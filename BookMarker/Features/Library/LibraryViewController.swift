//
//  LibraryViewController.swift
//  BookMarker
//
//  Created by Reimos on 9/30/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class LibraryViewController: UIViewController {

    // MARK: - UI Components
    private let headerView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    private let titleLabel = UILabel().then {
        $0.text = "내 서재"
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .label
    }

    private let addButton = UIButton().then {
        $0.setImage(UIImage(systemName: "plus"), for: .normal)
        $0.tintColor = .label
        $0.contentMode = .scaleAspectFit
    }

    private let segmentedControl = UISegmentedControl(items: ["내 서재", "내 장소"]).then {
        $0.selectedSegmentIndex = 0
        $0.backgroundColor = .systemGray6
        $0.selectedSegmentTintColor = .systemBackground
        $0.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .selected)
        $0.setTitleTextAttributes([.foregroundColor: UIColor.secondaryLabel], for: .normal)
    }

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    private let foldersStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 20
        $0.distribution = .fill
    }

    private let disposeBag = DisposeBag()
    private let viewModel = LibraryViewModel()

    // 폴더 데이터 관리
    private var bookCardViews: [BookCardView] = []
    private var cardViewDisposeBags: [DisposeBag] = []

    // Subject들
    private let folderMenuTappedSubject = PublishSubject<BookCardView.FolderBookData>()
    private let folderTappedSubject = PublishSubject<BookCardView.FolderBookData>()
    private let bookTappedSubject = PublishSubject<Item>()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureLayout()
        configureView()
        setupBindings()
    }

    private let viewWillAppearSubject = PublishSubject<Void>()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)

        // ViewModel에 화면 진입 알림
        viewWillAppearSubject.onNext(())
    }
}

// MARK: - UI Configuration
extension LibraryViewController: DesignProtocol {

    func configureHierarchy() {
        view.addSubview(headerView)
        view.addSubview(scrollView)

        headerView.addSubview(titleLabel)
        headerView.addSubview(addButton)
        headerView.addSubview(segmentedControl)

        scrollView.addSubview(contentView)
        contentView.addSubview(foldersStackView)
    }

    func configureLayout() {
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(120)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
        }

        addButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.size.equalTo(24)
        }

        segmentedControl.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(36)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        foldersStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-20)
        }
    }

    func configureView() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func createBookCardViews(with folders: [BookCardView.FolderBookData]) {
        // 기존 뷰들과 disposeBag들 제거
        bookCardViews.forEach { $0.removeFromSuperview() }
        bookCardViews.removeAll()
        cardViewDisposeBags.removeAll()

        // 새로운 BookCardView들 생성
        for folderData in folders {
            let bookCardView = BookCardView()
            let cardDisposeBag = DisposeBag()

            bookCardView.configure(with: folderData)

            // 폴더 카드 탭 이벤트 바인딩
            bookCardView.onFolderTapped = { [weak self, folderData] in
                print("폴더 카드 탭됨: \(folderData.title)")
                self?.folderTappedSubject.onNext(folderData)
            }

            // 메뉴 버튼 이벤트 바인딩 (클로저 캡처 문제 해결)
            bookCardView.menuButton.rx.tap
                .do(onNext: { _ in
                    print("메뉴 버튼 탭됨: \(folderData.title)")
                })
                .map { [folderData] _ in folderData }
                .bind(to: folderMenuTappedSubject)
                .disposed(by: cardDisposeBag)

            // 컬렉션뷰 책 데이터 바인딩 (데이터소스 초기화)
            bookCardView.booksCollectionView.dataSource = nil
            Observable.just(folderData.books)
                .bind(to: bookCardView.booksCollectionView.rx.items(
                    cellIdentifier: BookCoverCell.reuseIdentifier,
                    cellType: BookCoverCell.self
                )) { (itemIndex: Int, item: Item, cell: BookCoverCell) in
                    cell.configure(with: item)
                }
                .disposed(by: cardDisposeBag)

            // 컬렉션뷰 셀 탭 이벤트 바인딩 (클로저 캡처 문제 해결)
            bookCardView.booksCollectionView.rx.itemSelected
                .map { [folderData] indexPath in folderData.books[indexPath.item] }
                .bind(to: bookTappedSubject)
                .disposed(by: cardDisposeBag)

            bookCardViews.append(bookCardView)
            cardViewDisposeBags.append(cardDisposeBag)
            foldersStackView.addArrangedSubview(bookCardView)

            // 높이 제약 설정
            bookCardView.snp.makeConstraints {
                $0.height.equalTo(BookCardView.estimatedHeight())
            }
        }
    }

    private func setupBindings() {
        let input = LibraryViewModel.Input(
            viewWillAppear: viewWillAppearSubject.asObservable(),
            segmentChanged: segmentedControl.rx.selectedSegmentIndex.asObservable(),
            addButtonTapped: addButton.rx.tap.asObservable(),
            folderMenuTapped: folderMenuTappedSubject.asObservable(),
            folderTapped: folderTappedSubject.asObservable(),
            bookTapped: bookTappedSubject.asObservable()
        )

        let output = viewModel.transform(input)

        // 폴더들 업데이트
        output.folders
            .drive(with: self) { owner, folders in
                owner.createBookCardViews(with: folders)
            }
            .disposed(by: disposeBag)

        // 책 상세화면으로 이동
        output.navigateToBookDetail
            .filter { $0.title != nil }
            .drive(with: self) { owner, book in
                let detailVC = BookDetailViewController(book: book)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

        // 폴더 상세화면으로 이동
        output.navigateToFolderDetail
            .drive(onNext: { [weak self] folderData in
                let folderDetailVC = FolderDetailViewController(folderData: folderData)
                self?.navigationController?.pushViewController(folderDetailVC, animated: true)
            })
            .disposed(by: disposeBag)

        // 폴더 메뉴 표시
        output.showFolderMenu
            .do(onNext: { folderData in
                print("ViewController에서 showFolderMenu 받음: \(folderData.title)")
            })
            .drive(with: self) { owner, folderData in
                print("showFolderMenuAlert 호출 시작")
                owner.showFolderMenuAlert(for: folderData)
            }
            .disposed(by: disposeBag)

        // 새 폴더 추가 알럿
        output.showAddFolderAlert
            .drive(with: self) { owner, _ in
                owner.showAddFolderAlert()
            }
            .disposed(by: disposeBag)

        // 세그먼트 컨트롤
        output.selectedSegment
            .drive(with: self) { owner, index in
                print("세그먼트 선택: \(index)")
                let indexTitle = index == 0 ? "내 서재" : "내 장소"
                self.titleLabel.text = indexTitle
                // TODO: 내 서재 / 내 장소 전환 로직
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Helper Methods
    private func showFolderMenuAlert(for folderData: BookCardView.FolderBookData) {
        print("showFolderMenuAlert 호출됨: \(folderData.title), isEditable: \(folderData.isEditable)")
        let alert = UIAlertController(title: folderData.title, message: nil, preferredStyle: .actionSheet)

        if folderData.isEditable {
            let editAction = UIAlertAction(title: "편집", style: .default) { [weak self] _ in
                self?.showEditFolderAlert(for: folderData)
            }
            alert.addAction(editAction)

            // 편집 가능한 폴더는 삭제도 가능 (기본 폴더는 isEditable == false)
            let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
                self?.viewModel.deleteFolder(folderId: folderData.id)
            }
            alert.addAction(deleteAction)
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    private func showEditFolderAlert(for folderData: BookCardView.FolderBookData) {
        let alert = UIAlertController(title: "폴더 편집", message: "새로운 폴더 이름을 입력해주세요", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.text = folderData.title
            textField.placeholder = "폴더 이름"
        }

        let saveAction = UIAlertAction(title: "저장", style: .default) { [weak self] _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            self?.viewModel.updateFolderName(folderId: folderData.id, newName: newName)
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    private func showAddFolderAlert() {
        let alert = UIAlertController(title: "새 폴더", message: "폴더 이름을 입력해주세요", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "폴더 이름"
        }

        let addAction = UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            guard let folderName = alert.textFields?.first?.text, !folderName.isEmpty else { return }
            self?.viewModel.addFolder(name: folderName)
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(addAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
}
