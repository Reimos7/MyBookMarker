//
//  SearchViewController.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then
import Toast

final class SearchViewController: UIViewController {

    private let searchBar = SearchBar()
    private let resultCountLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .black
        $0.text = "검색 결과"
    }

    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 150)
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        $0.collectionViewLayout = layout
        $0.register(SearchCollectionViewCell.self, forCellWithReuseIdentifier: SearchCollectionViewCell.reuseIdentifier)
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .systemGray6
        $0.keyboardDismissMode = .onDrag  // 스크롤 시 키보드 자동 숨김
    }

    private let disposeBag = DisposeBag()
    private let viewModel = SearchViewModel()
    private let bookRepository = BookRepository()

    // 좋아요 상태 관리 Dictionary (ISBN13 -> Bool)
    private var favoriteStates: [String: Bool] = [:]

    // 현재 검색 결과 아이템들
    private var currentItems: [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureHierarchy()
        configureLayout()
        configureView()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 상세 페이지에서 돌아왔을 때 좋아요 상태 다시 로드
        if !currentItems.isEmpty {
            loadFavoriteStates(for: currentItems)
            collectionView.reloadData()
        }
    }

    private func setupNavigationBar() {
        title = "검색"
        navigationController?.navigationBar.tintColor = .black
        navigationItem.backButtonTitle = ""

        // 뒤로가기 버튼 표시
        navigationItem.hidesBackButton = false
    }
}


// MARK: - DesiginProtocolBind
extension SearchViewController: DesiginProtocolBind {
    
    func bind() {
        // UI 이벤트는 에러/종료가 없으므로 Relay 사용 (onError로 스트림이 끊길 일이 없음)
        let searchTrigger = PublishRelay<Void>()
        let favoriteButtonTapped = PublishRelay<Item>()
        let deleteConfirmed = PublishRelay<Item>()

        let input = SearchViewModel.Input(
            searchText: searchBar.textField.rx.text.orEmpty.asObservable(),
            searchTrigger: searchTrigger.asObservable(),
            favoriteButtonTapped: favoriteButtonTapped.asObservable(),
            deleteConfirmed: deleteConfirmed.asObservable()
        )

        let output = viewModel.transform(input)

        // 검색 결과를 컬렉션뷰에 바인딩
        output.books
            .drive(with: self) { owner, items in
                // 현재 아이템 저장
                owner.currentItems = items
                // 검색 결과가 로드되면 좋아요 상태 초기화
                owner.loadFavoriteStates(for: items)
            }
            .disposed(by: disposeBag)

        output.books
            .drive(collectionView.rx.items(
                cellIdentifier: SearchCollectionViewCell.reuseIdentifier,
                cellType: SearchCollectionViewCell.self
            )) { [weak self] _, item, cell in
                guard let self else { return }
                // 좋아요 상태 확인
                let isFavorite = self.favoriteStates[item.isbn13 ?? ""] ?? false
                cell.configure(with: item, isFavorite: isFavorite)

                // 좋아요 버튼 탭 이벤트 (몇 번째 칸인지는 VM이 알 필요 없으므로 도서만 전달)
                cell.favoriteButtonTapped = {
                    favoriteButtonTapped.accept(item)
                }
            }
            .disposed(by: disposeBag)

        // 검색 결과 개수 표시 (TODO: 나중에 구현)
//        output.resultCount
//            .drive(resultCountLabel.rx.text)
//            .disposed(by: disposeBag)

        // 로딩 상태 처리
        output.isLoading
            .drive(with: self) { owner, isLoading in
                // TODO: - 로딩 인디케이터 표시/숨김
            }
            .disposed(by: disposeBag)

        // 에러 처리 (Signal은 drive 대신 emit으로 구독)
        output.error
            .emit(with: self) { owner, error in
                owner.view.makeToast(error)
            }
            .disposed(by: disposeBag)

        // Toast 메시지 표시
        output.showToast
            .emit(with: self) { owner, message in
                owner.view.makeToast(message)
            }
            .disposed(by: disposeBag)

        // 폴더 선택 Alert 표시
        output.showFolderSelection
            .emit(with: self) { owner, item in
                owner.showFolderSelectionAlert(for: item)
            }
            .disposed(by: disposeBag)

        // 삭제 확인 Alert 표시
        output.showDeleteConfirmation
            .emit(with: self) { owner, item in
                owner.showDeleteConfirmationAlert(for: item, deleteConfirmed: deleteConfirmed)
            }
            .disposed(by: disposeBag)

        // 좋아요 상태 업데이트 (몇 번째 칸인지는 VC가 isbn13으로 찾음)
        output.favoriteChanged
            .emit(with: self) { owner, change in
                owner.updateFavoriteState(isbn13: change.isbn13, isFavorite: change.isFavorite)
            }
            .disposed(by: disposeBag)

        // 검색 트리거
        searchBar.textField.rx.controlEvent(.editingDidEndOnExit)
            .bind(to: searchTrigger)
            .disposed(by: disposeBag)

        // 네비게이션 검색 버튼 트리거
        navigationItem.rightBarButtonItem?.rx.tap
            .bind(to: searchTrigger)
            .disposed(by: disposeBag)

        // 셀 선택 -> 상세 화면 이동
        collectionView.rx.itemSelected
            .asDriver()
            .withLatestFrom(output.books) { indexPath, items in
                return items[indexPath.item]
            }
            .drive(with: self) { owner, item in
                let detailVC = BookDetailViewController(book: item)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    func configureHierarchy() {
        [searchBar, resultCountLabel, collectionView].forEach {
            view.addSubview($0)
        }
    }

    func configureLayout() {
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        resultCountLabel.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(resultCountLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    func configureView() {
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = false
    }

    // MARK: - Helper Methods

    /// 검색 결과의 좋아요 상태 로드
    private func loadFavoriteStates(for items: [Item]) {
        favoriteStates.removeAll()

        for item in items {
            guard let isbn13 = item.isbn13 else { continue }

            do {
                let existingBook = try bookRepository.getBook(byISBN: isbn13)
                favoriteStates[isbn13] = (existingBook != nil)
            } catch {
                print("좋아요 상태 로드 실패: \(error)")
                favoriteStates[isbn13] = false
            }
        }
    }

    /// 좋아요 상태 업데이트: ISBN13 기준으로 저장하고, 화면에 보이는 해당 도서 셀만 갱신
    private func updateFavoriteState(isbn13: String, isFavorite: Bool) {
        favoriteStates[isbn13] = isFavorite

        for indexPath in collectionView.indexPathsForVisibleItems
        where indexPath.item < currentItems.count && currentItems[indexPath.item].isbn13 == isbn13 {
            let cell = collectionView.cellForItem(at: indexPath) as? SearchCollectionViewCell
            cell?.updateFavoriteState(isFavorite)
        }
    }

    // MARK: - Folder Selection Alert

    private func showFolderSelectionAlert(for item: Item) {
        guard let window = view.window else { return }

        let folderSelectionView = FolderSelectionView(bookTitle: item.title ?? "도서")
        let folderSelectionVM = FolderSelectionViewModel()

        let input = FolderSelectionViewModel.Input(
            viewDidLoad: Observable.just(()),
            folderSelected: folderSelectionView.folderSelected.asObservable(),
            createFolderTapped: folderSelectionView.createFolderTapped.asObservable()
        )

        let output = folderSelectionVM.transform(input)

        folderSelectionView.bind(folders: output.folders.asObservable())

        // 폴더 선택 이벤트
        output.selectedFolder
            .drive(with: self) { owner, selectedFolder in
                folderSelectionView.hide()
                owner.viewModel.addBookToSelectedFolder(item: item, folder: selectedFolder)
                    .bind(with: self) { owner, result in
                        if result .isAdded, let isbn13 = item.isbn13 {
                            owner.updateFavoriteState(isbn13: isbn13, isFavorite: true)
                        }
                        owner.view.makeToast(result.message)
                    }
                    .disposed(by: owner.disposeBag)
            }
            .disposed(by: disposeBag)
        

        // 새 폴더 만들기
        output.showCreateFolder
            .drive(with: self) { owenr, _ in
                folderSelectionView.hide()
            }
            .disposed(by: disposeBag)

        // 닫기 이벤트
        folderSelectionView.closeTapped
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owenr, _ in
                folderSelectionView.hide()
            }
            .disposed(by: disposeBag)
        
        folderSelectionView.show(in: window)
    }

    private func showDeleteConfirmationAlert(for item: Item, deleteConfirmed: PublishRelay<Item>) {
        let alert = UIAlertController(
            title: "도서 삭제",
            message: "저장된 도서를 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)

        let confirmAction = UIAlertAction(title: "확인", style: .destructive) { _ in
            deleteConfirmed.accept(item)
        }

        alert.addAction(cancelAction)
        alert.addAction(confirmAction)

        present(alert, animated: true, completion: nil)
    }

}

