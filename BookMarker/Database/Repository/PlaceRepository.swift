//
//  PlaceRepository.swift
//  BookMarker
//
//  Created by Reimos on 10/1/25.
//

import Foundation
import RealmSwift

// 장소 데이터 관리를 위한 Repository
final class PlaceRepository {

    private let realmManager: RealmManager

    init(realmManager: RealmManager = .shared) {
        self.realmManager = realmManager
    }

    // 장소 추가
    func addPlace(_ place: PlaceRealmModel) throws {
        let realm = try realmManager.getRealm()
        try realm.write {
            realm.add(place)
        }
    }

    // 장소 추가 + 폴더에 등록 (한 번에 처리)
    // - Parameters:
    //   - place: 추가할 장소
    //   - folderId: 폴더 ID
    // - Returns: 추가된 장소 모델
    func addPlaceAndAddToFolder(_ place: PlaceRealmModel, folderId: ObjectId) throws -> PlaceRealmModel {
        let realm = try realmManager.getRealm()

        guard let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "PlaceRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "폴더를 찾을 수 없습니다."
            ])
        }

        try realm.write {
            // 1. 장소 추가
            realm.add(place)
            // 2. 폴더에 장소 연결
            folder.places.append(place)
            // 3. 폴더 수정일 갱신
            folder.updateModificationDate()
        }

        return place
    }

    // 폴더에 장소 추가
    func addPlaceToFolder(placeId: ObjectId, folderId: ObjectId) throws {
        let realm = try realmManager.getRealm()

        guard let place = realm.object(ofType: PlaceRealmModel.self, forPrimaryKey: placeId),
              let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "PlaceRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "장소 또는 폴더를 찾을 수 없습니다."
            ])
        }

        try realm.write {
            folder.places.append(place)
        }
    }

    // MARK: - Read

    // 모든 장소 조회
    func getAllPlaces() throws -> [PlaceRealmModel] {
        let realm = try realmManager.getRealm()
        let results = realm.objects(PlaceRealmModel.self)
            .sorted(byKeyPath: "savedDate", ascending: false)
        return Array(results)
    }

    // 특정 폴더의 장소 조회
    func getPlaces(in folderId: ObjectId) throws -> [PlaceRealmModel] {
        let realm = try realmManager.getRealm()

        guard let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "PlaceRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "폴더를 찾을 수 없습니다."
            ])
        }

        return Array(folder.places)
    }

    // ID로 장소 조회
    func getPlace(byId id: ObjectId) throws -> PlaceRealmModel? {
        let realm = try realmManager.getRealm()
        return realm.object(ofType: PlaceRealmModel.self, forPrimaryKey: id)
    }

    // 장소명과 주소로 장소 조회 (중복 확인용)
    // - Parameters:
    //   - name: 장소명
    //   - address: 주소
    // - Returns: 일치하는 장소 (없으면 nil)
    func getPlace(byName name: String, address: String) throws -> PlaceRealmModel? {
        let realm = try realmManager.getRealm()
        return realm.objects(PlaceRealmModel.self)
            .filter("name == %@ AND address == %@", name, address)
            .first
    }

    // 카테고리별 장소 조회
    func getPlaces(byCategory category: PlaceCategory) throws -> [PlaceRealmModel] {
        let realm = try realmManager.getRealm()
        return Array(realm.objects(PlaceRealmModel.self)
            .filter("category == %@", category.rawValue)
            .sorted(byKeyPath: "savedDate", ascending: false))
    }

    // MARK: - Update

    // 장소 평점 업데이트
    func updatePlaceRating(id: ObjectId, rating: Double) throws {
        let realm = try realmManager.getRealm()

        guard let place = realm.object(ofType: PlaceRealmModel.self, forPrimaryKey: id) else {
            throw NSError(domain: "PlaceRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "장소를 찾을 수 없습니다."
            ])
        }

        // 평점은 0.0 ~ 5.0 범위로 제한
        let clampedRating = min(max(rating, 0.0), 5.0)

        try realm.write {
            place.userRating = clampedRating
        }
    }

    // MARK: - Delete

    // 장소 삭제
    func deletePlace(id: ObjectId) throws {
        let realm = try realmManager.getRealm()

        guard let place = realm.object(ofType: PlaceRealmModel.self, forPrimaryKey: id) else {
            throw NSError(domain: "PlaceRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "장소를 찾을 수 없습니다."
            ])
        }

        try realm.write {
            realm.delete(place)
        }
    }

    // 폴더에서 장소 제거 (장소는 유지)
    func removePlaceFromFolder(placeId: ObjectId, folderId: ObjectId) throws {
        let realm = try realmManager.getRealm()

        guard let place = realm.object(ofType: PlaceRealmModel.self, forPrimaryKey: placeId),
              let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "PlaceRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "장소 또는 폴더를 찾을 수 없습니다."
            ])
        }

        try realm.write {
            if let index = folder.places.index(of: place) {
                folder.places.remove(at: index)
            }
        }
    }

    // 폴더에서 장소 제거 + 완전 삭제 (다른 폴더에도 없으면 삭제)
    // - Parameters:
    //   - placeId: 장소 ID
    //   - folderId: 폴더 ID
    func removePlaceFromFolderAndDelete(placeId: ObjectId, folderId: ObjectId) throws {
        let realm = try realmManager.getRealm()

        guard let place = realm.object(ofType: PlaceRealmModel.self, forPrimaryKey: placeId),
              let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "PlaceRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "장소 또는 폴더를 찾을 수 없습니다."
            ])
        }

        try realm.write {
            // 1. 폴더에서 장소 제거
            if let index = folder.places.index(of: place) {
                folder.places.remove(at: index)
            }

            // 2. 다른 폴더에도 속하지 않으면 완전 삭제
            if place.folders.isEmpty {
                realm.delete(place)
            }

            // 3. 폴더 수정일 갱신
            folder.updateModificationDate()
        }
    }

    // MARK: - Update Image

    /// 장소의 이미지 URL 업데이트
    /// - Parameters:
    ///   - placeId: 장소 ID
    ///   - imageURL: 이미지 URL 또는 로컬 파일명
    func updatePlaceImage(placeId: ObjectId, imageURL: String?) throws {
        let realm = try realmManager.getRealm()

        guard let place = realm.object(ofType: PlaceRealmModel.self, forPrimaryKey: placeId) else {
            throw NSError(domain: "PlaceRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "장소를 찾을 수 없습니다."
            ])
        }

        try realm.write {
            place.imageURL = imageURL
        }
    }
}

