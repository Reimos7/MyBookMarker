//
//  FolderDetailViewController.swift
//  BookMarker
//
//  Created by Claude on 10/3/25.
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

        layout.itemSize = CGSize(width: itemWidth, height: 320)
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
        let input = FolderDetailViewModel.Input()
        let output = viewModel.transform(input)

        // 책 목록 바인딩
        output.books
            .drive(collectionView.rx.items(
                cellIdentifier: BookGridCell.reuseIdentifier,
                cellType: BookGridCell.self
            )) { index, item, cell in
                cell.configure(with: item)

                // 상태 뱃지 설정 (선택적)
                // cell.setStatusBadge(text: "완독", color: .systemGreen)
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
        

        // 셀 선택 -> 상세 화면 이동
        collectionView.rx.itemSelected
            .asDriver()
            .withLatestFrom(output.books) { indexPath, books in
                return books[indexPath.item]
            }
            .drive(with: self) { owner, book in
                let detailVC = BookDetailViewController(book: book)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)
    }
}
