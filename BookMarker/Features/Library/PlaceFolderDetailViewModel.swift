//
//  PlaceFolderDetailViewModel.swift
//  BookMarker
//
//  Created by Claude on 1/18/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class PlaceFolderDetailViewModel: BaseViewModel {

    struct Input {
        let refreshTrigger: Observable<Void>
    }

    struct Output {
        let places: Driver<[PlaceRealmModel]>
    }

    private let folderData: BookCardView.FolderBookData
    private let placeRepository = PlaceRepository()

    init(folderData: BookCardView.FolderBookData) {
        self.folderData = folderData
    }

    func transform(_ input: Input) -> Output {
        // 폴더 ID를 ObjectId로 변환
        let folderId = Observable.just(folderData.id)
            .compactMap { try? ObjectId(string: $0) }

        // 새로고침 트리거 시 해당 폴더의 장소 목록 불러오기
        let places = input.refreshTrigger
            .withLatestFrom(folderId)
            .flatMapLatest { [placeRepository] objectId -> Observable<[PlaceRealmModel]> in
                do {
                    let places = try placeRepository.getPlaces(in: objectId)
                    return Observable.just(places)
                } catch {
                    print("장소 로드 실패: \(error)")
                    return Observable.just([])
                }
            }
            .asDriver(onErrorJustReturn: [])

        return Output(places: places)
    }
}
