//
//  BookCoverCell.swift
//  BookMarker
//
//  Created by Reimos on 9/30/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class BookCoverCell: BaseCollectionViewCell {

    // MARK: - UI Components
    private let bookImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 6
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .label
        $0.numberOfLines = 2
        $0.textAlignment = .center
        $0.lineBreakMode = .byTruncatingTail
    }

    private let authorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 10, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.numberOfLines = 1
    }

    // MARK: - Initialization
    override func configureHierarchy() {
        contentView.addSubview(bookImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorLabel)
    }

    override func configureLayout() {
        bookImageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(100)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(bookImageView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
        }

        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
        }
    }

    override func configureView() {
        backgroundColor = .clear
    }

    // MARK: - Configuration
    func configure(with item: Item) {
        titleLabel.text = item.title

        // 저자명 정제
        if let rawAuthor = item.author, !rawAuthor.isEmpty {
            let mainAuthor = rawAuthor
                .components(separatedBy: ",").first?
                .components(separatedBy: "(").first?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            authorLabel.text = mainAuthor
        } else {
            authorLabel.text = "저자미상"
        }

        // 책 이미지 설정
        if let coverURL = item.cover, let url = URL(string: coverURL) {
            bookImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "book.closed"),
                options: [.transition(.fade(0.3))]
            )
        } else {
            bookImageView.image = UIImage(systemName: "book.closed")
            bookImageView.tintColor = .systemGray4
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bookImageView.kf.cancelDownloadTask()
        bookImageView.image = nil
        titleLabel.text = nil
        authorLabel.text = nil
    }
}