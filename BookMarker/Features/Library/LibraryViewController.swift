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
import RealmSwift

final class LibraryViewController: UIViewController {

    private let headerView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    private let titleLabel = UILabel().then {
        $0.text = "내 파일"
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .label
    }

    private let addButton = UIButton().then {
        $0.setImage(UIImage(systemName: "plus"), for: .normal)
        $0.tintColor = .label
        $0.contentMode = .scaleAspectFit
    }

    // TODO: v2.0 - 내 장소 기능 활성화 시 주석 해제
    // 내 서재 / 내 장소 전환 세그먼트 컨트롤
//    private let segmentedControl = UISegmentedControl(items: ["내 서재", "내 장소"]).then {
//        $0.selectedSegmentIndex = 0
//        $0.backgroundColor = .systemGray6
//        $0.selectedSegmentTintColor = .systemBackground
//        $0.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .selected)
//        $0.setTitleTextAttributes([.foregroundColor: UIColor.secondaryLabel], for: .normal)
//    }

    // 내 서재 뷰 
    private let myLibraryView = UIView()

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    private let foldersStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 20
        $0.distribution = .fill
    }

    // TODO: v2.0 - 내 장소 기능 활성화 시 주석 해제
    // 내 장소 뷰
//    private let myPlacesView = MyPlacesView()

    private let disposeBag = DisposeBag()
    private let viewModel = LibraryViewModel()

    // 폴더 데이터 관리 (내 서재용)
    private var bookCardViews: [BookCardView] = []
    private var cardViewDisposeBags: [DisposeBag] = []

    // TODO: v2.0 - 내 장소 기능 활성화 시 주석 해제
    // 폴더 데이터 관리 (내 장소용)
//    private var placeCardViews: [BookCardView] = []
//    private var placeCardViewDisposeBags: [DisposeBag] = []

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

extension LibraryViewController: DesignProtocol {

    func configureHierarchy() {
        // TODO: v2.0 - 내 장소 기능 활성화 시 myPlacesView 추가
        [headerView, myLibraryView].forEach {
            view.addSubview($0)
        }

        myLibraryView.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(foldersStackView)

        // TODO: v2.0 - 내 장소 기능 활성화 시 segmentedControl 추가
        [titleLabel, addButton].forEach {
            headerView.addSubview($0)
        }
    }

    func configureLayout() {
        // TODO: v2.0 - 내 장소 기능 활성화 시 height 108로 변경
        headerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(56) // 세그먼트 없으므로 높이 감소
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

        // TODO: v2.0 - 내 장소 기능 활성화 시 주석 해제
//        segmentedControl.snp.makeConstraints {
//            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
//            $0.leading.equalToSuperview().offset(16)
//            $0.trailing.equalToSuperview().offset(-16)
//            $0.height.equalTo(36)
//        }

        myLibraryView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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

        // TODO: v2.0 - 내 장소 기능 활성화 시 주석 해제
//        myPlacesView.snp.makeConstraints {
//            $0.top.equalTo(headerView.snp.bottom)
//            $0.leading.trailing.equalToSuperview()
//            $0.bottom.equalTo(view.safeAreaLayoutGuide)
//        }
    }

    func configureView() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)

        navigationController?.navigationBar.tintColor = .black
        navigationItem.backButtonTitle = ""

        // 초기 상태: 내 서재만 표시
        myLibraryView.isHidden = false

        // TODO: v2.0 - 내 장소 기능 활성화 시 주석 해제
//        myPlacesView.isHidden = true
    }

    // TODO: v2.0 - 내 장소 기능 활성화 시 주석 해제
    // 세그먼트 인덱스에 따라 뷰 전환
//    private func switchView(to index: Int) {
//        if index == 0 {
//            // 내 서재 선택
//            myLibraryView.isHidden = false
//            myPlacesView.isHidden = true
//        } else {
//            // 내 장소 선택
//            myLibraryView.isHidden = true
//            myPlacesView.isHidden = false
//        }
//    }

    // 내 서재 폴더 카드 생성 (도서 폴더)
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

    // TODO: v2.0 - 내 장소 기능 활성화 시 주석 해제
    // 내 장소 폴더 카드 생성 (장소 폴더)
//    private func createPlaceCardViews(with folders: [BookCardView.FolderBookData]) {
//        // 기존 뷰들과 disposeBag들 제거
//        placeCardViews.forEach { $0.removeFromSuperview() }
//        placeCardViews.removeAll()
//        placeCardViewDisposeBags.removeAll()
//
//        let placeRepository = PlaceRepository()
//
//        // 새로운 CardView들 생성
//        for folderData in folders {
//            let placeCardView = BookCardView()
//            let cardDisposeBag = DisposeBag()
//
//            // PlaceCoverCell 등록
//            placeCardView.booksCollectionView.register(
//                PlaceCoverCell.self,
//                forCellWithReuseIdentifier: PlaceCoverCell.reuseIdentifier
//            )
//
//            // 폴더 데이터 설정
//            placeCardView.configure(with: folderData)
//
//            // 폴더 카드 탭 이벤트 바인딩
//            placeCardView.onFolderTapped = { [weak self, folderData] in
//                print("장소 폴더 카드 탭됨: \(folderData.title)")
//                self?.folderTappedSubject.onNext(folderData)
//            }
//
//            // 메뉴 버튼 이벤트 바인딩
//            placeCardView.menuButton.rx.tap
//                .do(onNext: { _ in
//                    print("장소 폴더 메뉴 버튼 탭됨: \(folderData.title)")
//                })
//                .map { [folderData] _ in folderData }
//                .bind(to: folderMenuTappedSubject)
//                .disposed(by: cardDisposeBag)
//
//            // 해당 폴더의 실제 장소 데이터 가져오기
//            do {
//                // String id를 ObjectId로 변환
//                guard let objectId = try? ObjectId(string: folderData.id) else {
//                    print("Invalid ObjectId: \(folderData.id)")
//                    continue
//                }
//                let places = try placeRepository.getPlaces(in: objectId)
//
//                // 컬렉션뷰 데이터 바인딩 (장소 목록)
//                placeCardView.booksCollectionView.dataSource = nil
//                Observable.just(places)
//                    .bind(to: placeCardView.booksCollectionView.rx.items(
//                        cellIdentifier: PlaceCoverCell.reuseIdentifier,
//                        cellType: PlaceCoverCell.self
//                    )) { (itemIndex: Int, place: PlaceRealmModel, cell: PlaceCoverCell) in
//                        cell.configure(with: place)
//                    }
//                    .disposed(by: cardDisposeBag)
//
//                // 장소 탭 이벤트 (추후 구현)
//                placeCardView.booksCollectionView.rx.modelSelected(PlaceRealmModel.self)
//                    .subscribe(onNext: { place in
//                        print("장소 선택됨: \(place.name ?? "이름없음")")
//                        // TODO: 장소 상세 화면 이동
//                    })
//                    .disposed(by: cardDisposeBag)
//
//            } catch {
//                print("장소 데이터 로드 실패: \(error)")
//                // 빈 배열 바인딩
//                Observable.just([PlaceRealmModel]())
//                    .bind(to: placeCardView.booksCollectionView.rx.items(
//                        cellIdentifier: PlaceCoverCell.reuseIdentifier,
//                        cellType: PlaceCoverCell.self
//                    )) { (itemIndex: Int, place: PlaceRealmModel, cell: PlaceCoverCell) in
//                        cell.configure(with: place)
//                    }
//                    .disposed(by: cardDisposeBag)
//            }
//
//            placeCardViews.append(placeCardView)
//            placeCardViewDisposeBags.append(cardDisposeBag)
//            myPlacesView.foldersStackView.addArrangedSubview(placeCardView)
//
//            // 높이 제약 설정
//            placeCardView.snp.makeConstraints {
//                $0.height.equalTo(BookCardView.estimatedHeight())
//            }
//        }
//    }

    private func setupBindings() {
        // TODO: v2.0 - 내 장소 기능 활성화 시 segmentedControl.rx.selectedSegmentIndex.asObservable()로 변경
        let input = LibraryViewModel.Input(
            viewWillAppear: viewWillAppearSubject.asObservable(),
            segmentChanged: Observable.just(0), // 항상 0 (내 서재)
            addButtonTapped: addButton.rx.tap.asObservable(),
            folderMenuTapped: folderMenuTappedSubject.asObservable(),
            folderTapped: folderTappedSubject.asObservable(),
            bookTapped: bookTappedSubject.asObservable()
        )

        let output = viewModel.transform(input)

        // TODO: v2.0 - 내 장소 기능 활성화 시 combineLatest로 변경하여 세그먼트에 따라 분기
        // 폴더들 업데이트 (내 서재만 표시)
        output.folders.asObservable()
            .bind(with: self) { owner, folders in
                // 항상 내 서재 폴더만 표시
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
            .drive(with: self) { owner, folderData in
                let folderDetailVC = FolderDetailViewController(folderData: folderData)
                owner.navigationController?.pushViewController(folderDetailVC, animated: true)
            }
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

        // TODO: v2.0 - 내 장소 기능 활성화 시 주석 해제
        // 세그먼트 변경 시 뷰 전환
//        output.selectedSegment
//            .drive(with: self) { owner, index in
//                print("세그먼트 선택: \(index)")
//                owner.switchView(to: index)
//            }
//            .disposed(by: disposeBag)
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
                self?.showDeleteFolderConfirmAlert(for: folderData)
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

    private func showDeleteFolderConfirmAlert(for folderData: BookCardView.FolderBookData) {
        let alert = UIAlertController(
            title: "폴더 삭제",
            message: "'\(folderData.title)' 폴더를 삭제하시겠습니까?\n폴더 내의 모든 도서도 함께 삭제됩니다.",
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        let confirmAction = UIAlertAction(title: "확인", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteFolder(folderId: folderData.id)
        }

        alert.addAction(cancelAction)
        alert.addAction(confirmAction)

        present(alert, animated: true)
    }
}
