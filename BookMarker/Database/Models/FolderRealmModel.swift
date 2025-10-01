//
//  FolderRealmModel.swift
//  BookMarker
//
//  Created by Reimos on 10/1/25.
//

import Foundation
import RealmSwift

// 폴더의 타입을 정의하는 열거형
// - book: 도서 폴더 (도서 목록을 저장)
// - place: 장소 폴더 (장소 목록을 저장)
enum FolderType: String, CaseIterable, PersistableEnum {
    case book = "book"
    case place = "place"

    /// 폴더 타입의 한글 표시명
    var displayName: String {
        switch self {
        case .book:
            return "도서"
        case .place:
            return "장소"
        }
    }
}

/// Realm용 폴더 모델
/// 사용자가 생성한 폴더 정보를 저장하며, 도서 또는 장소를 분류하여 관리
final class FolderRealmModel: Object {

    // MARK: - Primary Key
    /// 폴더 고유 식별자 (Primary Key)
    @Persisted(primaryKey: true) var id: ObjectId

    // MARK: - Basic Information
    /// 폴더명 (사용자가 지정한 폴더 이름)
    @Persisted var name: String?

    /// 폴더 설명 (폴더에 대한 상세 설명)
    @Persisted var folderDescription: String?

    /// 폴더 타입 (도서/장소 구분)
    @Persisted var type: FolderType = .book

    // MARK: - Date Information
    /// 폴더 생성일
    @Persisted var createdDate: Date = Date()

    /// 폴더 수정일 (폴더 정보나 내용이 변경될 때마다 업데이트)
    @Persisted var updateDate: Date = Date()

    // MARK: - Folder Properties
    /// 기본 폴더 여부 (기본 폴더는 삭제 불가)
    /// true: 시스템 기본 폴더 (삭제 불가)
    /// false: 사용자 생성 폴더 (삭제 가능)
    @Persisted var isBasic: Bool = false

    /// 폴더 색상 (Hex String 형태로 저장)
    /// 예: "#FF5733", "#3498DB"
    @Persisted var colorHex: String?

    // MARK: - Relationships
    /// 폴더에 포함된 도서 목록 (도서 폴더인 경우에만 사용)
    @Persisted var books: List<BookRealmModel> = List<BookRealmModel>()

    /// 폴더에 포함된 장소 목록 (장소 폴더인 경우에만 사용)
    @Persisted var places: List<PlaceRealmModel> = List<PlaceRealmModel>()


    // MARK: - Convenience Initializer
    /// 폴더 생성을 위한 편의 이니셜라이저
    /// - Parameters:
    ///   - name: 폴더명
    ///   - description: 폴더 설명
    ///   - type: 폴더 타입 (도서/장소)
    ///   - isBasic: 기본 폴더 여부
    ///   - colorHex: 폴더 색상 (Hex String)
    convenience init(name: String?, description: String? = nil, type: FolderType, isBasic: Bool = false, colorHex: String? = nil) {
        self.init()
        self.name = name
        self.folderDescription = description
        self.type = type
        self.isBasic = isBasic
        self.colorHex = colorHex
        self.createdDate = Date()
        self.updateDate = Date()
    }
}

// MARK: - Helper Methods
extension FolderRealmModel {

    /// 폴더 정보 업데이트 시 수정일 갱신
    func updateModificationDate() {
        self.updateDate = Date()
    }

    /// 도서 폴더인지 확인
    var isBookFolder: Bool {
        return type == .book
    }

    /// 장소 폴더인지 확인
    var isPlaceFolder: Bool {
        return type == .place
    }

    /// 폴더 내 아이템 개수 반환
    var itemCount: Int {
        switch type {
        case .book:
            return books.count
        case .place:
            return places.count
        }
    }
}
