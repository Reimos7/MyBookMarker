//
//  FolderDetailViewController.swift
//  BookMarker
//
//  Created by Reimos on 10/3/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class FolderDetailViewController: UIViewController {

    // MARK: - Properties
    private let folderData: BookCardView.FolderBookData
    private let viewModel: FolderDetailViewModel
    private let disposeBag = DisposeBag()
    private let refreshTrigger = PublishSubject<Void>()

    // MARK: - UI Components
    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        // 2열 그리드 레이아웃
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 16
        let itemWidth = (screenWidth - (spacing * 3)) / 2  // 좌우 여백 + 중간 간격

        layout.itemSize = CGSize(width: itemWidth, height: 240)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        $0.collectionViewLayout = layout
        $0.register(BookGridCell.self, forCellWithReuseIdentifier: BookGridCell.reuseIdentifier)
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .systemBackground
    }

    private let emptyLabel = UILabel().then {
        $0.text = "저장된 도서가 없습니다"
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.isHidden = true
    }

    // MARK: - Init
    init(folderData: BookCardView.FolderBookData) {
        self.folderData = folderData
        self.viewModel = FolderDetailViewModel(folderData: folderData)
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
        // 데이터 새로고침
        refreshTrigger.onNext(())
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = folderData.title

        // 뒤로가기 버튼
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = .label
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Helper Methods
    /// Realm에서 읽기 상태를 조회하여 저자 밑에 표시
    private func configureReadingStatusBadge(for cell: BookGridCell, item: Item) {
        guard let isbn13 = item.isbn13 else {
            cell.setReadingStatus(text: nil, color: nil)
            return
        }

        let bookRepository = BookRepository()

        do {
            if let savedBook = try bookRepository.getBook(byISBN: isbn13) {
                // 독서 일기가 작성되어 있는 경우에만 상태 표시
                if savedBook.hasDiary {
                    if savedBook.isReadingComplete {
                        cell.setReadingStatus(text: "읽기 완료", color: .systemTeal)
                    } else {
                        cell.setReadingStatus(text: "읽는 중", color: .systemOrange)
                    }
                } else {
                    // 일기가 없으면 상태 숨김
                    cell.setReadingStatus(text: nil, color: nil)
                }
            } else {
                cell.setReadingStatus(text: nil, color: nil)
            }
        } catch {
            print("[읽기 상태 설정 오류] \(error.localizedDescription)")
            cell.setReadingStatus(text: nil, color: nil)
        }
    }

    // MARK: - Navigation
    /// 선택된 도서의 독서 일기 작성 여부에 따라 적절한 화면으로 이동
    private func navigateToAppropriateScreen(for item: Item) {
        // 1. ISBN13으로 Realm에서 도서 조회
        guard let isbn13 = item.isbn13 else {
            view.makeToast("도서 정보를 찾을 수 없습니다.")
            return
        }

        let bookRepository = BookRepository()

        do {
            // 2. Realm에서 저장된 도서 찾기
            guard let savedBook = try bookRepository.getBook(byISBN: isbn13) else {
                view.makeToast("저장된 도서를 찾을 수 없습니다.")
                return
            }

            // 3. 독서 일기 작성 여부 확인
            if savedBook.hasDiary {
                // 독서 일기가 있으면 -> BookReviewViewController (읽기 전용)
                let reviewVC = BookReviewViewController(bookId: savedBook.id)
                navigationController?.pushViewController(reviewVC, animated: true)
            } else {
                // 독서 일기가 없으면 -> BookDiaryViewController (작성 화면)
                let diaryVC = BookDiaryViewController(book: item)
                navigationController?.pushViewController(diaryVC, animated: true)
            }

        } catch {
            view.makeToast("도서 정보를 불러오는데 실패했습니다.")
            print("[네비게이션 오류] \(error.localizedDescription)")
        }
    }
}

// MARK: - UI Configuration
extension FolderDetailViewController: DesignProtocol {

    func configureHierarchy() {
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
    }

    func configureLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    func configureView() {
        view.backgroundColor = .systemBackground
    }

    private func setupBindings() {
        let input = FolderDetailViewModel.Input(
            refresh: refreshTrigger.asObservable()
        )
        let output = viewModel.transform(input)

        // 책 목록 바인딩
        output.books
            .drive(collectionView.rx.items(
                cellIdentifier: BookGridCell.reuseIdentifier,
                cellType: BookGridCell.self
            )) { [weak self] index, item, cell in
                cell.configure(with: item)

                // Realm에서 읽기 상태 조회하여 배지 표시
                self?.configureReadingStatusBadge(for: cell, item: item)
            }
            .disposed(by: disposeBag)

        // 빈 상태 표시
        output.books
            .map { $0.isEmpty }
            .drive(with: self) { owner, isEmpty in
                owner.emptyLabel.isHidden = !isEmpty
                owner.collectionView.isHidden = isEmpty
            }
            .disposed(by: disposeBag)
        

        // 셀 선택 -> 독서 일기 작성 여부에 따라 화면 분기
        collectionView.rx.itemSelected
            .asDriver()
            .withLatestFrom(output.books) { indexPath, books in
                return books[indexPath.item]
            }
            .drive(with: self) { owner, selectedBook in
                owner.navigateToAppropriateScreen(for: selectedBook)
            }
            .disposed(by: disposeBag)
    }
}
