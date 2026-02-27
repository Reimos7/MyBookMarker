//
//  UIImageView+Extension.swift
//  BookMarker
//
//  Created by Reimos on 2/27/26.
//

import UIKit
import Kingfisher

extension UIImageView {

    // MARK: - Book Cover (API Item 기반)
    func setBookCover(with item: Item) {
        // highResolutionCover: coversum -> cover500 변환
        guard let urlString = item.highResolutionCover,
              let url = URL(string: urlString) else {
            // URL이 없거나 변환 실패 시 placeholder 표시
            image = UIImage(systemName: "book.closed")
            tintColor = .systemGray4
            return
        }

        kf.setImage(
            with: url,
            placeholder: UIImage(systemName: "book.closed"),
            options: [
                // 이미지 로드 시 0.3초 페이드인 애니메이션
                .transition(.fade(0.3)),
                // 원본 이미지를 캐시에 저장 (재다운로드 방지)
                .cacheOriginalImage
            ]
        )
    }

    // MARK: - Book Cover (Realm URL 기반)
    func setBookCover(with urlString: String?) {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            image = UIImage(systemName: "book.closed")
            tintColor = .systemGray4
            return
        }

        kf.setImage(
            with: url,
            placeholder: UIImage(systemName: "book.closed"),
            options: [
                .transition(.fade(0.3)),
                .cacheOriginalImage
            ]
        )
    }
}
