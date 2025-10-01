//
//  PlaceRealmModel.swift
//  BookMarker
//
//  Created by Reimos on 10/1/25.
//

import Foundation
import RealmSwift

/// 장소의 카테고리를 정의하는 열거형
/// 사용자가 저장하는 장소의 유형을 분류
enum PlaceCategory: String, CaseIterable, PersistableEnum {
    case cafe = "cafe"                 // 카페
    case studyCafe = "studyCafe"       // 스터디카페
    case library = "library"           // 도서관
   
    /// 카테고리의 한글 표시명
    var displayName: String {
        switch self {
        case .cafe:
            return "카페"
        case .studyCafe:
            return "스터디 카페"
        case .library:
            return "도서관"
        }
    }

    /// 카테고리별 아이콘 이름 (SF Symbol)
    var iconName: String {
        switch self {
        case .library:
            return "building.columns"
        case .studyCafe:
            return "books.vertical"
        case .cafe:
            return "cup.and.saucer"
        }
    }
}

/// Realm용 장소 모델
/// 사용자가 저장한 장소 정보를 관리 (독서 장소, 추천 장소 등)
final class PlaceRealmModel: Object {

    // MARK: - Primary Key
    /// 장소 고유 식별자 (Primary Key)
    @Persisted(primaryKey: true) var id: ObjectId

    // MARK: - Basic Information
    /// 장소명 (사용자가 지정한 장소 이름, 필수)
    @Persisted var name: String = ""

    /// 장소 주소
    /// 지도 API에서 가져오거나 사용자가 직접 입력
    @Persisted var address: String?

    /// 장소 설명
    /// 사용자가 작성한 장소에 대한 메모나 설명
    @Persisted var placeDescription: String?

    // MARK: - Location Information
    /// 위도 (Latitude)
    /// 지도상의 정확한 위치 표시를 위한 좌표
    @Persisted var latitude: Double?

    /// 경도 (Longitude)
    /// 지도상의 정확한 위치 표시를 위한 좌표
    @Persisted var longitude: Double?

    // MARK: - Media Information
    /// 장소 이미지 URL
    /// 사용자가 촬영한 사진이나 웹에서 가져온 이미지
    @Persisted var imageURL: String?

    // MARK: - Classification
    /// 장소 카테고리
    @Persisted var category: PlaceCategory = .cafe

    // MARK: - Rating
    /// 사용자 평점 (0.0 ~ 5.0)
    /// 0이면 미평가 상태
    @Persisted var userRating: Double = 0.0

    // MARK: - Date Information
    /// 장소가 저장된 날짜
    @Persisted var savedDate: Date = Date()

    // MARK: - Relationships
    /// 이 장소가 속한 폴더와의 역관계
    /// LinkingObjects를 통해 FolderRealmModel의 places 프로퍼티와 연결
    @Persisted(originProperty: "places") var folders: LinkingObjects<FolderRealmModel>


    // MARK: - Convenience Initializer
    /// 장소 생성을 위한 편의 이니셜라이저
    /// - Parameters:
    ///   - name: 장소명
    ///   - address: 주소
    ///   - latitude: 위도
    ///   - longitude: 경도
    ///   - description: 장소 설명
    ///   - imageURL: 장소 이미지 URL
    ///   - category: 장소 카테고리
    ///   - userRating: 사용자 평점 (0.0 ~ 5.0)
    convenience init(
        name: String,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        placeDescription: String? = nil,
        imageURL: String? = nil,
        category: PlaceCategory = .cafe,
        userRating: Double = 0.0
    ) {
        self.init()
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.placeDescription = placeDescription
        self.imageURL = imageURL
        self.category = category
        self.userRating = userRating
        self.savedDate = Date()
    }
}

// MARK: - Helper Methods
extension PlaceRealmModel {

    /// 장소에 좌표 정보가 있는지 확인
    var hasCoordinates: Bool {
        return latitude != nil && longitude != nil
    }

    /// 좌표 정보를 CLLocationCoordinate2D로 반환
    /// CoreLocation 프레임워크와 연동하여 지도 표시에 사용
    var coordinates: (latitude: Double, longitude: Double)? {
        guard let lat = latitude, let lon = longitude else {
            return nil
        }
        return (latitude: lat, longitude: lon)
    }

    /// 장소가 특정 폴더에 포함되어 있는지 확인
    /// - Parameter folderId: 확인할 폴더 ID
    /// - Returns: 포함 여부
    func isContained(in folderId: ObjectId) -> Bool {
        return folders.contains { $0.id == folderId }
    }

    /// 장소 정보가 유효한지 확인
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 주소의 간략 형태 반환 (시/구 정보만)
    /// "서울특별시 강남구 테헤란로 123" → "강남구"
    var shortAddress: String? {
        guard let address = address else { return nil }

        let components = address.components(separatedBy: " ")
        // 구 단위 찾기
        if let district = components.first(where: { $0.hasSuffix("구") }) {
            return district
        }
        // 시 단위 찾기
        if let city = components.first(where: { $0.hasSuffix("시") }) {
            return city
        }

        return components.first
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
