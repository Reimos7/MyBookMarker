//
//  FolderSelectionCell.swift
//  BookMarker
//
//  Created by Reimos on 10/2/25.
//

import UIKit
import SnapKit
import Then

// 폴더 선택 셀
final class FolderSelectionCell: UICollectionViewCell {

    // 컨테이너 뷰
    private let containerView = UIView().then {
        $0.layer.cornerRadius = 12
        $0.layer.borderWidth = 1.5
        $0.layer.borderColor = UIColor.systemGray5.cgColor
        $0.backgroundColor = .systemBackground
    }

    // 아이콘 컨테이너 뷰
    private let iconContainerView = UIView().then {
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    // 아이콘 이미지뷰
    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .white
    }

    // 폴더 이름 레이블
    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .label
    }

    // 폴더 태그 레이블 (기본 등)
    private let tagLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .systemGray
    }

    // 폴더 설명 레이블
    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .systemGray2
        $0.numberOfLines = 1
    }

    // 도서 개수 레이블
    private let countLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .systemGray
    }

    // 체크 아이콘
    private let checkImageView = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark")
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .systemGreen
        $0.isHidden = true
    }

    // 오른쪽 화살표 아이콘
    private let arrowImageView = UIImageView().then {
        $0.image = UIImage(systemName: "chevron.right")
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .systemGray3
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)

        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        
        [nameLabel,tagLabel,descriptionLabel,countLabel,checkImageView,arrowImageView].forEach {
            containerView.addSubview($0)
        }

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        iconContainerView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(48)
        }

        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(24)
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(14)
            $0.leading.equalTo(iconContainerView.snp.trailing).offset(12)
        }

        tagLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel.snp.trailing).offset(6)
            $0.centerY.equalTo(nameLabel)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(4)
            $0.leading.equalTo(nameLabel)
            $0.trailing.equalTo(countLabel.snp.leading).offset(-8)
        }

        countLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(40)
            $0.centerY.equalToSuperview()
        }

        checkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        arrowImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
    }

    // MARK: - Configuration

    func configure(with folder: FolderRealmModel) {
        // 폴더 이름
        nameLabel.text = folder.name

        // 태그 (기본 폴더인 경우)
        tagLabel.text = folder.isBasic ? "기본" : ""
        tagLabel.isHidden = !folder.isBasic

        // 설명 (기본 폴더: 설명 / 사용자 폴더: 생성 날짜)
        if folder.isBasic {
            descriptionLabel.text = folder.folderDescription ?? "기본으로 생성된 폴더입니다."
        } else {
            // 사용자가 만든 폴더는 생성 날짜 표시
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy.MM.dd 생성"
            descriptionLabel.text = dateFormatter.string(from: folder.createdDate)
        }

        // 도서 개수
        countLabel.text = "\(folder.itemCount)개"

        // 아이콘 및 배경색 설정
        configureIcon(for: folder)

        // 기본 폴더는 파란색 테두리
        if folder.isBasic {
            containerView.layer.borderColor = UIColor.systemTeal.cgColor
            containerView.layer.borderWidth = 2.0
            containerView.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.05)
        } else {
            containerView.layer.borderColor = UIColor.systemGray5.cgColor
            containerView.layer.borderWidth = 1.5
            containerView.backgroundColor = .systemBackground
        }

        // 체크 아이콘은 선택 시에만 표시 (기본적으로 숨김)
        checkImageView.isHidden = true
        arrowImageView.isHidden = false
    }

    private func configureIcon(for folder: FolderRealmModel) {
        // 폴더 색상으로 아이콘 컨테이너 배경 설정
        let backgroundColor: UIColor
        let iconName: String

        if folder.isBasic {
            // 기본 폴더
            backgroundColor = .systemTeal
            iconName = "folder.fill"
        } else {
            // 사용자 생성 폴더
            if let colorHex = folder.colorHex {
                backgroundColor = UIColor(hex: colorHex) ?? .systemGray
            } else {
                backgroundColor = .systemGray
            }

            // 폴더 이름에 따라 아이콘 변경 (예시)
            if folder.name?.contains("읽고 싶은") == true {
                iconName = "heart.fill"
            } else if folder.name?.contains("완독한") == true {
                iconName = "checkmark.circle.fill"
            } else if folder.name?.contains("추천") == true {
                iconName = "star.fill"
            } else {
                iconName = "folder.fill"
            }
        }

        iconContainerView.backgroundColor = backgroundColor
        iconImageView.image = UIImage(systemName: iconName)
    }

    // 선택 상태 표시
    func setSelected(_ selected: Bool) {
        checkImageView.isHidden = !selected
        arrowImageView.isHidden = selected
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
