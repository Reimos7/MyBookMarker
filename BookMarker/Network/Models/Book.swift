//
//  Book.swift
//  BookMarker
//
//  Created by Reimos on 9/26/25.
//

import Foundation

struct Book: Decodable {
    let item: [Item]
}

struct Item: Decodable {
    let title: String?
    // 알라딘 웹사이트 내 해당 도서 구매 상세 페이지 URL
    let link: String?
    let author, pubDate, description: String?
    let isbn13: String?
    let itemId, priceSales, priceStandard: Int?
    // 도서 표지 이미지 (API 기본값: coversum - 저해상도 썸네일)
    let cover: String?
    let categoryId: Int?
    let categoryName, publisher: String?
    // 판매 지수
    let salesPoint: Int?
    let customerReviewRank: Int?
    // 베스트 셀러로 머문 기간
    let bestDuration: String?
    let bestRank: Int?

    // MARK: - Computed Property

    // 고해상도 표지 이미지 URL
    var highResolutionCover: String? {
        guard let cover else { return nil }

        // coversum이 포함된 경우에만 교체 
        if cover.contains("coversum") {
            return cover.replacingOccurrences(of: "coversum", with: "cover500")
        }

        // coversum이 없는 경우 원본 URL 반환 (예상치 못한 URL 구조 변경 대비)
        return cover
    }
}

