//
//  CategoryCell.swift
//  BookMarker
//
//  Created by Reimos on 9/27/25.
//

import UIKit
import SnapKit
import Then

final class CategoryCell: BaseCollectionViewCell {

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .systemGray
        $0.textAlignment = .center
    }

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    override func configureHierarchy() {
        contentView.addSubview(titleLabel)
    }

    override func configureLayout() {
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }

    override func configureView() {
        backgroundColor = .clear
        layer.cornerRadius = 20
        updateAppearance()
    }

    func configure(with category: String) {
        titleLabel.text = category
    }

    private func updateAppearance() {
        if isSelected {
            backgroundColor = .systemTeal
            titleLabel.textColor = .white
            titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        } else {
            backgroundColor = .systemGray6
            titleLabel.textColor = .systemGray
            titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        }
    }
}
