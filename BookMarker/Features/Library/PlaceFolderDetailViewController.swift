//
//  PlaceFolderDetailViewController.swift
//  BookMarker
//
//  Created by Claude on 1/18/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa
import RealmSwift

final class PlaceFolderDetailViewController: UIViewController {

    // MARK: - Properties
    private let folderData: BookCardView.FolderBookData
    private let viewModel: PlaceFolderDetailViewModel
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
        $0.register(PlaceGridCell.self, forCellWithReuseIdentifier: PlaceGridCell.reuseIdentifier)
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .systemBackground
    }

    private let emptyLabel = UILabel().then {
        $0.text = "저장된 장소가 없습니다"
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.isHidden = true
    }

    // MARK: - Init
    init(folderData: BookCardView.FolderBookData) {
        self.folderData = folderData
        self.viewModel = PlaceFolderDetailViewModel(folderData: folderData)
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

        navigationController?.navigationBar.tintColor = .black
        navigationItem.backButtonTitle = ""
    }
}

// MARK: - DesignProtocol
extension PlaceFolderDetailViewController: DesignProtocol {
    func configureHierarchy() {
        [collectionView, emptyLabel].forEach {
            view.addSubview($0)
        }
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
        let input = PlaceFolderDetailViewModel.Input(
            refreshTrigger: refreshTrigger.asObservable()
        )

        let output = viewModel.transform(input)

        // 장소 목록 바인딩
        output.places
            .drive(collectionView.rx.items(
                cellIdentifier: PlaceGridCell.reuseIdentifier,
                cellType: PlaceGridCell.self
            )) { [weak self] (index, place, cell) in
                cell.configure(with: place)
            }
            .disposed(by: disposeBag)

        // 빈 상태 처리
        output.places
            .map { $0.isEmpty }
            .drive(with: self) { owner, isEmpty in
                owner.emptyLabel.isHidden = !isEmpty
                owner.collectionView.isHidden = isEmpty
            }
            .disposed(by: disposeBag)

        // 셀 선택 이벤트
        collectionView.rx.modelSelected(PlaceRealmModel.self)
            .bind(with: self) { owner, place in
                print("장소 선택됨: \(place.name)")
                let detailVC = PlaceDetailViewController(place: place)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)
    }
}
