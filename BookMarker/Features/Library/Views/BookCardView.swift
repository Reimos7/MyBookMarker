//
//  BookCardView.swift
//  BookMarker
//
//  Created by Reimos on 9/30/25.
//

import UIKit
import SnapKit
import Then

final class BookCardView: UIView {

    // MARK: - Model
    struct FolderBookData {
        let id: String
        let title: String
        let subtitle: String
        let iconColor: UIColor
        let books: [Item]
        let isEditable: Bool

        init(id: String = UUID().uuidString,
             title: String,
             subtitle: String,
             iconColor: UIColor = .systemTeal,
             books: [Item] = [],
             isEditable: Bool = true) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.iconColor = iconColor
            self.books = books
            self.isEditable = isEditable
        }
    }

    // MARK: - UI Components
    private let containerView = UIView().then {
        $0.backgroundColor = .systemTeal.withAlphaComponent(0.1)
        $0.layer.cornerRadius = 12
    }

    private let headerView = UIView()

    private let folderIconView = UIView().then {
        $0.layer.cornerRadius = 8
    }

    private let folderIcon = UIImageView().then {
        $0.image = UIImage(systemName: "folder.fill")
        $0.contentMode = .scaleAspectFit
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .label
    }

    private let dateLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 2
    }

    let menuButton = UIButton().then {
        $0.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        $0.tintColor = .secondaryLabel
        $0.contentMode = .scaleAspectFit
    }

    lazy var booksCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.register(BookCoverCell.self, forCellWithReuseIdentifier: BookCoverCell.reuseIdentifier)
        $0.showsHorizontalScrollIndicator = false
        $0.backgroundColor = .clear
        $0.isScrollEnabled = true
    }

    // MARK: - Properties
    private var folderData: FolderBookData?

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(headerView)
        containerView.addSubview(booksCollectionView)

        headerView.addSubview(folderIconView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(dateLabel)
        headerView.addSubview(menuButton)

        folderIconView.addSubview(folderIcon)

        setupLayout()
    }

    private func setupLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        headerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(40)
        }

        folderIconView.snp.makeConstraints {
            $0.leading.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }

        folderIcon.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalTo(folderIconView.snp.trailing).offset(12)
            $0.trailing.equalTo(menuButton.snp.leading).offset(-12)
        }

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.trailing.equalTo(titleLabel.snp.trailing)
        }

        menuButton.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        booksCollectionView.snp.makeConstraints {
            $0.top.equalTo(headerView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-16)
            $0.height.equalTo(140)
        }
    }

    private func createLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 140)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return layout
    }

    // MARK: - Public Methods
    func configure(with data: FolderBookData) {
        folderData = data

        titleLabel.text = data.title
        dateLabel.text = data.subtitle

        // 아이콘 색상 설정
        folderIconView.backgroundColor = data.iconColor.withAlphaComponent(0.3)
        folderIcon.tintColor = data.iconColor
        containerView.backgroundColor = data.iconColor.withAlphaComponent(0.1)

        // 메뉴 버튼 표시/숨김
        menuButton.isHidden = !data.isEditable
    }

    // MARK: - Getter
    var currentFolderData: FolderBookData? {
        return folderData
    }

    // MARK: - Height Calculation
    static func estimatedHeight() -> CGFloat {
        return 16 + 40 + 16 + 140 + 16 // top + header + gap + collection + bottom
    }
}
