//
//  MapPlaceCell.swift
//  BookMarker
//
//  Created by Reimos on 10/5/25.
//

import UIKit
import SnapKit
import Then
import RxSwift

final class MapPlaceCell: BaseCollectionViewCell {

    var disposeBag = DisposeBag()

    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
    }

    private let placeImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.backgroundColor = .systemGray6
        $0.tintColor = .systemGray
    }
    
    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .black
        $0.numberOfLines = 1
    }

    private let infoStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.alignment = .center
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
        $0.font = .systemFont(ofSize: 13)
        $0.textColor = .darkGray
        $0.numberOfLines = 1
    }

    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .gray
        $0.numberOfLines = 1
    }

    // 하트 버튼 (외부에서 접근 가능하도록 internal)
    let favoriteButton = UIButton().then {
        $0.setImage(UIImage(systemName: "heart"), for: .normal)
        $0.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        $0.tintColor = .systemPink
    }

    // 계층 구조 설정
    override func configureHierarchy() {
        contentView.backgroundColor = .clear
        contentView.addSubview(containerView)

        // containerView에 모든 UI 요소 추가
        [placeImageView, nameLabel, infoStackView, addressLabel,
         descriptionLabel, favoriteButton].forEach {
            containerView.addSubview($0)
        }

        // infoStackView에 정보 레이블들 추가
        [categoryIconLabel, categoryLabel, starIconLabel,
         ratingLabel, distanceLabel].forEach {
            infoStackView.addArrangedSubview($0)
        }
    }

    override func configureLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        placeImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(100)
        }

        favoriteButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.trailing.equalToSuperview().inset(12)
            $0.width.height.equalTo(30)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalTo(placeImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(favoriteButton.snp.leading).offset(-8)
        }

        infoStackView.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
            $0.leading.equalTo(nameLabel)
            $0.trailing.lessThanOrEqualToSuperview().inset(12)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(infoStackView.snp.bottom).offset(6)
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalToSuperview().inset(12)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(addressLabel.snp.bottom).offset(4)
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalToSuperview().inset(12)
        }
    }

    func configure(name: String, category: String, rating: Double, distance: String, address: String, description: String) {
        nameLabel.text = name

        switch category {
        case "카페":
            categoryIconLabel.text = "☕️"
            categoryLabel.textColor = .systemOrange
            categoryIconLabel.textColor = .systemOrange
        case "도서관":
            categoryIconLabel.text = "📚"
            categoryLabel.textColor = .systemBlue
            categoryIconLabel.textColor = .systemBlue
        case "스터디카페":
            categoryIconLabel.text = "💼"
            categoryLabel.textColor = .systemPurple
            categoryIconLabel.textColor = .systemPurple
        default:
            categoryIconLabel.text = "📍"
            categoryLabel.textColor = .systemGray
            categoryIconLabel.textColor = .systemGray
        }

        categoryLabel.text = category

        if rating > 0 {
            starIconLabel.isHidden = false
            ratingLabel.isHidden = false
            ratingLabel.text = String(format: "%.1f", rating)
        } else {
            starIconLabel.isHidden = true
            ratingLabel.isHidden = true
        }

        distanceLabel.text = "• \(distance)"

        addressLabel.text = address

        descriptionLabel.text = description

        // 카테고리별 SFSymbol 아이콘 설정
        configurePlaceIcon(category: category)
    }

    private func configurePlaceIcon(category: String) {
        let iconName: String

        // 카테고리 문자열을 소문자로 변환하여 유연하게 매칭
        let lowercasedCategory = category.lowercased()

        // 주의: "스터디카페"가 "카페"를 포함하므로 스터디카페를 먼저 체크해야 함
        if lowercasedCategory.contains("스터디") || lowercasedCategory.contains("study") {
            iconName = "laptopcomputer"
        } else if lowercasedCategory.contains("도서관") || lowercasedCategory.contains("library") {
            iconName = "books.vertical.fill"
        } else if lowercasedCategory.contains("카페") {
            iconName = "cup.and.saucer"
        } else {
            // 기본 아이콘
            iconName = "mappin.circle"
        }

        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
        placeImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        placeImageView.tintColor = .systemGray
    }

    // 하트 버튼 상태 설정
    // - Parameter isFavorite: 즐겨찾기 여부 (true: 채워진 하트, false: 빈 하트)
    func setFavoriteState(_ isFavorite: Bool) {
        favoriteButton.isSelected = isFavorite
    }

    // 셀 재사용 준비 (구독 해제)
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()  // 이전 구독 모두 해제
    }
}
