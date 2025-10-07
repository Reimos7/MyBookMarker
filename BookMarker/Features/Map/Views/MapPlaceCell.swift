//
//  PlaceCell.swift
//  BookMarker
//
//  Created by Reimos on 10/5/25.
//

import UIKit
import SnapKit
import Then

final class MapPlaceCell: BaseCollectionViewCell {

    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
    }

    private let placeImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.backgroundColor = .systemGray5
    }

    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .black
    }

    private let categoryIconLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .systemOrange
    }

    private let categoryLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .systemOrange
    }

    private let starIconLabel = UILabel().then {
        $0.text = "★"
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .systemYellow
    }

    private let ratingLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .black
    }

    private let distanceLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .darkGray
    }

    private let addressLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .darkGray
    }

    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13)
        $0.textColor = .gray
        $0.numberOfLines = 0
    }

    private let favoriteButton = UIButton().then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.tintColor = .systemPink
    }

    // MARK: - BaseCollectionViewCell Methods

    override func configureHierarchy() {
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)
        
        [placeImageView,nameLabel,categoryIconLabel,categoryLabel,starIconLabel,ratingLabel,distanceLabel,addressLabel,descriptionLabel,favoriteButton].forEach {
            containerView.addSubview($0)
        }
    }

    override func configureLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20))
        }

        placeImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.top.equalToSuperview().offset(12)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
            $0.width.height.equalTo(100)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(placeImageView)
            $0.leading.equalTo(placeImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
        }

        categoryIconLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.leading.equalTo(nameLabel)
        }

        categoryLabel.snp.makeConstraints {
            $0.centerY.equalTo(categoryIconLabel)
            $0.leading.equalTo(categoryIconLabel.snp.trailing).offset(4)
        }

        starIconLabel.snp.makeConstraints {
            $0.centerY.equalTo(categoryLabel)
            $0.leading.equalTo(categoryLabel.snp.trailing).offset(12)
        }

        ratingLabel.snp.makeConstraints {
            $0.centerY.equalTo(starIconLabel)
            $0.leading.equalTo(starIconLabel.snp.trailing).offset(4)
        }

        distanceLabel.snp.makeConstraints {
            $0.centerY.equalTo(ratingLabel)
            $0.leading.equalTo(ratingLabel.snp.trailing).offset(8)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(categoryLabel.snp.bottom).offset(6)
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalToSuperview().inset(12)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(addressLabel.snp.bottom).offset(6)
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalToSuperview().inset(12)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }

        favoriteButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().inset(12)
            $0.width.height.equalTo(30)
        }
    }

    // MARK: - Configure

    func configure(name: String, category: String, rating: Double, distance: String, address: String, description: String) {
        nameLabel.text = name

        // 카테고리 아이콘 설정
        switch category {
        case "카페":
            categoryIconLabel.text = "☕️"
        case "도서관":
            categoryIconLabel.text = "📚"
        case "스터디카페":
            categoryIconLabel.text = "💼"
        default:
            categoryIconLabel.text = "📍"
        }

        categoryLabel.text = category
        ratingLabel.text = "\(rating)"
        distanceLabel.text = "• \(distance)"
        addressLabel.text = address
        descriptionLabel.text = description
    }
}
