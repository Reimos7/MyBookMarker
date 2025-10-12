//
//  PlaceMapper.swift
//  BookMarker
//
//  Created by Claude on 10/11/25.
//

import Foundation

// KakaoPlace(DTO) PlaceRealmModel 변환 매퍼
enum PlaceMapper {
    // Kakao API 장소 데이터를 PlaceRealmModel로 변환
    // Parameter kakaoPlace: KakaoPlace API 응답 모델
    // Returns: Realm 저장용 PlaceRealmModel
    static func toRealmModel(from kakaoPlace: KakaoPlace) -> PlaceRealmModel {
        // 카테고리 변환 (KakaoPlace PlaceCategory)
        let category = mapCategory(from: kakaoPlace.simpleCategory)

        return PlaceRealmModel(
            name: kakaoPlace.placeName,
            address: kakaoPlace.addressName,
            latitude: kakaoPlace.latitude,
            longitude: kakaoPlace.longitude,
            placeDescription: kakaoPlace.roadAddressName,  // 도로명 주소를 설명으로 사용
            imageURL: nil,  // 카카오 API에는 이미지 없음
            category: category,
            userRating: 0.0  // 초기 평점 0
        )
    }

    // 카테고리 문자열을 PlaceCategory enum으로 변환
    // - Parameter categoryString: 카카오 카테고리 문자열 ("카페", "도서관" 등)
    // - Returns: PlaceCategory enum 값
    private static func mapCategory(from categoryString: String) -> PlaceCategory {
        if categoryString.contains("카페") {
            return .cafe
        } else if categoryString.contains("도서관") {
            return .library
        } else if categoryString.contains("스터디") || categoryString.contains("독서실") {
            return .studyCafe
        }
        // 기본값은 카페
        return .cafe
    }
}
