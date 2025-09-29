//
//  BookImageCell.swift
//  BookMarker
//
//  Created by Reimos on 9/28/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class BookImageCell: BaseCollectionViewCell {

    private let bookImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
    }

    override func configureHierarchy() {
        [bookImageView].forEach {
            contentView.addSubview($0)
        }
    }

    override func configureLayout() {
        bookImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(160)
        }

    }

    override func configureView() {
        backgroundColor = .clear
    }

    func configure(with item: Item) {
        // 책 이미지 설정
        if let coverURL = item.cover, let url = URL(string: coverURL) {
            bookImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "book.closed")
            )
        } else {
            bookImageView.image = UIImage(systemName: "book.closed")
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bookImageView.image = nil
    }
}
