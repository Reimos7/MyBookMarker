//
//  BookGridCell.swift
//  BookMarker
//
//  Created by Reimos on 10/3/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class BookGridCell: BaseCollectionViewCell {

    // MARK: - UI Components
    private let containerView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 12
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
    }

    private let coverImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        //$0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    private let statusBadge = UILabel().then {
        $0.font = .systemFont(ofSize: 11, weight: .semibold)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.isHidden = true
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .label
        $0.numberOfLines = 2
        $0.lineBreakMode = .byTruncatingTail
    }

    private let authorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let starRatingView = StarRatingView()

    // 읽기 상태 컨테이너 (아이콘 + 텍스트)
    private let readingStatusContainer = UIView().then {
        $0.backgroundColor = .systemOrange
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.isHidden = false
    }

    private let readingStatusIcon = UIImageView().then {
        $0.image = UIImage(systemName: "book.fill")
        $0.tintColor = .white
        $0.contentMode = .scaleAspectFit
    }

    private let readingStatusLabel = UILabel().then {
        $0.text = "읽는 중"
        $0.font = .systemFont(ofSize: 12, weight: .semibold)
        $0.textColor = .white
    }

    // MARK: - Lifecycle
    override func configureHierarchy() {
        contentView.addSubview(containerView)

        [coverImageView, statusBadge, readingStatusContainer].forEach {
            containerView.addSubview($0)
        }

        // 읽기 상태 컨테이너 내부
        readingStatusContainer.addSubview(readingStatusIcon)
        readingStatusContainer.addSubview(readingStatusLabel)
    }

    override func configureLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(4)
        }

        coverImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(8)
            $0.bottom.equalTo(readingStatusContainer.snp.top).offset(-8)
        }

        statusBadge.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.top).offset(8)
            $0.leading.equalTo(coverImageView.snp.leading).offset(8)
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(40)
        }

        // 읽기 상태 컨테이너 (도서 이미지 하단에 고정)
        readingStatusContainer.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(24)
            $0.bottom.equalToSuperview().offset(-8)
        }

        // 읽기 상태 아이콘
        readingStatusIcon.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(14)
        }

        // 읽기 상태 레이블
        readingStatusLabel.snp.makeConstraints {
            $0.leading.equalTo(readingStatusIcon.snp.trailing).offset(6)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-8)
        }
    }

    override func configureView() {
        backgroundColor = .clear
    }

    // MARK: - Configuration
    func configure(with item: Item) {
        // 책 표지
        if let coverURL = item.highResolutionCover, let url = URL(string: coverURL) {
            coverImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "book.closed"),
                options: [.transition(.fade(0.3)), .cacheOriginalImage]
            )
        } else {
            coverImageView.image = UIImage(systemName: "book.closed")
        }
    }

    private func extractMainAuthor(from rawAuthor: String?) -> String {
        guard let rawAuthor = rawAuthor, !rawAuthor.isEmpty else { return "저자미상" }

        let mainAuthor = rawAuthor
            .components(separatedBy: ",").first?
            .components(separatedBy: "(").first?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return mainAuthor ?? rawAuthor
    }

    // MARK: - Reading Status
    func setReadingStatus(text: String?, color: UIColor?) {
        if let text = text, let color = color {
            readingStatusLabel.text = text
            readingStatusContainer.backgroundColor = color
            readingStatusContainer.isHidden = false
        } else {
            // 작성 전 상태 표시
            readingStatusLabel.text = "작성 전"
            readingStatusContainer.backgroundColor = .systemGray4
            readingStatusContainer.isHidden = false
        }
    }
}
