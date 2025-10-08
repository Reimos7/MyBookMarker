//
//  KakaoPlace.swift
//  BookMarker
//
//  Created by Reimos on 10/7/25.
//

import Foundation

// MARK: - 카카오 로컬 API 응답 구조체
struct KakaoPlaceResponse: Codable {
    // 검색 결과 메타데이터 (총 개수, 페이징 정보 등)
    let meta: KakaoPlaceMeta
    let documents: [KakaoPlace]
}

// MARK: - 검색 메타 정보
struct KakaoPlaceMeta: Codable {
    let totalCount: Int
    // 노출 가능한 문서 수 (최대 45개까지만 제공)
    let pageableCount: Int
    let isEnd: Bool

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case pageableCount = "pageable_count"
        case isEnd = "is_end"
    }
}

// MARK: - 개별 장소 정보
struct KakaoPlace: Codable {
    let id: String
    let placeName: String
    // 카테고리 전체 경로 (예: "음식점 > 카페 > 커피전문점")
    let categoryName: String
    // 카테고리 그룹 코드 (CE7: 카페, FD6: 음식점 등)
    let categoryGroupCode: String
    // 카테고리 그룹명 (카페, 음식점 등)
    let categoryGroupName: String
    let phone: String
    let addressName: String
    let roadAddressName: String
    let x: String
    let y: String
    // 카카오맵 상세 페이지 URL
    let placeUrl: String
    // 중심 좌표로부터의 거리 (meter 단위, 빈 문자열일 수 있음)
    let distance: String

    enum CodingKeys: String, CodingKey {
        case id
        case placeName = "place_name"
        case categoryName = "category_name"
        case categoryGroupCode = "category_group_code"
        case categoryGroupName = "category_group_name"
        case phone
        case addressName = "address_name"
        case roadAddressName = "road_address_name"
        case x, y
        case placeUrl = "place_url"
        case distance
    }
}

// MARK: - Helper Extensions
extension KakaoPlace {
    // X, Y 좌표를 Double 타입으로 변환 (API는 String으로 제공)
    var latitude: Double? {
        return Double(y)
    }

    var longitude: Double? {
        return Double(x)
    }

    // 거리를 Double로 변환 (미터 단위)
    var distanceInMeters: Double? {
        return Double(distance)
    }

    var formattedDistance: String {
        guard let meters = distanceInMeters else {
            return "-"
        }

        if meters >= 1000 {
            // 1km 이상이면 km 단위로 표시 (소수점 1자리)
            return String(format: "%.1fkm", meters / 1000)
        } else {
            // 1km 미만이면 m 단위로 표시
            return "\(Int(meters))m"
        }
    }

    // 카테고리를 간단한 형태로 변환
    // "음식점 > 카페 > 커피전문점" → "카페"
    var simpleCategory: String {
        // categoryGroupName이 있으면 사용 (카페, 음식점 등)
        if !categoryGroupName.isEmpty {
            return categoryGroupName
        }
        // 없으면 categoryName에서 마지막 항목 추출
        let components = categoryName.components(separatedBy: " > ")
        return components.last ?? categoryName
    }
}
