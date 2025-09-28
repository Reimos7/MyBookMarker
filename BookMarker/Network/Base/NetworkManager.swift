//
//  NetworkManager.swift
//  BookMarker
//
//  Created by Reimos on 9/26/25.
//

import Foundation
import Alamofire
import RxSwift

protocol NetworkManagerProtocol {
    func request<T: Decodable>(_ router: Router, responseType: T.Type) -> Single<Result<T, NetworkError>>
}

final class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()

    private let session: Session

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60

        self.session = Session(
            configuration: configuration,
            interceptor: NetworkInterceptor()
        )
    }

    func request<T: Decodable>(_ router: Router, responseType: T.Type) -> Single<Result<T, NetworkError>> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.success(.failure(.unknownError)))
                return Disposables.create()
            }

            let request = self.session.request(router.endPoint, method: router.method, parameters: router.parameter)
                .validate(statusCode: 200..<300)
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        do {
                            let decodedData = try JSONDecoder().decode(T.self, from: data)
                            single(.success(.success(decodedData)))
                        } catch {
                            print("Decoding Error: \(error)")
                            if let jsonString = String(data: data, encoding: .utf8) {
                                print("Response JSON: \(jsonString)")
                            }
                            single(.success(.failure(.decodingError)))
                        }
                    case .failure(let error):
                        if let statusCode = response.response?.statusCode {
                            single(.success(.failure(.networkError(statusCode: statusCode))))
                        } else {
                            single(.success(.failure(.alamofireError(error))))
                        }
                    }
                }

            return Disposables.create {
                request.cancel()
            }
        }
    }
}

// MARK: - Network Interceptor
private class NetworkInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var adaptedRequest = urlRequest

        // 공통 헤더 추가
        adaptedRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        adaptedRequest.setValue("BookMarker/1.0", forHTTPHeaderField: "User-Agent")

        completion(.success(adaptedRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard request.retryCount < 2 else {
            completion(.doNotRetry)
            return
        }

        // 네트워크 에러나 타임아웃 시 재시도
        if let urlError = error as? URLError,
           urlError.code == .timedOut || urlError.code == .networkConnectionLost {
            completion(.retryWithDelay(1.0))
        } else {
            completion(.doNotRetry)
        }
    }
}
