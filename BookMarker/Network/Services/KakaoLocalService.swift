//
//  KakaoLocalService.swift
//  BookMarker
//
//  Created by Reimos on 10/7/25.
//

import Foundation
import RxSwift
import Alamofire

// MARK: - 카카오 로컬 API 서비스
final class KakaoLocalService {

    static let shared = KakaoLocalService()

    private init() {}

    // MARK: - 장소 검색 메서드
    func searchPlaces(
        category: KakaoPlaceCategory,
        latitude: Double,
        longitude: Double,
        radius: Int = 1000
    ) -> Single<[KakaoPlace]> {

        // 스터디카페는 카테고리 코드가 없어서 키워드 검색 사용
        if category.needsKeywordSearch {
            return searchByKeyword(
                query: category.searchKeyword,
                latitude: latitude,
                longitude: longitude,
                radius: radius
            )
        }

        // 카페, 도서관, 전체는 카테고리 검색 사용
        return searchByCategory(
            category: category,
            latitude: latitude,
            longitude: longitude,
            radius: radius
        )
    }

    private func searchByCategory(
        category: KakaoPlaceCategory,
        latitude: Double,
        longitude: Double,
        radius: Int
    ) -> Single<[KakaoPlace]> {

        // KakaoLocalRouter로 요청 생성
        let router = KakaoLocalRouter.searchByCategory(
            category: category,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            page: 1,
            size: 15
        )

        return Single.create { single in
            AF.request(router)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: KakaoPlaceResponse.self) { response in
                    switch response.result {
                    case .success(let placeResponse):
                        single(.success(placeResponse.documents))
                    case .failure(let error):
                        print("카카오 API 에러: \(error.localizedDescription)")
                        if let data = response.data,
                           let errorString = String(data: data, encoding: .utf8) {
                            print("응답 내용: \(errorString)")
                        }
                        single(.failure(error))
                    }
                }

            return Disposables.create()
        }
    }

    private func searchByKeyword(
        query: String,
        latitude: Double,
        longitude: Double,
        radius: Int
    ) -> Single<[KakaoPlace]> {

        let router = KakaoLocalRouter.searchByKeyword(
            query: query,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            page: 1,
            size: 15
        )

        return Single.create { single in
            AF.request(router)
                .validate(statusCode: 200..<300)
                .responseDecodable(of: KakaoPlaceResponse.self) { response in
                    switch response.result {
                    case .success(let placeResponse):
                        single(.success(placeResponse.documents))
                    case .failure(let error):
                        print("카카오 키워드 검색 에러: \(error.localizedDescription)")
                        if let data = response.data,
                           let errorString = String(data: data, encoding: .utf8) {
                            print("응답 내용: \(errorString)")
                        }
                        single(.failure(error))
                    }
                }

            return Disposables.create()
        }
    }

    func searchMultipleCategories(
        categories: [KakaoPlaceCategory],
        latitude: Double,
        longitude: Double,
        radius: Int = 1000
    ) -> Single<[KakaoPlace]> {

        let searches = categories.map { category in
            searchPlaces(
                category: category,
                latitude: latitude,
                longitude: longitude,
                radius: radius
            )
        }

        //  모든 검색을 병렬로 실행하고 결과 합치기
        return Single.zip(searches)
            .map { resultsArray in
                // 2차원 배열을 1차원 배열로 평탄화
                return resultsArray.flatMap { $0 }
            }
    }
}
