//
//  BookReviewViewController.swift
//  BookMarker
//
//  Created by Reimos on 10/3/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa
import Kingfisher
import RealmSwift

/// 저장된 독서 일기를 보여주는 뷰 컨트롤러
final class BookReviewViewController: UIViewController {

    // MARK: - Properties
    private let bookId: ObjectId
    private let bookRepository = BookRepository()
    private let disposeBag = DisposeBag()
    private var bookData: BookRealmModel?

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = UIColor.systemGray6
    }

    private let contentView = UIView()

    // 첫 번째 카드: 도서 정보
    private let bookInfoCardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    // 두 번째 카드: 내 메모
    private let memoCardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    // 세 번째 카드: 인상 깊은 구절
    private let quoteCardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    private let coverShadowContainer = UIView().then {
        $0.backgroundColor = .clear
       // $0.layer.shadowColor = UIColor.black.cgColor
        //$0.layer.shadowOpacity = 0.15
        //$0.layer.shadowOffset = CGSize(width: 0, height: 4)
        $0.layer.shadowRadius = 8
    }

    private let bookCoverImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    private let bookTitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 0
        $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
        $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private let bookAuthorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let publisherLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .secondaryLabel
    }
    
    private let readingStatusBadge = UILabel().then {
        $0.text = "읽는 중"
        $0.font = .systemFont(ofSize: 11, weight: .semibold)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.backgroundColor = .systemOrange
        $0.layer.cornerRadius = 13
        $0.clipsToBounds = true
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // 읽기 상태 컨테이너 (아이콘 + 텍스트)
    private let readingStatusContainer = UIView().then {
        $0.backgroundColor = .systemOrange
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let readingStatusIcon = UIImageView().then {
        $0.image = UIImage(systemName: "book.fill")
        $0.tintColor = .white
        $0.contentMode = .scaleAspectFit
    }

    private let readingStatusLabel = UILabel().then {
        $0.text = "읽는 중"
        $0.font = .systemFont(ofSize: 12, weight: .semibold)
        $0.textColor = .white
    }

    // 별점
    private let starStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 2
        $0.distribution = .fillEqually
        $0.alignment = .center
    }

    private let ratingLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .secondaryLabel
    }

    // 태그 컬렉션뷰
    private lazy var tagCollectionView: UICollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.register(TagCell.self, forCellWithReuseIdentifier: TagCell.identifier)
        return cv
    }()

    private var tags: [String] = []

    // 카테고리/저장일 섹션
    private let infoSectionContainer = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 0
    }

    private let categoryTitleLabel = UILabel().then {
        $0.text = "카테고리"
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let categoryValueLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .label
        $0.textAlignment = .right
    }

    private let dateTitleLabel = UILabel().then {
        $0.text = "저장일"
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let dateValueLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .label
        $0.textAlignment = .right
    }

    private let dividerLine = UIView().then {
        $0.backgroundColor = .separator.withAlphaComponent(0.3)
    }

    private let dividerLine2 = UIView().then {
        $0.backgroundColor = .separator.withAlphaComponent(0.3)
    }

    private let startDateTitleLabel = UILabel().then {
        $0.text = "독서 시작일"
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let startDateValueLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .label
        $0.textAlignment = .right
    }

    private let endDateTitleLabel = UILabel().then {
        $0.text = "독서 완료일"
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let endDateValueLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .label
        $0.textAlignment = .right
    }

    // 내 메모 섹션
    private let memoTitleLabel = UILabel().then {
        $0.text = "내 메모"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .label
    }

    private let memoContentLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    // 인상 깊은 구절 섹션
    private let quoteTitleLabel = UILabel().then {
        $0.text = "인상 깊은 구절"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .label
    }

    private let quoteStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
        $0.distribution = .fill
    }

    private let noQuoteLabel = UILabel().then {
        $0.text = "저장된 구절이 없습니다."
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    // 버튼들
    private let editButton = UIButton().then {
        var config = UIButton.Configuration.filled()
        config.title = "수정하기"
        config.image = UIImage(systemName: "pencil")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = .systemTeal
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        $0.configuration = config
    }

    private let writeDiaryButton = UIButton().then {
        var config = UIButton.Configuration.plain()
        config.title = "독서 일기 쓰기"
        config.image = UIImage(systemName: "pencil.line")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseForegroundColor = .label
        config.background.strokeColor = .separator
        config.background.strokeWidth = 1
        config.cornerStyle = .medium
        $0.configuration = config
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.separator.cgColor
        $0.layer.cornerRadius = 10
    }

    // MARK: - Init
    init(bookId: ObjectId) {
        self.bookId = bookId
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
        setupCollectionView()
        setupBindings()
        loadBookData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 독서 일기 작성/수정 후 돌아왔을 때 데이터 새로고침
        loadBookData()
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = "도서 정보"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .label

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "pencil"),
            style: .plain,
            target: self,
            action: #selector(editNavButtonTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .label
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func editNavButtonTapped() {
        // TODO: 편집 기능 구현
        print("편집 버튼 클릭")
    }

    private func setupCollectionView() {
        tagCollectionView.delegate = self
        tagCollectionView.dataSource = self
    }

    private func setupBindings() {
        // 수정하기 버튼 - BookDiaryViewController로 이동
        editButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                guard let book = owner.bookData else { return }
                let item = BookMapper.toItem(from: book)
                let diaryVC = BookDiaryViewController(book: item)
                owner.navigationController?.pushViewController(diaryVC, animated: true)
            }
            .disposed(by: disposeBag)

        // 독서 일기 쓰기 버튼 - BookDiaryViewController로 이동
        writeDiaryButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                guard let book = owner.bookData else { return }
                let item = BookMapper.toItem(from: book)
                let diaryVC = BookDiaryViewController(book: item)
                owner.navigationController?.pushViewController(diaryVC, animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func loadBookData() {
        do {
            guard let book = try bookRepository.getBook(byId: bookId) else {
                view.makeToast("도서 정보를 찾을 수 없습니다.")
                return
            }

            self.bookData = book
            updateUI(with: book)

        } catch {
            view.makeToast("도서 정보를 불러오는데 실패했습니다.")
            print("[로드 실패] \(error.localizedDescription)")
        }
    }

    private func updateUI(with book: BookRealmModel) {
        // 도서 기본 정보
        bookTitleLabel.text = book.title
        bookAuthorLabel.text = book.cleanAuthorName
        publisherLabel.text = book.publisher

        // 표지 이미지
        if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
            bookCoverImageView.kf.setImage(with: url)
        }

        // 읽기 상태
        readingStatusLabel.text = book.isReadingComplete ? "읽기 완료" : "읽는 중"
        readingStatusContainer.backgroundColor = book.isReadingComplete ? .systemTeal : .systemOrange

        // 별점
        updateStars(rating: Int(book.userRating))
        ratingLabel.text = book.userRating > 0 ? "\(Int(book.userRating))/5" : "평점 없음"

        // 태그
        tags = Array(book.tags)
        tagCollectionView.reloadData()

        // 태그 컬렉션뷰 높이 자동 조절
        DispatchQueue.main.async { [weak self] in
            self?.updateTagCollectionViewHeight()
        }

        // 카테고리 (마지막 항목만 표시)
        if let category = book.category {
            let components = category.split(separator: ">").map { $0.trimmingCharacters(in: .whitespaces) }
            categoryValueLabel.text = components.last ?? "미분류"
        } else {
            categoryValueLabel.text = "미분류"
        }

        // 저장일
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. M. d."
        dateValueLabel.text = formatter.string(from: book.savedDate)

        // 독서 시작일
        if let startDate = book.startDate {
            startDateValueLabel.text = formatter.string(from: startDate)
        } else {
            startDateValueLabel.text = "-"
        }

        // 독서 완료일
        if let endDate = book.endDate {
            endDateValueLabel.text = formatter.string(from: endDate)
        } else {
            endDateValueLabel.text = "읽는 중"
            endDateValueLabel.textColor = .systemOrange
        }

        // 내 메모
        memoContentLabel.text = book.diaryContent ?? "작성된 메모가 없습니다."

        // 인상 깊은 구절
        let quotes = Array(book.quotes)
        if quotes.isEmpty {
            quoteStackView.isHidden = true
            noQuoteLabel.isHidden = false
        } else {
            quoteStackView.isHidden = false
            noQuoteLabel.isHidden = true
            updateQuotes(quotes)
        }

        // 버튼 표시 여부
        let hasDiary = book.hasDiary
        editButton.isHidden = !hasDiary
        writeDiaryButton.isHidden = hasDiary
    }

    private func updateStars(rating: Int) {
        // 기존 별 제거
        starStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 새로운 별 추가
        for i in 0..<5 {
            let starImageView = UIImageView()
            starImageView.contentMode = .scaleAspectFit
            starImageView.snp.makeConstraints { $0.size.equalTo(18) }

            if i < rating {
                starImageView.image = UIImage(systemName: "star.fill")
                starImageView.tintColor = .systemYellow
            } else {
                starImageView.image = UIImage(systemName: "star")
                starImageView.tintColor = .systemGray4
            }

            starStackView.addArrangedSubview(starImageView)
        }
    }

    private func updateTagCollectionViewHeight() {
        let contentHeight = tagCollectionView.collectionViewLayout.collectionViewContentSize.height
        tagCollectionView.snp.updateConstraints {
            $0.height.equalTo(max(contentHeight, 40))
        }
    }

    private func updateQuotes(_ quotes: [String]) {
        // 기존 구절 제거
        quoteStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 구절 추가
        for (index, quote) in quotes.enumerated() {
            let quoteContainer = UIView()
            quoteContainer.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.5)
            quoteContainer.layer.cornerRadius = 8

            let quoteLabel = UILabel()
            quoteLabel.text = "\" \(quote) \""
            quoteLabel.font = .systemFont(ofSize: 14, weight: .regular)
            quoteLabel.textColor = .label
            quoteLabel.numberOfLines = 0

            quoteContainer.addSubview(quoteLabel)
            quoteLabel.snp.makeConstraints {
                $0.edges.equalToSuperview().inset(16)
            }

            quoteStackView.addArrangedSubview(quoteContainer)
        }
    }
}

// MARK: - UI Configuration
extension BookReviewViewController: DesignProtocol {

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 3개의 카드뷰를 contentView에 추가
        contentView.addSubview(bookInfoCardView)
        contentView.addSubview(memoCardView)
        contentView.addSubview(quoteCardView)

        // 표지 그림자 컨테이너
        coverShadowContainer.addSubview(bookCoverImageView)

        // 읽기 상태 컨테이너 계층
        readingStatusContainer.addSubview(readingStatusIcon)
        readingStatusContainer.addSubview(readingStatusLabel)

        // 정보 섹션 컨테이너
        infoSectionContainer.addSubview(categoryTitleLabel)
        infoSectionContainer.addSubview(categoryValueLabel)
        infoSectionContainer.addSubview(dividerLine)
        infoSectionContainer.addSubview(dateTitleLabel)
        infoSectionContainer.addSubview(dateValueLabel)
        infoSectionContainer.addSubview(dividerLine2)
        infoSectionContainer.addSubview(startDateTitleLabel)
        infoSectionContainer.addSubview(startDateValueLabel)
        infoSectionContainer.addSubview(endDateTitleLabel)
        infoSectionContainer.addSubview(endDateValueLabel)

        // 첫 번째 카드: 도서 정보 + 태그 + 카테고리
        [coverShadowContainer, bookTitleLabel, bookAuthorLabel,
         publisherLabel, readingStatusContainer, starStackView, ratingLabel,
         tagCollectionView, infoSectionContainer].forEach {
            bookInfoCardView.addSubview($0)
        }

        // 두 번째 카드: 내 메모
        memoCardView.addSubview(memoTitleLabel)
        memoCardView.addSubview(memoContentLabel)

        // 세 번째 카드: 인상 깊은 구절
        quoteCardView.addSubview(quoteTitleLabel)
        quoteCardView.addSubview(quoteStackView)
        quoteCardView.addSubview(noQuoteLabel)

        // 버튼들은 카드 밖에 배치
        contentView.addSubview(editButton)
        contentView.addSubview(writeDiaryButton)
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // ===== 첫 번째 카드: 도서 정보 =====
        bookInfoCardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        // 표지 그림자 컨테이너 (높이 증가)
        coverShadowContainer.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.equalToSuperview().offset(24)
            $0.width.equalTo(90)
            $0.height.equalTo(135)
        }

        // 도서 표지 (그림자 컨테이너 안)
        bookCoverImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 도서 제목
        bookTitleLabel.snp.makeConstraints {
            $0.top.equalTo(coverShadowContainer)
            $0.leading.equalTo(coverShadowContainer.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().offset(-24)
        }

        // 저자
        bookAuthorLabel.snp.makeConstraints {
            $0.top.equalTo(bookTitleLabel.snp.bottom).offset(6)
            $0.leading.equalTo(bookTitleLabel)
            $0.trailing.equalToSuperview().offset(-24)
        }

        // 출판사
        publisherLabel.snp.makeConstraints {
            $0.top.equalTo(bookAuthorLabel.snp.bottom).offset(4)
            $0.leading.equalTo(bookTitleLabel)
            $0.trailing.equalToSuperview().offset(-24)
        }

        // 읽기 상태 컨테이너 (출판사 밑, 별점 위)
        readingStatusContainer.snp.makeConstraints {
            $0.top.equalTo(publisherLabel.snp.bottom).offset(8)
            $0.leading.equalTo(bookTitleLabel)
            $0.height.equalTo(24)
        }

        // 읽기 상태 아이콘
        readingStatusIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(14)
        }

        // 읽기 상태 레이블
        readingStatusLabel.snp.makeConstraints {
            $0.leading.equalTo(readingStatusIcon.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-10)
        }

        // 별점
        starStackView.snp.makeConstraints {
            $0.top.equalTo(readingStatusContainer.snp.bottom).offset(8)
            $0.leading.equalTo(bookTitleLabel)
            $0.height.equalTo(20)
        }

        ratingLabel.snp.makeConstraints {
            $0.centerY.equalTo(starStackView)
            $0.leading.equalTo(starStackView.snp.trailing).offset(8)
        }

        // 태그 컬렉션뷰
        tagCollectionView.snp.makeConstraints {
            $0.top.equalTo(coverShadowContainer.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(40)
        }

        // 정보 섹션 (높이 자동 조절)
        infoSectionContainer.snp.makeConstraints {
            $0.top.equalTo(tagCollectionView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        categoryTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(0)
        }

        categoryValueLabel.snp.makeConstraints {
            $0.centerY.equalTo(categoryTitleLabel)
            $0.trailing.equalToSuperview().offset(0)
        }

        dividerLine.snp.makeConstraints {
            $0.top.equalTo(categoryTitleLabel.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        dateTitleLabel.snp.makeConstraints {
            $0.top.equalTo(dividerLine.snp.bottom).offset(14)
            $0.leading.equalToSuperview().offset(0)
        }

        dateValueLabel.snp.makeConstraints {
            $0.centerY.equalTo(dateTitleLabel)
            $0.trailing.equalToSuperview().offset(0)
        }

        dividerLine2.snp.makeConstraints {
            $0.top.equalTo(dateTitleLabel.snp.bottom).offset(14)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        startDateTitleLabel.snp.makeConstraints {
            $0.top.equalTo(dividerLine2.snp.bottom).offset(14)
            $0.leading.equalToSuperview().offset(0)
        }

        startDateValueLabel.snp.makeConstraints {
            $0.centerY.equalTo(startDateTitleLabel)
            $0.trailing.equalToSuperview().offset(0)
        }

        endDateTitleLabel.snp.makeConstraints {
            $0.top.equalTo(startDateTitleLabel.snp.bottom).offset(14)
            $0.leading.equalToSuperview().offset(0)
            $0.bottom.equalToSuperview().offset(-16)
        }

        endDateValueLabel.snp.makeConstraints {
            $0.centerY.equalTo(endDateTitleLabel)
            $0.trailing.equalToSuperview().offset(0)
        }

        // 첫 번째 카드의 bottom 제약 (infoSectionContainer가 마지막 요소)
        bookInfoCardView.snp.makeConstraints {
            $0.bottom.equalTo(infoSectionContainer.snp.bottom).offset(24)
        }

        // ===== 두 번째 카드: 내 메모 =====
        memoCardView.snp.makeConstraints {
            $0.top.equalTo(bookInfoCardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        memoTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        memoContentLabel.snp.makeConstraints {
            $0.top.equalTo(memoTitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().offset(-24)
        }

        // ===== 세 번째 카드: 인상 깊은 구절 =====
        quoteCardView.snp.makeConstraints {
            $0.top.equalTo(memoCardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        quoteTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        quoteStackView.snp.makeConstraints {
            $0.top.equalTo(quoteTitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().offset(-24)
        }

        noQuoteLabel.snp.makeConstraints {
            $0.top.equalTo(quoteTitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().offset(-24)
        }

        // ===== 버튼들 (카드 밖) =====
        editButton.snp.makeConstraints {
            $0.top.equalTo(quoteCardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(56)
        }

        writeDiaryButton.snp.makeConstraints {
            $0.top.equalTo(editButton.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(56)
            $0.bottom.equalToSuperview().offset(-40)
        }
    }

    func configureView() {
        view.backgroundColor = UIColor.systemGray6
    }
}

// MARK: - UICollectionViewDelegate, DataSource
extension BookReviewViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCell.identifier, for: indexPath) as? TagCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: tags[indexPath.item])
        return cell
    }
}

// MARK: - TagCell
final class TagCell: UICollectionViewCell {

    static let identifier = "TagCell"

    private let tagLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .systemTeal
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemTeal.withAlphaComponent(0.15)
        layer.cornerRadius = 16

        contentView.addSubview(tagLabel)
        tagLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }

    func configure(with tag: String) {
        tagLabel.text = "#\(tag)"
    }
}

// MARK: - LeftAlignedCollectionViewFlowLayout
final class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }

        var leftMargin: CGFloat = sectionInset.left
        var maxY: CGFloat = -1.0

        let modifiedAttributes = attributes.compactMap { attribute -> UICollectionViewLayoutAttributes? in
            guard attribute.representedElementCategory == .cell else { return attribute }

            let newAttribute = attribute.copy() as! UICollectionViewLayoutAttributes

            // 새로운 줄인지 확인
            if newAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }

            // 좌측 정렬 적용
            newAttribute.frame.origin.x = leftMargin

            leftMargin += newAttribute.frame.width + minimumInteritemSpacing
            maxY = max(newAttribute.frame.maxY, maxY)

            return newAttribute
        }

        return modifiedAttributes
    }
}
