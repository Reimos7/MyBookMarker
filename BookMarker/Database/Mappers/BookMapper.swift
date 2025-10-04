//
//  BookMapper.swift
//  BookMarker
//
//  Created by Reimos on 10/2/25.
//

import Foundation

/// Item(DTO) ↔ BookRealmModel 변환 매퍼
enum BookMapper {

    /// API Item을 BookRealmModel로 변환
    static func toRealmModel(from item: Item) -> BookRealmModel {
        return BookRealmModel(
            isbn13: item.isbn13,
            title: item.title ?? "제목 없음",
            author: item.author,
            publisher: item.publisher,
            publishedDate: item.pubDate,
            coverImageURL: item.cover,
            bookDescription: item.description,
            category: item.categoryName
        )
    }

    /// BookRealmModel을 Item(DTO)로 변환
    /// - Note: Item은 Decodable이므로 직접 생성할 수 없어 임시 Item 객체를 반환
    static func toItem(from realmModel: BookRealmModel) -> Item {
        // JSON을 통한 우회 변환
        let dict: [String: Any?] = [
            "title": realmModel.title,
            "link": nil,
            "author": realmModel.author,
            "pubDate": realmModel.publishedDate,
            "description": realmModel.bookDescription,
            "isbn13": realmModel.isbn13,
            "itemId": nil,
            "priceSales": nil,
            "priceStandard": nil,
            "cover": realmModel.coverImageURL,
            "categoryId": nil,
            "categoryName": realmModel.category,
            "publisher": realmModel.publisher,
            "salesPoint": nil,
            "customerReviewRank": nil,
            "bestDuration": nil,
            "bestRank": nil
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: dict.compactMapValues { $0 })
        let item = try! JSONDecoder().decode(Item.self, from: jsonData)
        return item
    }
}
