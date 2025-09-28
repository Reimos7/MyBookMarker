//
//  BestSellerCarouselCell.swift
//  BookMarker
//
//  Created by Reimos on 9/27/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class BestSellerCarouselCell: BaseCollectionViewCell {

    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 10
    }

    private let rankLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .systemTeal
        $0.textAlignment = .center
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
    }

    private let coverImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.15
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .black
        $0.numberOfLines = 0
        $0.lineBreakMode = .byTruncatingTail
    }

    private let authorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .darkGray
    }

    private let publisherLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .systemGray
    }

    private let categoryTagLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .medium)
        $0.textColor = .systemGreen
        $0.backgroundColor = .systemGreen.withAlphaComponent(0.15)
        $0.textAlignment = .center
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.text = "소설"
    }

    override func configureHierarchy() {
        contentView.addSubview(containerView)

        [rankLabel, coverImageView, titleLabel, authorLabel, publisherLabel, categoryTagLabel].forEach {
            containerView.addSubview($0)
        }
    }

    override func configureLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
        }

        rankLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(16)
            $0.size.equalTo(32)
        }

        coverImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.top.equalTo(rankLabel.snp.bottom).offset(2)
            $0.bottom.equalToSuperview().offset(-24)
            $0.width.equalTo(120)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(coverImageView.snp.trailing).offset(24)
            $0.trailing.equalToSuperview().offset(-24)
            $0.top.equalTo(coverImageView.snp.top)
        }

        authorLabel.snp.makeConstraints {
            $0.leading.trailing.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
        }

        publisherLabel.snp.makeConstraints {
            $0.leading.trailing.equalTo(titleLabel)
            $0.top.equalTo(authorLabel.snp.bottom).offset(8)
        }

        categoryTagLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.bottom.equalTo(coverImageView.snp.bottom)
            $0.height.equalTo(26)
            $0.width.greaterThanOrEqualTo(60)
        }
    }

    override func configureView() {
        backgroundColor = .clear
    }

    func configure(with item: Item, rank: Int) {
        rankLabel.text = "\(rank)"
        titleLabel.text = item.title
        authorLabel.text = item.author
        publisherLabel.text = item.publisher
        categoryTagLabel.text = getCategoryTag(from: item.categoryName)

        if let coverURL = item.cover, let url = URL(string: coverURL) {
            coverImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "book.closed"),
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage
                ]
            )
        } else {
            coverImageView.image = UIImage(systemName: "book.closed")
        }
    }

    private func getCategoryTag(from categoryName: String?) -> String {
        guard let category = categoryName else { return "도서" }

        if category.contains("소설") { return "소설" }
        if category.contains("인문") { return "인문/철학" }
        if category.contains("자기계발") { return "자기계발" }
        if category.contains("경영") { return "경제/경영" }
        if category.contains("에세이") { return "에세이" }
        if category.contains("과학") { return "과학" }
        if category.contains("역사") { return "역사" }

        return "기타"
    }
}
