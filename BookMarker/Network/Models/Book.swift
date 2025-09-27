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
    // 도서 표지 이미지
    let cover: String?
    let categoryId: Int?
    let categoryName, publisher: String?
    // 판매 지수
    let salesPoint: Int?
    let customerReviewRank: Int?
    // 베스트 셀러로 머문 기간
    let bestDuration: String?
    let bestRank: Int?
}

