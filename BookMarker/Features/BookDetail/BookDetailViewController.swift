//
//  BookDetailViewController.swift
//  BookMarker
//
//  Created by Reimos on 9/28/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa
import Kingfisher

final class BookDetailViewController: UIViewController {

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    // MARK: - 도서 정보 섹션
    private let bookImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
    }

    private let titleLabel = UILabel().then {
        $0.text = "스티브 잡스"
        $0.font = .systemFont(ofSize: 14, weight: .bold)
        $0.textColor = .black
        $0.numberOfLines = 4
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.7
    }

    private let authorLabel = UILabel().then {
        $0.text = "월터 아이작슨"
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .darkGray
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.8
    }

    private let publisherLabel = UILabel().then {
        $0.text = "민음사"
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .gray
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.8
    }

    private let pubDateLabel = UILabel().then {
        $0.text = "2023년 10월"
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .gray
        $0.numberOfLines = 1
        $0.isHidden = true
    }

    private let starRatingView = StarRatingView()

    private let categoryLabel = PaddingLabel().then {
        $0.text = "인물/평전"
        $0.font = .systemFont(ofSize: 11, weight: .medium)
        $0.textColor = .systemTeal
        $0.backgroundColor = .systemTeal.withAlphaComponent(0.1)
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.textAlignment = .center
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemTeal.cgColor
        $0.padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }

    // MARK: - 줄거리 섹션
    private let descriptionTitleLabel = UILabel().then {
        $0.text = "줄거리"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .black
    }

    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .darkGray
        $0.numberOfLines = 0
        $0.lineBreakMode = .byWordWrapping
        $0.text = "줄거리 정보가 없습니다."
    }

    // MARK: - 저자의 다른 작품 섹션
    private let otherBooksTitleLabel = UILabel().then {
        $0.text = "월터 아이작슨의 다른 작품"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .black
    }

    private let otherBooksCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 120)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        $0.collectionViewLayout = layout
        $0.register(OtherBookCell.self, forCellWithReuseIdentifier: OtherBookCell.reuseIdentifier)
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .clear
        $0.isScrollEnabled = false // 높이를 고정하기 위해
    }

    // MARK: - 편집자 추천 섹션
    private let recommendationTitleLabel = UILabel().then {
        $0.text = "이런 책은 어때요?"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .black
    }

    private let recommendationCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 140)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        $0.collectionViewLayout = layout
        $0.register(BookImageCell.self, forCellWithReuseIdentifier: BookImageCell.reuseIdentifier)
        $0.showsHorizontalScrollIndicator = false
        $0.backgroundColor = .clear
    }

    private let disposeBag = DisposeBag()
    private var bookItem: Item?
    private let viewModel = BookDetailViewModel()
    private var heartButton: UIBarButtonItem?

    init(book: Item) {
        self.bookItem = book
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureHierarchy()
        configureLayout()
        configureView()
        setupBindings()
        configureBookInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupNavigationBar() {
        title = "도서 상세"

        // 뒤로가기 버튼
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .black

        // 하트 버튼 (좋아요/즐겨찾기)
        heartButton = UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            style: .plain,
            target: nil,
            action: nil
        )
        heartButton?.tintColor = .black
        navigationItem.rightBarButtonItem = heartButton
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }


    private func configureBookInfo() {
        guard let book = bookItem else { return }

        titleLabel.text = book.title

        // 저자명 정제: 맨 앞 저자만 표시
        let displayAuthor = extractMainAuthor(from: book.author)
        authorLabel.text = displayAuthor

        publisherLabel.text = book.publisher

        // 출판일 포맷팅
        if let pubDate = book.pubDate {
            pubDateLabel.text = formatPubDate(pubDate)
        } else {
            pubDateLabel.text = "출판일 미상"
        }

        // 책 이미지 설정
        if let coverURL = book.cover, let url = URL(string: coverURL) {
            bookImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "book.closed"))
        }

        // 별점 설정 (customerReviewRank를 10점 만점으로 사용)
        if let reviewRank = book.customerReviewRank {
            starRatingView.rating = Double(reviewRank)
        } else {
            starRatingView.rating = 0.0
        }

        // 카테고리 설정 (마지막 카테고리만 표시)
        if let categoryName = book.categoryName {
            let lastCategory = categoryName
                .components(separatedBy: ">")
                .last?
                .trimmingCharacters(in: .whitespaces)
            categoryLabel.text = lastCategory ?? categoryName
        }

        // 줄거리 설정
        if let description = book.description, !description.isEmpty {
            descriptionLabel.text = description
        } else {
            descriptionLabel.text = "줄거리 정보가 제공되지 않습니다."
        }

        // 저자의 다른 작품 타이틀 업데이트
        otherBooksTitleLabel.text = "\(displayAuthor)님의 다른 작품"
    }

    private func extractMainAuthor(from rawAuthor: String?) -> String {
        guard let rawAuthor = rawAuthor, !rawAuthor.isEmpty else { return "저자미상" }

        // 첫 번째 저자만 추출하고 역할 정보 제거
        let mainAuthor = rawAuthor
            .components(separatedBy: ",").first?         // 첫 번째 저자만
            .components(separatedBy: "(").first?         // "(지은이" 등 제거
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return mainAuthor ?? rawAuthor
    }

    private func formatPubDate(_ pubDate: String) -> String {
        // 알라딘 API의 pubDate는 "2023-10-15" 형식
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let date = dateFormatter.date(from: pubDate) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy년 M월 dd일"
            return outputFormatter.string(from: date)
        }

        // 포맷팅에 실패하면 원본 반환
        return pubDate
    }
}

// MARK: - UI Configuration
extension BookDetailViewController: DesignProtocol {

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [bookImageView, titleLabel, authorLabel, publisherLabel, pubDateLabel, starRatingView, categoryLabel,
         descriptionTitleLabel, descriptionLabel,
         otherBooksTitleLabel, otherBooksCollectionView,
         recommendationTitleLabel, recommendationCollectionView].forEach {
            contentView.addSubview($0)
        }
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // 도서 이미지
        bookImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(16)
            $0.width.equalTo(120)
            $0.height.equalTo(160)
        }

        // 도서 제목
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(bookImageView.snp.top)
            $0.leading.equalTo(bookImageView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        // 저자
        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.trailing.equalTo(titleLabel.snp.trailing)
        }

        // 출판사
        publisherLabel.snp.makeConstraints {
            $0.top.equalTo(authorLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel.snp.leading)
        }

        // 출판일 (출판사 옆에 배치)
        pubDateLabel.snp.makeConstraints {
            $0.top.equalTo(publisherLabel.snp.top)
            $0.leading.equalTo(publisherLabel.snp.trailing).offset(8)
            $0.trailing.lessThanOrEqualTo(titleLabel.snp.trailing)
        }

        // 별점 (출판사/출판일 아래, 카테고리 위에 배치)
        starRatingView.snp.makeConstraints {
            $0.top.equalTo(publisherLabel.snp.bottom).offset(8)
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.height.equalTo(16)
            $0.width.equalTo(120)
        }

        // 카테고리 라벨 (도서 이미지 하단에 고정)
        categoryLabel.snp.makeConstraints {
            $0.bottom.equalTo(bookImageView.snp.bottom)
            $0.leading.equalTo(titleLabel.snp.leading)
        }

        // 줄거리 타이틀
        descriptionTitleLabel.snp.makeConstraints {
            $0.top.equalTo(bookImageView.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        // 줄거리 내용
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(descriptionTitleLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        // 저자의 다른 작품 타이틀 (초기 제약 - 동적으로 변경됨)
        otherBooksTitleLabel.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        // 저자의 다른 작품 컬렉션뷰 (초기 제약 - 동적으로 변경됨)
        otherBooksCollectionView.snp.makeConstraints {
            $0.top.equalTo(otherBooksTitleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(300) // 임시 높이
        }

        // 편집자 추천 타이틀 (초기 제약 - 동적으로 변경됨)
        recommendationTitleLabel.snp.makeConstraints {
            $0.top.equalTo(otherBooksCollectionView.snp.bottom).offset(32)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        // 편집자 추천 컬렉션뷰
        recommendationCollectionView.snp.makeConstraints {
            $0.top.equalTo(recommendationTitleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(160)
            $0.bottom.equalToSuperview().inset(12)
        }
    }

    func configureView() {
        view.backgroundColor = .systemGray6
    }

    private func setupBindings() {
        guard let book = bookItem else { return }

        // 삭제 확인 Subject
        let deleteConfirmedSubject = PublishSubject<Void>()

        let input = BookDetailViewModel.Input(
            bookItem: Observable.just(book),
            heartButtonTapped: heartButton?.rx.tap.asObservable() ?? Observable.never(),
            deleteConfirmed: deleteConfirmedSubject.asObservable()
        )

        let output = viewModel.transform(input)

        // 저자의 다른 작품 바인딩
        output.otherBooks
            .drive(otherBooksCollectionView.rx.items(
                cellIdentifier: OtherBookCell.reuseIdentifier,
                cellType: OtherBookCell.self
            )) { (index: Int, item: Item, cell: OtherBookCell) in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        // 편집자 추천 도서 바인딩
        output.recommendedBooks
            .drive(recommendationCollectionView.rx.items(
                cellIdentifier: BookImageCell.reuseIdentifier,
                cellType: BookImageCell.self
            )) { (index: Int, item: Item, cell: BookImageCell) in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        // 저자의 다른 작품 개수에 따른 레이아웃 동적 조정
        output.otherBooks
            .drive(with: self) { owner, books in
                if books.isEmpty {
                    // 다른 작품이 없으면 섹션 숨기고, "이런 책은 어때요?"를 바로 위에 배치
                    owner.otherBooksTitleLabel.isHidden = true
                    owner.otherBooksCollectionView.isHidden = true

                    owner.recommendationTitleLabel.snp.remakeConstraints {
                        $0.top.equalTo(owner.descriptionLabel.snp.bottom).offset(24)
                        $0.leading.equalToSuperview().offset(16)
                        $0.trailing.equalToSuperview().offset(-16)
                    }
                } else {
                    // 다른 작품이 있으면 정상 표시
                    owner.otherBooksTitleLabel.isHidden = false
                    owner.otherBooksCollectionView.isHidden = false

                    // 컬렉션뷰 높이 조정
                    let height = max(152, books.count * 132) // 각 셀 높이(120) + 간격(12) + 상하패딩(32)
                    owner.otherBooksCollectionView.snp.updateConstraints {
                        $0.height.equalTo(height)
                    }

                    // "이런 책은 어때요?"를 다른 작품 아래에 배치
                    owner.recommendationTitleLabel.snp.remakeConstraints {
                        $0.top.equalTo(owner.otherBooksCollectionView.snp.bottom).offset(32)
                        $0.leading.equalToSuperview().offset(16)
                        $0.trailing.equalToSuperview().offset(-16)
                    }
                }
            }
            .disposed(by: disposeBag)

        // 하트 버튼 상태 업데이트
        output.isFavorite
            .drive(with: self) { owner, isFavorite in
                let imageName = isFavorite ? "heart.fill" : "heart"
              //  let toastMesage = isFavorite ? "
            
                owner.heartButton?.image = UIImage(systemName: imageName)
                owner.heartButton?.tintColor = isFavorite ? .systemRed : .black
            }
            .disposed(by: disposeBag)

        // 토스트 메시지 표시
        output.showToast
            .filter { !$0.isEmpty }
            .drive(with: self) { owner, message in
                // TODO: Toast 라이브러리 연동
                print("Toast: \(message)")
                owner.view.makeToast(message)
            }
            .disposed(by: disposeBag)

        // 폴더 선택 Alert 표시
        output.showFolderSelection
            .drive(with: self) { owner, item in
                owner.showFolderSelectionAlert(for: item)
            }
            .disposed(by: disposeBag)

        // 삭제 확인 Alert 표시
        output.showDeleteConfirmation
            .drive(with: self) { owner, item in
                owner.showDeleteConfirmationAlert(for: item, deleteConfirmed: deleteConfirmedSubject)
            }
            .disposed(by: disposeBag)

        // 저자의 다른 작품 셀 탭 이벤트
        otherBooksCollectionView.rx.itemSelected
            .asDriver()
            .withLatestFrom(output.otherBooks) { indexPath, books in
                return books[indexPath.item]
            }
            .drive(with: self) { owner, selectedBook in
                print("다른 작품 선택됨: \(selectedBook.title ?? "")")
                let detailVC = BookDetailViewController(book: selectedBook)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

        // 편집자 추천 도서 셀 탭 이벤트
        recommendationCollectionView.rx.itemSelected
            .asDriver()
            .withLatestFrom(output.recommendedBooks) { indexPath, books in
                return books[indexPath.item]
            }
            .drive(with: self) { owner, selectedBook in
                print("편집자 추천 도서 선택됨: \(selectedBook.title ?? "")")
                let detailVC = BookDetailViewController(book: selectedBook)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

    }

    // MARK: - Folder Selection Alert

    private func showFolderSelectionAlert(for item: Item) {
        guard let window = view.window else { return }

        // FolderSelectionView 생성
        let folderSelectionView = FolderSelectionView(bookTitle: item.title ?? "도서")
        let folderSelectionVM = FolderSelectionViewModel()

        // ViewModel Input
        let input = FolderSelectionViewModel.Input(
            viewDidLoad: Observable.just(()),
            folderSelected: folderSelectionView.folderSelected.asObservable(),
            createFolderTapped: folderSelectionView.createFolderTapped.asObservable()
        )

        // ViewModel Output
        let output = folderSelectionVM.transform(input)

        // 폴더 목록 바인딩
        folderSelectionView.bind(folders: output.folders.asObservable())

        // 폴더 선택 이벤트
        output.selectedFolder
            .drive(with: self) { owner, selectedFolder in
                // Alert 닫기
                folderSelectionView.hide()

                // 선택한 폴더에 도서 추가
                owner.viewModel.addBookToSelectedFolder(item: item, folder: selectedFolder)
                    .subscribe(onNext: { (success, message) in
                        // 성공 시 하트 버튼 상태 업데이트
                        if success {
                            owner.heartButton?.image = UIImage(systemName: "heart.fill")
                            owner.heartButton?.tintColor = .systemRed
                        }
                        // Toast 메시지 표시
                        owner.view.makeToast(message)
                    })
                    .disposed(by: owner.disposeBag)
            }
            .disposed(by: disposeBag)

        // 새 폴더 만들기
        output.showCreateFolder
            .drive(with: self) { owner, _ in
                folderSelectionView.hide()
                print("새 폴더 만들기 화면으로 이동") // TODO: 새 폴더 생성 화면 구현
            }
            .disposed(by: disposeBag)

        // 닫기 이벤트
        folderSelectionView.closeTapped
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, _ in
                folderSelectionView.hide()
            }
            .disposed(by: disposeBag)


        // Alert 표시
        folderSelectionView.show(in: window)
    }

    private func showDeleteConfirmationAlert(for item: Item, deleteConfirmed: PublishSubject<Void>) {
        let alert = UIAlertController(
            title: "도서 삭제",
            message: "저장된 도서를 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        // 취소 버튼
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)

        // 확인 버튼
        let confirmAction = UIAlertAction(title: "확인", style: .destructive) { _ in
            deleteConfirmed.onNext(())
        }

        alert.addAction(cancelAction)
        alert.addAction(confirmAction)

        present(alert, animated: true, completion: nil)
    }
}
