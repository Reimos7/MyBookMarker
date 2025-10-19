//
//  PlaceGridCell.swift
//  BookMarker
//
//  Created by Claude on 1/18/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class PlaceGridCell: UICollectionViewCell {

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
    }

    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .label
        $0.numberOfLines = 2
    }

    private let addressLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 2
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureLayout()
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        nameLabel.text = nil
        addressLabel.text = nil
    }

    func configure(with place: PlaceRealmModel) {
        nameLabel.text = place.name ?? "장소 이름 없음"
        addressLabel.text = place.address ?? "주소 정보 없음"

        // 이미지 로드
        if let imageURLString = place.imageURL, let imageURL = URL(string: imageURLString) {
            imageView.kf.setImage(
                with: imageURL,
                placeholder: UIImage(systemName: "photo"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        } else {
            imageView.image = UIImage(systemName: "photo")
            imageView.tintColor = .systemGray3
        }
    }
}

extension PlaceGridCell: DesignProtocol {
    func configureHierarchy() {
        [imageView, nameLabel, addressLabel].forEach {
            contentView.addSubview($0)
        }
    }

    func configureLayout() {
        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(160)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(4)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(4)
        }
    }

    func configureView() {
        contentView.backgroundColor = .systemBackground
    }
}
