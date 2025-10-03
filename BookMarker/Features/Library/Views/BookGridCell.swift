//
//  BookGridCell.swift
//  BookMarker
//
//  Created by Claude on 10/3/25.
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
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .systemGray6
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

    private let tagsStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.distribution = .fillProportionally
    }

    // MARK: - Lifecycle
    override func configureHierarchy() {
        contentView.addSubview(containerView)

        [coverImageView, statusBadge, titleLabel, authorLabel, starRatingView, tagsStackView].forEach {
            containerView.addSubview($0)
        }
    }

    override func configureLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(4)
        }

        coverImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(120)
            $0.height.equalTo(160)
        }

        statusBadge.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.top).offset(8)
            $0.leading.equalTo(coverImageView.snp.leading).offset(8)
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(40)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(12)
        }

        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(titleLabel)
        }

        starRatingView.snp.makeConstraints {
            $0.top.equalTo(authorLabel.snp.bottom).offset(6)
            $0.leading.equalTo(titleLabel)
        }

        tagsStackView.snp.makeConstraints {
            $0.top.equalTo(starRatingView.snp.bottom).offset(8)
            $0.leading.trailing.equalTo(titleLabel)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
    }

    override func configureView() {
        backgroundColor = .clear
    }

    // MARK: - Configuration
    func configure(with item: Item) {
        // 책 표지
        if let coverURL = item.cover, let url = URL(string: coverURL) {
            coverImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "book.closed"),
                options: [.transition(.fade(0.3)), .cacheOriginalImage]
            )
        } else {
            coverImageView.image = UIImage(systemName: "book.closed")
        }

        // 제목
        titleLabel.text = item.title

        // 저자 (첫 번째 저자만)
        let authorName = extractMainAuthor(from: item.author)
        authorLabel.text = authorName

        // 별점
        if let reviewRank = item.customerReviewRank {
            starRatingView.rating = Double(reviewRank)
            starRatingView.isHidden = false
        } else {
            starRatingView.isHidden = true
        }

        // 태그들 (카테고리, 출판사 등)
        setupTags(item: item)
    }

    private func setupTags(item: Item) {
        // 기존 태그 제거
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        var tags: [String] = []

        // 카테고리
        if let category = item.categoryName?.components(separatedBy: ">").last?.trimmingCharacters(in: .whitespaces) {
            tags.append(category)
        }

        // 출판사
        if let publisher = item.publisher {
            tags.append(publisher)
        }

        // 최대 2개까지만 표시
        for tag in tags.prefix(2) {
            let tagLabel = createTagLabel(text: tag)
            tagsStackView.addArrangedSubview(tagLabel)
        }
    }

    private func createTagLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .secondaryLabel
        label.backgroundColor = .systemGray6
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.snp.makeConstraints {
            $0.height.equalTo(20)
        }
        return label
    }

    private func extractMainAuthor(from rawAuthor: String?) -> String {
        guard let rawAuthor = rawAuthor, !rawAuthor.isEmpty else { return "저자미상" }

        let mainAuthor = rawAuthor
            .components(separatedBy: ",").first?
            .components(separatedBy: "(").first?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return mainAuthor ?? rawAuthor
    }

    // MARK: - Status Badge
    func setStatusBadge(text: String?, color: UIColor?) {
        if let text = text, let color = color {
            statusBadge.text = text
            statusBadge.backgroundColor = color
            statusBadge.isHidden = false
        } else {
            statusBadge.isHidden = true
        }
    }
}
