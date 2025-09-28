//
//  NewBookCell.swift
//  BookMarker
//
//  Created by Reimos on 9/27/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class NewBookCell: BaseCollectionViewCell {

    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    private let coverImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .bold)
        $0.textColor = .black
        $0.numberOfLines = 2
        $0.lineBreakMode = .byTruncatingTail
        $0.textAlignment = .left
    }

    private let authorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .medium)
        $0.textColor = .darkGray
    }

    private let categoryTagLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 11, weight: .medium)
        $0.textColor = .systemBlue
        $0.backgroundColor = .systemBlue.withAlphaComponent(0.15)
        $0.textAlignment = .center
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
    }

    override func configureHierarchy() {
        contentView.addSubview(containerView)

        [coverImageView, titleLabel, authorLabel, categoryTagLabel].forEach {
            containerView.addSubview($0)
        }
    }

    override func configureLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(4)
        }

        coverImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.leading.trailing.equalToSuperview().inset(12)
            $0.height.equalTo(120)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(12)
            $0.height.equalTo(15)
            $0.leading.trailing.equalToSuperview().inset(12)
        }

        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.height.equalTo(15)
            $0.leading.trailing.equalToSuperview().inset(12)
        }

        categoryTagLabel.snp.makeConstraints {
            $0.top.equalTo(authorLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(12)
            $0.height.equalTo(15)
            $0.width.greaterThanOrEqualTo(50)
            $0.bottom.lessThanOrEqualToSuperview().inset(4)
        }
    }

    override func configureView() {
        backgroundColor = .clear
    }

    func configure(with item: Item) {
        titleLabel.text = item.title
        authorLabel.text = item.author
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
        if category.contains("인문") { return "인문" }
        if category.contains("자기계발") { return "자기계발" }
        if category.contains("경영") { return "경영" }
        if category.contains("에세이") { return "에세이" }
        if category.contains("과학") { return "과학" }

        return "기타"
    }
}
