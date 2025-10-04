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

        [coverImageView, categoryTagLabel].forEach {
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
            $0.height.equalTo(160)
        }

        categoryTagLabel.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(60)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    override func configureView() {
        backgroundColor = .clear
    }

    func configure(with item: Item) {
        categoryTagLabel.text = getLastCategory(from: item.categoryName)

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

    private func getLastCategory(from categoryName: String?) -> String {
        guard let category = categoryName else { return "도서" }

        // 마지막 카테고리만 추출
        let lastCategory = category
            .components(separatedBy: ">")
            .last?
            .trimmingCharacters(in: .whitespaces)

        return lastCategory ?? "도서"
    }
}
