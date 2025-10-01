//
//  BookRealmModel.swift
//  BookMarker
//
//  Created by Reimos on 10/1/25.
//

import Foundation
import RealmSwift

// Realm용 도서 모델
// 사용자가 저장한 도서 정보를 관리
final class BookRealmModel: Object {

    // MARK: - Primary Key
    // 도서 고유 식별자 (Primary Key)
    @Persisted(primaryKey: true) var id: ObjectId

    // MARK: - Book Information
    
    // 도서를 고유하게 식별하는 국제 표준 번호
    @Persisted var isbn13: String?

    // 책 제목 (필수 정보)
    @Persisted var title: String = ""

    // 저자명
    // 여러 저자가 있는 경우 콤마로 구분된 문자열로 저장
    @Persisted var author: String?

    // 출판사명
    @Persisted var publisher: String?

    // 출간일 (문자열 형태로 저장)
    // 알라딘 API에서 "2023-10-15" 형태로 제공
    @Persisted var publishedDate: String?

    // MARK: - Media Information
    // 도서 표지 이미지 URL
    // 알라딘 API에서 제공하는 커버 이미지 링크
    @Persisted var coverImageURL: String?

    // 도서 줄거리/설명
    // 도서의 상세 내용 또는 요약 정보
    @Persisted var bookDescription: String?

    // MARK: - Classification
    // 도서 카테고리 (예: 소설, 에세이, 자기계발 등)
    @Persisted var category: String?

    // MARK: - Rating
    /// 사용자 평점 (0.0 ~ 5.0)
    /// 0이면 미평가 상태
    @Persisted var userRating: Double = 0.0

    // MARK: - Date Information
    // 사용자가 도서를 저장한 날짜
    @Persisted var savedDate: Date = Date()

    // MARK: - Relationships
    // 도서와 연관된 장소 ID (선택적)
    // 도서를 읽은 장소나 추천 장소와의 연결
    @Persisted var placeId: String?

    // 이 도서가 속한 폴더와의 역관계
    // LinkingObjects를 통해 FolderRealmModel의 books 프로퍼티와 연결
    @Persisted(originProperty: "books") var folders: LinkingObjects<FolderRealmModel>


    // MARK: - Convenience Initializer
    /// 도서 생성을 위한 편의 이니셜라이저
    /// - Parameters:
    ///   - isbn13: 표준 도서 번호
    ///   - title: 책 제목
    ///   - author: 저자명
    ///   - publisher: 출판사
    ///   - publishedDate: 출간일
    ///   - coverImageURL: 표지 이미지 URL
    ///   - bookDescription: 도서 설명
    ///   - category: 도서 카테고리
    ///   - userRating: 사용자 평점 (0.0 ~ 5.0)
    ///   - placeId: 연관된 장소 ID
    convenience init(
        isbn13: String? = nil,
        title: String,
        author: String? = nil,
        publisher: String? = nil,
        publishedDate: String? = nil,
        coverImageURL: String? = nil,
        bookDescription: String? = nil,
        category: String? = nil,
        userRating: Double = 0.0,
        placeId: String? = nil
    ) {
        self.init()
        self.isbn13 = isbn13
        self.title = title
        self.author = author
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.coverImageURL = coverImageURL
        self.bookDescription = bookDescription
        self.category = category
        self.userRating = userRating
        self.placeId = placeId
        self.savedDate = Date()
    }
}

// MARK: - Helper Methods
extension BookRealmModel {

    /// 저자명을 정제하여 반환 (괄호, 콤마 제거)
    /// 알라딘 API에서 "홍길동, 김철수 (지은이)" 형태로 오는 데이터를 "홍길동"으로 정제
    var cleanAuthorName: String {
        guard let author = author, !author.isEmpty else {
            return "저자미상"
        }

        return author
            .components(separatedBy: ",").first?
            .components(separatedBy: "(").first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "저자미상"
    }

    /// 도서가 특정 폴더에 포함되어 있는지 확인
    /// - Parameter folderId: 확인할 폴더 ID
    /// - Returns: 포함 여부
    func isContained(in folderId: ObjectId) -> Bool {
        return folders.contains { $0.id == folderId }
    }

    /// 도서의 출간년도 추출
    /// "2023-10-15" 형태에서 "2023" 추출
    var publishedYear: String? {
        guard let publishedDate = publishedDate else { return nil }
        return String(publishedDate.prefix(4))
    }

    /// 도서 정보가 유효한지 확인
    var isValid: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 평점이 있는지 확인
    var hasRating: Bool {
        return userRating > 0
    }

    /// 평점을 별 개수로 반환 (0~5)
    var starRating: Int {
        return Int(round(userRating))
    }
}
