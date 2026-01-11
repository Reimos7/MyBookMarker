//
//  PlaceCoverCell.swift
//  BookMarker
//
//  Created by Reimos on 10/12/25.
//

import UIKit
import SnapKit
import Then

/// 장소 폴더에 표시될 장소 아이템 셀 (SF Symbol 아이콘 + 장소명)
final class PlaceCoverCell: BaseCollectionViewCell {

    // 컨테이너 뷰 (배경 + 그림자)
    private let containerView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemGray5.cgColor
    }

    // 아이콘 컨테이너 뷰 (색상 배경)
    private let iconContainerView = UIView().then {
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    // 장소 아이콘 (SF Symbol)
    private let placeIconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .white
    }

    // 장소명 레이블
    private let placeNameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .label
        $0.numberOfLines = 2
        $0.textAlignment = .center
        $0.lineBreakMode = .byTruncatingTail
    }

    override func configureHierarchy() {
        contentView.addSubview(containerView)
        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(placeIconImageView)
        containerView.addSubview(placeNameLabel)
    }

    override func configureLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(4)
        }

        iconContainerView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(48)
        }

        placeIconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(28)
        }

        placeNameLabel.snp.makeConstraints {
            $0.top.equalTo(iconContainerView.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(8)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }

    override func configureView() {
        backgroundColor = .clear
    }

    // 장소 데이터로 셀 구성
    // - Parameter place: PlaceRealmModel 장소 데이터
    func configure(with place: PlaceRealmModel) {
        placeNameLabel.text = place.name

        // 카테고리에 따라 아이콘과 배경색 설정
        let iconConfig = getIconConfig(for: place.category)
        placeIconImageView.image = UIImage(systemName: iconConfig.iconName)
        iconContainerView.backgroundColor = iconConfig.backgroundColor
    }

    // 카테고리별 아이콘 설정 가져오기
    private func getIconConfig(for category: PlaceCategory) -> (iconName: String, backgroundColor: UIColor) {
        switch category {
        case .cafe:
            return ("cup.and.saucer.fill", .systemOrange)
        case .library:
            return ("book.fill", .systemBlue)
        case .studyCafe:
            return ("desktopcomputer", .systemPurple)
        }
    }
}
