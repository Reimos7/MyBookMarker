//
//  BookMapper.swift
//  BookMarker
//
//  Created by Reimos on 10/2/25.
//

import Foundation

/// Item(DTO) BookRealmModel 변환 매퍼
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
}
