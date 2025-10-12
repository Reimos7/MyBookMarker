//
//  FolderSelectionView.swift
//  BookMarker
//
//  Created by Reimos on 10/2/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

// 폴더 선택 커스텀 Alert View
final class FolderSelectionView: UIView {

    private let dimmedView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }

    // 컨테이너 뷰
    private let containerView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
    }

    // 닫기 버튼
    private let closeButton = UIButton().then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .systemGray
    }

    // 타이틀 레이블
    private let titleLabel = UILabel().then {
        $0.text = "폴더 선택"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .label
    }

    // 서브 타이틀 레이블 (도서 제목)
    private let subtitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .systemGray
        $0.numberOfLines = 2
    }

    // 폴더 목록 CollectionView
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .clear
        $0.register(FolderSelectionCell.self, forCellWithReuseIdentifier: FolderSelectionCell.reuseIdentifier)
        $0.showsVerticalScrollIndicator = true
    }

    // 새 폴더 만들기 버튼
    private let createFolderButton = UIButton().then {
        $0.setTitle("+ 새 폴더 만들기", for: .normal)
        $0.setTitleColor(.systemGray, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray4.cgColor
        $0.layer.cornerRadius = 12
        $0.backgroundColor = .clear
        
        $0.isHidden = true
    }

    private let disposeBag = DisposeBag()

    // 폴더 선택 이벤트
    let folderSelected = PublishSubject<FolderRealmModel>()

    // 새 폴더 만들기 이벤트
    let createFolderTapped = PublishSubject<Void>()

    // 닫기 이벤트
    let closeTapped = PublishSubject<Void>()

    init(bookTitle: String) {
        super.init(frame: .zero)
        subtitleLabel.text = "\"\(bookTitle)\"을(를) 저장할 폴더를 선택하세요"
        setupUI()
        bindActions()
    }

    init(placeTitle: String) {
        super.init(frame: .zero)
        subtitleLabel.text = "\"\(placeTitle)\"을(를) 저장할 폴더를 선택하세요"
        setupUI()
        bindActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(dimmedView)
        addSubview(containerView)
        
        [closeButton,titleLabel,subtitleLabel,collectionView,createFolderButton].forEach {
            containerView.addSubview($0)
        }

        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        containerView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(24)
            $0.height.equalTo(500)
        }

        closeButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(20)
            $0.leading.equalToSuperview().inset(20)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalTo(createFolderButton.snp.top).offset(-16)
        }

        createFolderButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.bottom.equalToSuperview().inset(20)
            $0.height.equalTo(48)
        }
    }

    private func bindActions() {
        // 닫기 버튼 탭
        closeButton.rx.tap
            .bind(to: closeTapped)
            .disposed(by: disposeBag)

        // 딤 뷰 탭
        let dimTapGesture = UITapGestureRecognizer()
        dimmedView.addGestureRecognizer(dimTapGesture)
        dimTapGesture.rx.event
            .map { _ in }
            .bind(to: closeTapped)
            .disposed(by: disposeBag)

        // 새 폴더 만들기 버튼 탭
        createFolderButton.rx.tap
            .bind(to: createFolderTapped)
            .disposed(by: disposeBag)
    }

    // MARK: - CollectionView Layout

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Public Methods

    // 폴더 데이터 바인딩
    func bind(folders: Observable<[FolderRealmModel]>) {
        folders
            .bind(to: collectionView.rx.items(
                cellIdentifier: FolderSelectionCell.reuseIdentifier,
                cellType: FolderSelectionCell.self
            )) { index, folder, cell in
                cell.configure(with: folder)
            }
            .disposed(by: disposeBag)

        // 셀 선택 이벤트
        collectionView.rx.modelSelected(FolderRealmModel.self)
            .bind(to: folderSelected)
            .disposed(by: disposeBag)
    }

    // 애니메이션과 함께 표시
    func show(in view: UIView) {
        view.addSubview(self)
        self.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 초기 상태
        alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        // 애니메이션
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.containerView.transform = .identity
        }
    }

    // 애니메이션과 함께 숨김
    func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}
