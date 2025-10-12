//
//  MapViewModel.swift
//  BookMarker
//
//  Created by Reimos on 10/7/25.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation

final class MapViewModel: BaseViewModel {

    struct Input {
        let viewDidLoad: Observable<Void>
        // 카테고리 필터 선택 (전체, 카페, 도서관, 스터디카페)
        let categorySelected: Observable<KakaoPlaceCategory>
        // 현재 위치 버튼 탭
        let currentLocationTapped: Observable<Void>
        // 장소 셀 선택 (컬렉션뷰)
        let placeSelected: Observable<IndexPath>
        // 핀 선택 (지도에서 마커 클릭)
        let pinSelected: Observable<String>  // 장소 ID
        // 하트 버튼 탭 (장소 저장/삭제)
        let favoriteTapped: Observable<(KakaoPlace, Int)>  // (장소, 인덱스)
        // 폴더 선택 후 저장 확정
        let folderSelected: Observable<(KakaoPlace, FolderRealmModel, Int)>
        // 삭제 확인 후 실제 삭제
        let deleteConfirmed: Observable<(KakaoPlace, Int)>
    }

    struct Output {
        // 장소 목록 (컬렉션뷰에 바인딩)
        let places: Driver<[KakaoPlace]>

        // 현재 위치 (지도 중심 이동용)
        let currentLocation: Driver<CLLocation>

        // 로딩 상태 (인디케이터 표시용)
        let isLoading: Driver<Bool>

        // 에러 메시지 (Alert 표시용)
        let errorMessage: Driver<String>

        // 선택된 카테고리 (필터 버튼 UI 업데이트용)
        let selectedCategory: Driver<KakaoPlaceCategory>

        // 선택된 장소 (상세 화면 이동용)
        let selectedPlace: Driver<KakaoPlace>

        // 토스트 메시지 ("내 장소에 추가되었습니다" 등)
        let showToast: Driver<String>

        // 폴더 선택 Alert 표시
        let showFolderSelection: Driver<(KakaoPlace, Int)>

        // 삭제 확인 Alert 표시
        let showDeleteConfirmation: Driver<(KakaoPlace, Int)>

        // 하트 상태 업데이트 (인덱스, 채워짐 여부)
        let updateFavoriteState: Driver<(Int, Bool)>
    }

    // 의존성 주입
    private let kakaoLocalService: KakaoLocalService
    private let locationManager: LocationManager
    private let placeRepository: PlaceRepository
    private let folderRepository: FolderRepository

    private let disposeBag = DisposeBag()

    // 이니셜라이저 (의존성 주입)
    init(
        kakaoLocalService: KakaoLocalService = .shared,
        locationManager: LocationManager = .shared,
        placeRepository: PlaceRepository = PlaceRepository(),
        folderRepository: FolderRepository = FolderRepository()
    ) {
        self.kakaoLocalService = kakaoLocalService
        self.locationManager = locationManager
        self.placeRepository = placeRepository
        self.folderRepository = folderRepository
    }

    func transform(_ input: Input) -> Output {

        let placesRelay = BehaviorRelay<[KakaoPlace]>(value: [])           // 장소 목록
        let fullPlacesRelay = BehaviorRelay<[KakaoPlace]>(value: [])       // 전체 장소 목록 (필터링 전)
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)            // 로딩 상태
        let errorMessageRelay = PublishRelay<String>()                    // 에러 메시지
        let selectedCategoryRelay = BehaviorRelay<KakaoPlaceCategory>(value: .all)  // 선택된 카테고리
        let currentLocationRelay = PublishRelay<CLLocation>()             // 현재 위치

        // 하트 버튼 관련 Relay
        let toastMessageRelay = PublishRelay<String>()                    // 토스트 메시지
        let showFolderSelectionRelay = PublishRelay<(KakaoPlace, Int)>()  // 폴더 선택 Alert
        let showDeleteConfirmationRelay = PublishRelay<(KakaoPlace, Int)>()  // 삭제 확인 Alert
        let updateFavoriteStateRelay = PublishRelay<(Int, Bool)>()        // 하트 상태 업데이트

        // MARK: - 뷰 로드 시 초기 설정
        input.viewDidLoad
            .take(1)  // 한 번만 실행
            .bind(with: self) { owner, _ in
                // 위치 권한 요청
                self.locationManager.requestAuthorization()
                
                // 위치 업데이트 시작
                self.locationManager.startUpdatingLocation()
            }
            .disposed(by: disposeBag)

        // MARK: - 현재 위치 구독
        locationManager.currentLocation
            .drive(with: self) { owner, location in
                currentLocationRelay.accept(location)
            }
            .disposed(by: disposeBag)
 

        // MARK: - 카테고리 선택 시 처리
        input.categorySelected
            .do(onNext: { category in
                // 10-1. 선택된 카테고리 저장
                selectedCategoryRelay.accept(category)
            })
            .withLatestFrom(currentLocationRelay) { ($0, $1) }  // (카테고리, 현재위치) 튜플
            .flatMapLatest { [weak self] category, location -> Observable<[KakaoPlace]> in
                guard let self = self else { return .empty() }

                // 로딩 시작
                isLoadingRelay.accept(true)

                // 선택된 카테고리로 장소 검색
                return self.searchPlaces(
                    category: category,
                    location: location
                )
                .asObservable()
                .do(
                    onNext: { _ in
                        // 로딩 종료 (성공)
                        isLoadingRelay.accept(false)
                    },
                    onError: { error in
                        // 로딩 종료 (실패)
                        isLoadingRelay.accept(false)
                        errorMessageRelay.accept("장소 검색 실패: \(error.localizedDescription)")
                    }
                )
                .catch { _ in .just([]) }  // 에러 시 빈 배열
            }
            .bind(with: self) { owner, places in
                // 검색 결과를 전체 목록과 현재 목록 모두에 저장
                fullPlacesRelay.accept(places)
                placesRelay.accept(places)
            }
            .disposed(by: disposeBag)

        // MARK: - 현재 위치 버튼 탭 시 처리
        input.currentLocationTapped
            .withLatestFrom(currentLocationRelay)
            .bind(with: self) { owner, location in
                // 현재 위치를 다시 방출 (지도 중심 이동용)
                currentLocationRelay.accept(location)
            }
            .disposed(by: disposeBag)

        // MARK: - 핀 선택 시 처리 (지도 마커 클릭)
        input.pinSelected
            .withLatestFrom(fullPlacesRelay) { placeId, allPlaces in
                // 전체 목록에서 해당 ID의 장소만 필터링
                return allPlaces.filter { $0.id == placeId }
            }
            .bind(with: self) { owner, filteredPlaces in
                // 필터링된 장소(1개)만 컬렉션뷰에 표시
                placesRelay.accept(filteredPlaces)
            }
            .disposed(by: disposeBag)

        // MARK: - 장소 셀 선택 시 처리
        let selectedPlace = input.placeSelected
            .withLatestFrom(placesRelay) { indexPath, places in
                // IndexPath로 장소 추출
                return places[indexPath.row]
            }
            .asDriver(onErrorDriveWith: .empty())

        // MARK: - 하트 버튼 탭 처리 (장소 저장/삭제)
        input.favoriteTapped
            .subscribe(onNext: { [weak self] (place, index) in
                guard let self = self else { return }

                do {
                    // 1. 장소가 이미 저장되어 있는지 확인
                    let existingPlace = try self.placeRepository.getPlace(
                        byName: place.placeName,
                        address: place.addressName
                    )

                    if existingPlace == nil {
                        // 저장되지 않은 장소 → 저장 처리

                        // 2. 사용자가 만든 장소 폴더 개수 확인
                        let allFolders = try self.folderRepository.getAllFolders(type: .place)
                        let userFolders = allFolders.filter { !$0.isBasic }

                        if userFolders.isEmpty {
                            // 사용자 폴더 없음 → 기본 폴더에 자동 저장
                            if let defaultFolder = try self.folderRepository.getBasicFolder(type: .place) {
                                let placeRealmModel = PlaceMapper.toRealmModel(from: place)
                                _ = try self.placeRepository.addPlaceAndAddToFolder(
                                    placeRealmModel,
                                    folderId: defaultFolder.id
                                )
                                print("장소가 기본 폴더에 저장되었습니다: \(placeRealmModel.name)")

                                updateFavoriteStateRelay.accept((index, true))
                                toastMessageRelay.accept("내 장소에 추가되었습니다.")
                            }
                        } else {
                            // 사용자 폴더 있음 → 폴더 선택 Alert 표시
                            showFolderSelectionRelay.accept((place, index))
                        }
                    } else {
                        // 이미 저장된 장소 → 삭제 확인 Alert 표시
                        showDeleteConfirmationRelay.accept((place, index))
                    }
                } catch {
                    print("하트 버튼 처리 실패: \(error)")
                    toastMessageRelay.accept("오류가 발생했습니다.")
                }
            })
            .disposed(by: disposeBag)

        // MARK: - 폴더 선택 후 저장 처리
        input.folderSelected
            .subscribe(onNext: { [weak self] (place, folder, index) in
                guard let self = self else { return }

                do {
                    // 장소가 이미 저장되어 있는지 다시 확인
                    if try self.placeRepository.getPlace(byName: place.placeName, address: place.addressName) == nil {
                        let placeRealmModel = PlaceMapper.toRealmModel(from: place)
                        _ = try self.placeRepository.addPlaceAndAddToFolder(
                            placeRealmModel,
                            folderId: folder.id
                        )
                        print("장소가 \(folder.name ?? "폴더")에 저장되었습니다: \(placeRealmModel.name)")
                        updateFavoriteStateRelay.accept((index, true))
                        toastMessageRelay.accept("\(folder.name ?? "폴더")에 추가되었습니다.")
                    } else {
                        toastMessageRelay.accept("이미 추가된 장소입니다.")
                    }
                } catch {
                    print("폴더에 장소 추가 실패: \(error)")
                    toastMessageRelay.accept("오류가 발생했습니다.")
                }
            })
            .disposed(by: disposeBag)

        // MARK: - 삭제 확인 후 실제 삭제 처리
        input.deleteConfirmed
            .subscribe(onNext: { [weak self] (place, index) in
                guard let self = self else { return }

                do {
                    // 삭제할 장소 찾기
                    guard let existingPlace = try self.placeRepository.getPlace(
                        byName: place.placeName,
                        address: place.addressName
                    ) else {
                        toastMessageRelay.accept("장소를 찾을 수 없습니다.")
                        return
                    }

                    // 해당 장소가 속한 모든 폴더에서 제거
                    let folders = Array(existingPlace.folders)
                    for folder in folders {
                        try self.placeRepository.removePlaceFromFolderAndDelete(
                            placeId: existingPlace.id,
                            folderId: folder.id
                        )
                    }

                    updateFavoriteStateRelay.accept((index, false))
                    toastMessageRelay.accept("내 장소에서 제거되었습니다.")
                } catch {
                    print("장소 삭제 실패: \(error)")
                    toastMessageRelay.accept("오류가 발생했습니다.")
                }
            })
            .disposed(by: disposeBag)

        return Output(
            places: placesRelay.asDriver(),
            currentLocation: currentLocationRelay.asDriver(onErrorDriveWith: .empty()),
            isLoading: isLoadingRelay.asDriver(),
            errorMessage: errorMessageRelay.asDriver(onErrorDriveWith: .empty()),
            selectedCategory: selectedCategoryRelay.asDriver(),
            selectedPlace: selectedPlace,
            showToast: toastMessageRelay.asDriver(onErrorDriveWith: .empty()),
            showFolderSelection: showFolderSelectionRelay.asDriver(onErrorDriveWith: .empty()),
            showDeleteConfirmation: showDeleteConfirmationRelay.asDriver(onErrorDriveWith: .empty()),
            updateFavoriteState: updateFavoriteStateRelay.asDriver(onErrorDriveWith: .empty())
        )
    }

    // 장소 검색
    private func searchPlaces(
        category: KakaoPlaceCategory,
        location: CLLocation
    ) -> Single<[KakaoPlace]> {

        // 카테고리가 "전체"인 경우
        if category == .all {
            // 카페, 도서관, 스터디카페를 모두 검색
            return kakaoLocalService.searchMultipleCategories(
                categories: [.cafe, .library, .studyCafe],
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radius: 1000  // 반경 1km
            )
        } else {
            // 선택된 카테고리만 검색
            return kakaoLocalService.searchPlaces(
                category: category,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                radius: 1000
            )
        }
    }
}
