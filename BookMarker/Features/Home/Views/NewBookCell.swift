//
//  NewBookCell.swift
//  BookMarker
//
//  Created by Reimos on 9/27/25.
//

import UIKit
import SnapKit
import Then

final class NewBookCell: BaseCollectionViewCell {

    // MARK: - Properties
    var onDeleteButtonTapped: (() -> Void)?

    // MARK: - UI Components
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

    // 삭제 모드 오버레이 (어두운 배경)
    private let deleteOverlayView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 12
        $0.isHidden = true
    }

    // 삭제 버튼 (흰색 배경 + 검은색 쓰레기통)
    private let deleteButton = UIButton().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 25
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4

        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let trashIcon = UIImage(systemName: "trash.fill", withConfiguration: config)
        $0.setImage(trashIcon, for: .normal)
        $0.tintColor = .black

        $0.isHidden = true
    }

    override func configureHierarchy() {
        contentView.addSubview(containerView)

        [coverImageView, categoryTagLabel, deleteOverlayView, deleteButton].forEach {
            containerView.addSubview($0)
        }

        // 삭제 버튼 액션
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    @objc private func deleteButtonTapped() {
        onDeleteButtonTapped?()
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

        // 삭제 오버레이 (컨테이너 전체를 덮음)
        deleteOverlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 삭제 버튼 (중앙에 배치)
        deleteButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(50)
        }
    }

    override func configureView() {
        backgroundColor = .clear
    }

    func configure(with item: Item) {
        categoryTagLabel.text = getLastCategory(from: item.categoryName)

        coverImageView.setBookCover(with: item)
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

    // MARK: - Delete Mode

    // 삭제 모드 활성화
    func showDeleteMode() {
        UIView.animate(withDuration: 0.2) {
            self.deleteOverlayView.isHidden = false
            self.deleteButton.isHidden = false
        }
    }

    // 삭제 모드 비활성화
    func hideDeleteMode() {
        UIView.animate(withDuration: 0.2) {
            self.deleteOverlayView.isHidden = true
            self.deleteButton.isHidden = true
        }
    }

    // 삭제 모드 여부 확인
    var isDeleteModeActive: Bool {
        return !deleteOverlayView.isHidden
    }
}
