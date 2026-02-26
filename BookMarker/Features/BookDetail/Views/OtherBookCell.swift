//
//  OtherBookCell.swift
//  BookMarker
//
//  Created by Reimos on 9/28/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class OtherBookCell: BaseCollectionViewCell {

    private let bookImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 4
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .black
        $0.numberOfLines = 2
    }

    private let authorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .gray
    }

    private let ratingView = UIView()

    private let ratingLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .orange
    }

    private let starImageView = UIImageView().then {
        $0.image = UIImage(systemName: "star.fill")
        $0.tintColor = .orange
        $0.contentMode = .scaleAspectFit
    }

    private let chevronImageView = UIImageView().then {
        $0.image = UIImage(systemName: "chevron.right")
        $0.tintColor = .systemGray3
        $0.contentMode = .scaleAspectFit
    }

    override func configureHierarchy() {
        [bookImageView, titleLabel, authorLabel, ratingView, chevronImageView].forEach {
            contentView.addSubview($0)
        }

        [starImageView, ratingLabel].forEach {
            ratingView.addSubview($0)
        }
    }

    override func configureLayout() {
        bookImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(80)
            $0.height.equalTo(110)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(bookImageView.snp.top)
            $0.leading.equalTo(bookImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
        }

        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.trailing.equalTo(titleLabel.snp.trailing)
        }

        ratingView.snp.makeConstraints {
            $0.top.equalTo(authorLabel.snp.bottom).offset(8)
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.height.equalTo(16)
        }

        starImageView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(12)
        }

        ratingLabel.snp.makeConstraints {
            $0.leading.equalTo(starImageView.snp.trailing).offset(4)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
    }

    override func configureView() {
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
    }

    func configure(with item: Item) {
        titleLabel.text = item.title

        // 저자명 정제: 맨 앞 저자만 표시
        let displayAuthor = extractMainAuthor(from: item.author)
        authorLabel.text = displayAuthor

        // 책 이미지 설정
        if let coverURL = item.highResolutionCover, let url = URL(string: coverURL) {
            bookImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "book.closed"),
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage
                ]
            )
        } else {
            bookImageView.image = UIImage(systemName: "book.closed")
        }

        let rating = Double(item.customerReviewRank ?? 0)
        ratingLabel.text = String(format: "%.1f", rating)
    }

    private func extractMainAuthor(from rawAuthor: String?) -> String {
        guard let rawAuthor = rawAuthor, !rawAuthor.isEmpty else { return "저자미상" }

        // 첫 번째 저자만 추출하고 역할 정보 제거
        let mainAuthor = rawAuthor
            .components(separatedBy: ",").first?         // 첫 번째 저자만
            .components(separatedBy: "(").first?         // "(지은이" 등 제거
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return mainAuthor ?? rawAuthor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bookImageView.image = nil
        titleLabel.text = nil
        authorLabel.text = nil
        ratingLabel.text = nil
    }
}
