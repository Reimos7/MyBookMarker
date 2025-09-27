//
//  SearchBar.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import UIKit
import SnapKit
import Then

final class SearchBar: UIView {

    let textField = UITextField().then {
        $0.placeholder = "검색어를 입력해주세요"
        $0.font = .systemFont(ofSize: 16)
        $0.textColor = .black
        $0.backgroundColor = .clear
        $0.borderStyle = .none
        $0.clearButtonMode = .whileEditing
    }

    private let searchIconImageView = UIImageView().then {
        $0.image = UIImage(systemName: "magnifyingglass")
        $0.tintColor = .systemGray3
        $0.contentMode = .scaleAspectFit
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 20

        [searchIconImageView, textField].forEach {
            addSubview($0)
        }

        searchIconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(20)
        }

        textField.snp.makeConstraints {
            $0.leading.equalTo(searchIconImageView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-12)
            $0.verticalEdges.equalToSuperview().inset(8)
        }
    }
}
