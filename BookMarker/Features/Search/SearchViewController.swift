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
        //$0.text = "검색 결과 (0건)"
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
        title = ""
        navigationController?.navigationBar.tintColor = .black

        // 탭바에서 진입하므로 백버튼 숨김
        navigationItem.leftBarButtonItem = nil
        navigationItem.hidesBackButton = true
    }

//    @objc private func searchButtonTapped() {
//        searchBar.textField.becomeFirstResponder()
//    }
//    
   
}


// MARK: - DesiginProtocolBind
extension SearchViewController: DesiginProtocolBind {
    
    func bind() {
        let searchTrigger = PublishSubject<Void>()
        let favoriteButtonTappedSubject = PublishSubject<(Item, Int)>()
        let deleteConfirmedSubject = PublishSubject<(Item, Int)>()

        let input = SearchViewModel.Input(
            searchText: searchBar.textField.rx.text.orEmpty.asObservable(),
            searchTrigger: searchTrigger.asObservable(),
            favoriteButtonTapped: favoriteButtonTappedSubject.asObservable(),
            deleteConfirmed: deleteConfirmedSubject.asObservable()
        )

        let output = viewModel.transform(input)

        // 검색 결과를 컬렉션뷰에 바인딩
        output.books
            .drive(onNext: { [weak self] items in
                guard let self = self else { return }
                // 현재 아이템 저장
                self.currentItems = items
                // 검색 결과가 로드되면 좋아요 상태 초기화
                self.loadFavoriteStates(for: items)
            })
            .disposed(by: disposeBag)

        output.books
            .drive(collectionView.rx.items(
                cellIdentifier: SearchCollectionViewCell.reuseIdentifier,
                cellType: SearchCollectionViewCell.self
            )) { [weak self] index, item, cell in
                guard let self = self else { return }
                // 좋아요 상태 확인
                let isFavorite = self.favoriteStates[item.isbn13 ?? ""] ?? false
                cell.configure(with: item, isFavorite: isFavorite)

                // 좋아요 버튼 탭 이벤트
                cell.favoriteButtonTapped = {
                    favoriteButtonTappedSubject.onNext((item, index))
                }
            }
            .disposed(by: disposeBag)

        // 검색 결과 개수 표시 (TODO: 나중에 구현)
//        output.resultCount
//            .drive(resultCountLabel.rx.text)
//            .disposed(by: disposeBag)

        // 로딩 상태 처리
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                // TODO: 로딩 인디케이터 표시/숨김
            })
            .disposed(by: disposeBag)

        // 에러 처리
        output.error
            .filter { !$0.isEmpty }
            .drive(with: self) { owner, error in
                owner.view.makeToast(error)
            }
            .disposed(by: disposeBag)

//            .drive(onNext: { [weak self] error in
//                self?.view.makeToast(error)
//            })
//            .disposed(by: disposeBag)

        // Toast 메시지 표시
        output.showToast
            .filter { !$0.isEmpty }
            .drive(with: self) { owner, message in
                owner.view.makeToast(message)
            }
            .disposed(by: disposeBag)

        // 폴더 선택 Alert 표시
        output.showFolderSelection
            .drive(onNext: { [weak self] (item, index) in
                self?.showFolderSelectionAlert(for: item, at: index)
            })
            .disposed(by: disposeBag)

        // 삭제 확인 Alert 표시
        output.showDeleteConfirmation
            .drive(onNext: { [weak self] (item, index) in
                self?.showDeleteConfirmationAlert(for: item, at: index, deleteConfirmed: deleteConfirmedSubject)
            })
            .disposed(by: disposeBag)

        // 좋아요 상태 업데이트
        output.updateFavoriteState
            .drive(onNext: { [weak self] (index, isFavorite) in
                self?.updateCellFavoriteState(at: index, isFavorite: isFavorite)
            })
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
            .drive(onNext: { [weak self] item in
                guard let self = self else { return }
                let detailVC = BookDetailViewController(book: item)
                self.navigationController?.pushViewController(detailVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func configureHierarchy() {
        [searchBar, resultCountLabel, collectionView].forEach {
            view.addSubview($0)
        }
    }

    func configureLayout() {
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        resultCountLabel.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(resultCountLabel.snp.bottom).offset(12)
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

    /// 특정 셀의 좋아요 상태 업데이트
    private func updateCellFavoriteState(at index: Int, isFavorite: Bool) {
        // ISBN13 기반으로 favoriteStates 업데이트
        if index < currentItems.count,
           let isbn13 = currentItems[index].isbn13 {
            favoriteStates[isbn13] = isFavorite
        }

        // 셀이 화면에 보이는 경우에만 업데이트
        if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? SearchCollectionViewCell {
            cell.updateFavoriteState(isFavorite)
        }
    }

    // MARK: - Folder Selection Alert

    private func showFolderSelectionAlert(for item: Item, at index: Int) {
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
            .drive(onNext: { [weak self] selectedFolder in
                guard let self = self else { return }
                folderSelectionView.hide()

                self.viewModel.addBookToSelectedFolder(item: item, folder: selectedFolder, index: index)
                    .subscribe(onNext: { [weak self] (index, success, message) in
                        guard let self = self else { return }
                        if success {
                            self.updateCellFavoriteState(at: index, isFavorite: true)
                            if let isbn13 = item.isbn13 {
                                self.favoriteStates[isbn13] = true
                            }
                        }
                        self.view.makeToast(message)
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)

        // 새 폴더 만들기
        output.showCreateFolder
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                folderSelectionView.hide()
                print("새 폴더 만들기 화면으로 이동")
            })
            .disposed(by: disposeBag)

        // 닫기 이벤트
        folderSelectionView.closeTapped
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                folderSelectionView.hide()
            })
            .disposed(by: disposeBag)

        folderSelectionView.show(in: window)
    }

    private func showDeleteConfirmationAlert(for item: Item, at index: Int, deleteConfirmed: PublishSubject<(Item, Int)>) {
        let alert = UIAlertController(
            title: "도서 삭제",
            message: "저장된 도서를 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)

        let confirmAction = UIAlertAction(title: "확인", style: .destructive) { _ in
            deleteConfirmed.onNext((item, index))
        }

        alert.addAction(cancelAction)
        alert.addAction(confirmAction)

        present(alert, animated: true, completion: nil)
    }

}

