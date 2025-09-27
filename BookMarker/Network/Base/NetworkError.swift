//
//  NetworkError.swift
//  BookMarker
//
//  Created by Reimos on 9/27/25.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError(statusCode: Int)
    case alamofireError(Error)
    case unknownError
    case aladinAPIError(String)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .noData:
            return "데이터를 받을 수 없습니다."
        case .decodingError:
            return "데이터 파싱에 실패했습니다."
        case .networkError(let statusCode):
            return "네트워크 오류 (상태코드: \(statusCode))"
        case .alamofireError(let error):
            return "네트워크 요청 실패: \(error.localizedDescription)"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        case .aladinAPIError(let message):
            return "알라딘 API 오류: \(message)"
        }
    }
}
