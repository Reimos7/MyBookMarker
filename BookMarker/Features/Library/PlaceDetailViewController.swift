//
//  PlaceDetailViewController.swift
//  BookMarker
//
//  Created by Claude on 10/20/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa
import RealmSwift
import Kingfisher

final class PlaceDetailViewController: UIViewController {

    // MARK: - Properties
    private let place: PlaceRealmModel
    private let viewModel: PlaceDetailViewModel
    private let disposeBag = DisposeBag()
    private let refreshTrigger = PublishSubject<Void>()
    private let addBookTrigger = PublishSubject<Void>()

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    // 장소 이미지
    private let placeImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
    }

    // 장소 정보 컨테이너
    private let infoContainerView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 2
    }

    private let addressLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 2
    }

    private let ratingStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.alignment = .center
    }

    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    // 책 섹션
    private let booksSectionHeaderView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    private let booksSectionTitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .label
    }

    // 책 컬렉션뷰
    private let booksCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        // 2열 그리드
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 16
        let itemWidth = (screenWidth - (spacing * 3)) / 2

        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.5)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(BookCoverCell.self, forCellWithReuseIdentifier: BookCoverCell.reuseIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .systemBackground
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    private let emptyBookLabel = UILabel().then {
        $0.text = "이 장소에서 읽은 책이 없습니다"
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.isHidden = true
    }

    private let addBookButton = UIButton().then {
        var config = UIButton.Configuration.filled()
        config.title = "책 추가하기"
        config.image = UIImage(systemName: "plus.circle.fill")
        config.imagePadding = 8
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        $0.configuration = config
    }

    // MARK: - Init
    init(place: PlaceRealmModel) {
        self.place = place
        self.viewModel = PlaceDetailViewModel(place: place)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureHierarchy()
        configureLayout()
        configureView()
        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refreshTrigger.onNext(())
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = "장소 상세"
        navigationController?.navigationBar.tintColor = .black
        navigationItem.backButtonTitle = ""
    }

    private func configurePlaceInfo() {
        // 장소명
        nameLabel.text = place.name

        // 주소
        if let address = place.address {
            addressLabel.text = "📍 \(address)"
            addressLabel.isHidden = false
        } else {
            addressLabel.isHidden = true
        }

        // 평점
        configureRatingView()

        // 설명
        if let description = place.placeDescription, !description.isEmpty {
            descriptionLabel.text = "\"\(description)\""
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }

        // 장소 이미지
        if let imageURL = place.imageURL, let url = URL(string: imageURL) {
            placeImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "photo"),
                options: [.transition(.fade(0.3))]
            )
        } else {
            placeImageView.image = UIImage(systemName: "photo")
            placeImageView.tintColor = .systemGray4
        }
    }

    private func configureRatingView() {
        // 기존 별 제거
        ratingStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let rating = place.userRating
        let fullStars = Int(rating)
        let hasHalfStar = rating - Double(fullStars) >= 0.5

        // 꽉 찬 별
        for _ in 0..<fullStars {
            let starImageView = UIImageView(image: UIImage(systemName: "star.fill"))
            starImageView.tintColor = .systemYellow
            starImageView.snp.makeConstraints { $0.size.equalTo(16) }
            ratingStackView.addArrangedSubview(starImageView)
        }

        // 반 별
        if hasHalfStar {
            let starImageView = UIImageView(image: UIImage(systemName: "star.leadinghalf.filled"))
            starImageView.tintColor = .systemYellow
            starImageView.snp.makeConstraints { $0.size.equalTo(16) }
            ratingStackView.addArrangedSubview(starImageView)
        }

        // 빈 별
        let emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0)
        for _ in 0..<emptyStars {
            let starImageView = UIImageView(image: UIImage(systemName: "star"))
            starImageView.tintColor = .systemGray4
            starImageView.snp.makeConstraints { $0.size.equalTo(16) }
            ratingStackView.addArrangedSubview(starImageView)
        }

        // 평점 숫자 레이블
        let ratingLabel = UILabel().then {
            $0.text = String(format: "(%.1f)", rating)
            $0.font = .systemFont(ofSize: 14, weight: .medium)
            $0.textColor = .secondaryLabel
        }
        ratingStackView.addArrangedSubview(ratingLabel)

        ratingStackView.isHidden = rating == 0
    }
}

// MARK: - DesignProtocol
extension PlaceDetailViewController: DesignProtocol {
    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [placeImageView, infoContainerView, booksSectionHeaderView, booksCollectionView, emptyBookLabel, addBookButton].forEach {
            contentView.addSubview($0)
        }

        [nameLabel, addressLabel, ratingStackView, descriptionLabel].forEach {
            infoContainerView.addSubview($0)
        }

        booksSectionHeaderView.addSubview(booksSectionTitleLabel)
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        placeImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(280)
        }

        infoContainerView.snp.makeConstraints {
            $0.top.equalTo(placeImageView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        ratingStackView.snp.makeConstraints {
            $0.top.equalTo(addressLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(ratingStackView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-20)
        }

        booksSectionHeaderView.snp.makeConstraints {
            $0.top.equalTo(infoContainerView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(50)
        }

        booksSectionTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        booksCollectionView.snp.makeConstraints {
            $0.top.equalTo(booksSectionHeaderView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(100) // 초기값, 동적으로 변경됨
        }

        emptyBookLabel.snp.makeConstraints {
            $0.top.equalTo(booksSectionHeaderView.snp.bottom).offset(40)
            $0.centerX.equalToSuperview()
        }

        addBookButton.snp.makeConstraints {
            $0.top.equalTo(booksCollectionView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-20)
        }
    }

    func configureView() {
        view.backgroundColor = .systemBackground
        configurePlaceInfo()
    }

    private func setupBindings() {
        let input = PlaceDetailViewModel.Input(
            refreshTrigger: refreshTrigger.asObservable(),
            addBookTrigger: addBookButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        // 책 목록 바인딩
        output.books
            .do(onNext: { [weak self] books in
                // 컬렉션뷰 높이 동적 조정
                guard let self = self else { return }
                let itemsPerRow: CGFloat = 2
                let rows = ceil(CGFloat(books.count) / itemsPerRow)
                let screenWidth = UIScreen.main.bounds.width
                let spacing: CGFloat = 16
                let itemWidth = (screenWidth - (spacing * 3)) / 2
                let itemHeight = itemWidth * 1.5
                let totalHeight = (rows * itemHeight) + ((rows - 1) * spacing)

                self.booksCollectionView.snp.updateConstraints {
                    $0.height.equalTo(max(totalHeight, 100))
                }
            })
            .drive(booksCollectionView.rx.items(
                cellIdentifier: BookCoverCell.reuseIdentifier,
                cellType: BookCoverCell.self
            )) { (index, book, cell) in
                cell.configure(with: book)
            }
            .disposed(by: disposeBag)

        // 책 개수 업데이트
        output.bookCount
            .drive(with: self) { owner, count in
                owner.booksSectionTitleLabel.text = "📚 여기서 읽은 책 (\(count))"
                owner.emptyBookLabel.isHidden = count > 0
                owner.booksCollectionView.isHidden = count == 0
            }
            .disposed(by: disposeBag)

        // 책 선택 이벤트
        booksCollectionView.rx.modelSelected(Item.self)
            .bind(with: self) { owner, book in
                let detailVC = BookDetailViewController(book: book)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

        // 책 추가 버튼
        output.showBookSelector
            .drive(with: self) { owner, _ in
                owner.showBookSelectorAlert()
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Helper Methods
    private func showBookSelectorAlert() {
        print("DEBUG: showBookSelectorAlert 호출됨")
        let placeId = place.id.stringValue
        print("DEBUG: placeId = \(placeId)")

        let bookSelectorVC = PlaceBookSelectorViewController(placeId: placeId) { [weak self] in
            print("DEBUG: 책 선택 완료 콜백")
            // 책이 추가되면 목록 새로고침
            self?.refreshTrigger.onNext(())
        }

        print("DEBUG: PlaceBookSelectorViewController 생성 완료")
        let navController = UINavigationController(rootViewController: bookSelectorVC)
        print("DEBUG: present 직전")
        present(navController, animated: true) {
            print("DEBUG: present 완료")
        }
    }
}
