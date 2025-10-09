//
//  LocationManager.swift
//  BookMarker
//
//  Created by Reimos on 10/7/25.
//

import Foundation
import CoreLocation
import RxSwift
import RxCocoa
import UIKit

// MARK: - 위치 권한 상태
// 위치 권한의 현재 상태를 나타내는 enum
enum LocationAuthorizationStatus {
    case notDetermined      // 아직 권한 요청 안 함
    case denied            // 사용자가 권한 거부
    case authorized        // 권한 허용됨
}


// 현재 위치를 가져오고 관리하는 싱글톤 클래스
final class LocationManager: NSObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()

    // 현재 위치를 방출하는 PublishSubject
    // ViewController에서 구독하여 위치 변경 감지
    private let currentLocationSubject = PublishSubject<CLLocation>()

    // 권한 상태를 방출하는 BehaviorSubject
    // 초기값은 notDetermined
    private let authorizationStatusSubject = BehaviorSubject<LocationAuthorizationStatus>(value: .notDetermined)

    private let disposeBag = DisposeBag()

    // 외부에서 구독할 수 있는 현재 위치 Observable (Driver)
    var currentLocation: Driver<CLLocation> {
        return currentLocationSubject.asDriver(onErrorDriveWith: .empty())
    }

    // 외부에서 구독할 수 있는 권한 상태 Observable (Driver)
    var authorizationStatus: Driver<LocationAuthorizationStatus> {
        return authorizationStatusSubject.asDriver(onErrorJustReturn: .denied)
    }

    private override init() {
        super.init()
        setupLocationManager()
    }

    // MARK: - Setup
    // LocationManager 초기 설정
    private func setupLocationManager() {
        locationManager.delegate = self

        // 정확도 설정 (최고 정확도)
        // - kCLLocationAccuracyBest: 가장 정확한 위치 (GPS 사용)
        // - 배터리 소모가 많으므로 필요에 따라 조정 가능
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        // 거리 필터 설정 (100m)
        // - 100m 이상 이동했을 때만 위치 업데이트
        // - 배터리 절약을 위해 설정
        locationManager.distanceFilter = 100

        // 초기 권한 상태는 delegate 콜백에서 자동 확인됨
        // iOS 경고 방지: checkAuthorizationStatus() 제거
        // locationManagerDidChangeAuthorization()이 자동으로 호출됨
    }

    // MARK: - Authorization
    // 위치 권한 요청
    func requestAuthorization() {
        // 위치 사용 권한 요청
        // 권한 팝업 표시  사용자 선택 delegate 콜백 호출
        locationManager.requestWhenInUseAuthorization()
    }

    // 권한 상태를 LocationAuthorizationStatus로 변환하여 방출
    private func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            // 아직 권한 요청 안 함
            authorizationStatusSubject.onNext(.notDetermined)

        case .denied, .restricted:
            // 권한 거부 또는 제한됨
            authorizationStatusSubject.onNext(.denied)

        case .authorizedWhenInUse, .authorizedAlways:
            // 권한 허용됨
            authorizationStatusSubject.onNext(.authorized)
            // 위치 업데이트 시작
            startUpdatingLocation()

        @unknown default:
            // 미래에 추가될 수 있는 케이스 대비
            authorizationStatusSubject.onNext(.denied)
        }
    }

    // MARK: - Location Updates
    // 위치 업데이트 시작
    func startUpdatingLocation() {
        // iOS 14+ 경고 방지: locationServicesEnabled() 체크 제거
        // delegate 콜백에서만 이 메서드를 호출하므로 이미 권한이 있다고 가정
        // 위치 서비스가 비활성화된 경우 didFailWithError에서 처리됨
        locationManager.startUpdatingLocation()
        print("위치 업데이트 시작")
    }

    // 위치 업데이트 중지
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        print("위치 업데이트 중지")
    }

    // 한 번만 현재 위치 가져오기
    // 현재 위치를 방출하는 Single
    func getCurrentLocation() -> Single<CLLocation> {
        return Single.create { [weak self] single in
            guard let self = self else {
                single(.failure(NSError(domain: "LocationManager", code: -1, userInfo: nil)))
                return Disposables.create()
            }

            // 18-1. Driver를 Observable로 변환 후 첫 번째 값만 받기
            // Driver는 .take() 메서드가 없으므로 asObservable() 필요
            let disposable = self.currentLocation
                .asObservable()
                .take(1)
                .subscribe(onNext: { location in
                    single(.success(location))
                })

            // 위치 업데이트 시작
            self.startUpdatingLocation()

            return disposable
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {

    // 권한 상태가 변경되었을 때 호출 (iOS 14+)
    // iOS 14+에서는 델리게이트 콜백이 호출되었다는 것 자체가 권한 변경을 의미
    // 파라미터로 전달된 manager의 authorizationStatus를 바로 사용하면 경고 발생
    // 대신 현재 시스템 권한 상태를 직접 확인하지 않고 updateAuthorizationStatus 호출
    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // iOS 14+에서는 delegate 호출 시점에 이미 권한 상태가 변경됨
        // manager.authorizationStatus는 이 시점에서 안전하게 접근 가능
        let status = manager.authorizationStatus
        updateAuthorizationStatus(status)
    }

    // 권한 상태가 변경되었을 때 호출 (iOS 14 미만)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // 변경된 권한 상태 확인 및 업데이트
        updateAuthorizationStatus(status)
    }

    // 위치가 업데이트되었을 때 호출
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 가장 최신 위치 가져오기
        guard let location = locations.last else { return }

        // 위치 정확도 확인
        // - horizontalAccuracy가 0보다 작으면 유효하지 않은 위치
        guard location.horizontalAccuracy >= 0 else {
            print("유효하지 않은 위치: accuracy = \(location.horizontalAccuracy)")
            return
        }

        // 너무 오래된 위치 필터링 (5초 이내)
        let age = abs(location.timestamp.timeIntervalSinceNow)
        guard age < 5.0 else {
            print("오래된 위치 데이터: \(age)초 전")
            return
        }

        // 유효한 위치를 Subject로 방출
        print("위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocationSubject.onNext(location)
    }

    /// 위치 가져오기 실패 시 호출
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 에러 로깅
        print("위치 가져오기 실패: \(error.localizedDescription)")

        // 특정 에러 처리
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                // 권한 거부
                print("위치 권한이 거부되었습니다.")
                authorizationStatusSubject.onNext(.denied)

            case .locationUnknown:
                // 위치를 찾을 수 없음 (일시적, 재시도 가능)
                print("위치를 찾을 수 없습니다. 재시도 중...")

            default:
                print("기타 위치 에러: \(clError.code.rawValue)")
            }
        }

        // Subject로 에러 전달
        currentLocationSubject.onError(error)
    }
}

// MARK: - Helper Extensions
extension LocationManager {

    // 위치 서비스 사용 가능 여부 확인
    var isLocationServicesEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }

    // 앱 설정 화면으로 이동
    // 위치 권한이 거부되었을 때 사용자를 설정 화면으로 안내
    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
