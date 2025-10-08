//
//  KakaoLocalRouter.swift
//  BookMarker
//
//  Created by Reimos on 10/7/25.
//

import Foundation
import Alamofire

// MARK: - 카카오 로컬 API 카테고리 코드
enum KakaoPlaceCategory: String {
    case cafe = "CE7"           // 카페 카테고리 코드
    case library = "LIBRARY"    // 도서관 (키워드 검색용, CT1은 문화시설 전체라서 미술관/영화관 포함됨)
    case studyCafe = "STUDY"    // 스터디카페 (키워드 검색용)
    case all = ""               // 전체 카테고리 (빈 문자열)
    
    var displayName: String {
        switch self {
        case .cafe:
            return "카페"
        case .library:
            return "도서관"
        case .studyCafe:
            return "스터디카페"
        case .all:
            return "전체"
        }
    }
    
    //도서관과 스터디카페는 카테고리 코드가 없어서 키워드 검색을 사용해야 함
    var needsKeywordSearch: Bool {
        return self == .studyCafe || self == .library
    }
    
    // 키워드 검색에 사용할 검색어
    var searchKeyword: String {
        switch self {
        case .library:
            return "도서관"
        case .studyCafe:
            return "스터디카페"
        default:
            return ""
        }
    }
}

// MARK: - 카카오 로컬 API Router
enum KakaoLocalRouter {

    case searchByCategory(
        category: KakaoPlaceCategory,
        latitude: Double,
        longitude: Double,
        radius: Int = 1000,
        page: Int = 1,
        size: Int = 15 // 한 페이지에 보여질 문서 수 (1~15, 기본 15)
    )
    
    // 키워드로 장소 검색 (스터디카페 등 카테고리 코드가 없는 경우)
    case searchByKeyword(
        query: String,
        latitude: Double,
        longitude: Double,
        radius: Int = 1000,
        page: Int = 1,
        size: Int = 15
    )
}

// MARK: - Router 프로토콜 구현
extension KakaoLocalRouter {
    
    // 카카오 API의 Base URL
    var baseURL: String {
        return "https://dapi.kakao.com"
    }
    
    // API 엔드포인트 경로
    var path: String {
        switch self {
        case .searchByCategory:
            // 카테고리로 검색하는 API
            return "/v2/local/search/category.json"
        case .searchByKeyword:
            // 키워드로 검색하는 API
            return "/v2/local/search/keyword.json"
        }
    }
    
    // URL 생성
    var endPoint: URL {
      
        var components = URLComponents(string: baseURL + path)!
        
        var queryItems: [URLQueryItem] = []
        
        if let params = parameter {
            for (key, value) in params {
               
                queryItems.append(URLQueryItem(name: key, value: "\(value)"))
            }
        }
        
        components.queryItems = queryItems
        
        return components.url!
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    // 요청 파라미터
    var parameter: [String: Any]? {
        switch self {
        case .searchByCategory(let category, let latitude, let longitude, let radius, let page, let size):
            // 카테고리 검색 파라미터
            var params: [String: Any] = [
                "x": longitude,
                "y": latitude,
                "radius": radius,
                "page": page,
                "size": size
            ]
            
            // 카테고리 코드 추가 (전체가 아닌 경우에만)
            if category != .all {
                params["category_group_code"] = category.rawValue
            }
            
            return params
            
        case .searchByKeyword(let query, let latitude, let longitude, let radius, let page, let size):
            // 키워드 검색 파라미터
            return [
                "query": query,
                "x": longitude,
                "y": latitude,
                "radius": radius,
                "page": page,
                "size": size
            ]
        }
    }
    
    // HTTP 헤더 (카카오 REST API Key 인증)
    var headers: HTTPHeaders {
        return [
            // "KakaoAK {REST_API_KEY}" 형식
            "Authorization": "KakaoAK \(API.kakaoRestAPIKey)"
        ]
    }
}

// MARK: - URLRequestConvertible 구현
// Alamofire의 URLRequestConvertible 프로토콜 구현
// 이를 통해 Router를 바로 Alamofire 요청에 사용할 수 있음
extension KakaoLocalRouter: URLRequestConvertible {
    func asURLRequest() throws -> URLRequest {
        // 기본 URLRequest 생성
        var request = URLRequest(url: endPoint)
        
        // HTTP 메서드 설정
        request.method = method
        
        // 헤더 설정
        request.headers = headers
        
        // 타임아웃 설정 (10초)
        request.timeoutInterval = 10
        
        // 완성된 URLRequest 반환
        return request
    }
}
