//
//  PlaceRepository.swift
//  BookMarker
//
//  Created by Reimos on 10/1/25.
//

import Foundation
import RealmSwift

/// 장소 데이터 관리를 위한 Repository
final class PlaceRepository {

    private let realmManager: RealmManager

    init(realmManager: RealmManager = .shared) {
        self.realmManager = realmManager
    }

    // MARK: - Create

    /// 장소 추가
    func addPlace(_ place: PlaceRealmModel) throws {
        let realm = try realmManager.getRealm()
        try realm.write {
            realm.add(place)
        }
    }

    /// 폴더에 장소 추가
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

    /// 모든 장소 조회
    func getAllPlaces() throws -> [PlaceRealmModel] {
        let realm = try realmManager.getRealm()
        let results = realm.objects(PlaceRealmModel.self)
            .sorted(byKeyPath: "savedDate", ascending: false)
        return Array(results)
    }

    /// 특정 폴더의 장소 조회
    func getPlaces(in folderId: ObjectId) throws -> [PlaceRealmModel] {
        let realm = try realmManager.getRealm()

        guard let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "PlaceRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "폴더를 찾을 수 없습니다."
            ])
        }

        return Array(folder.places)
    }

    /// ID로 장소 조회
    func getPlace(byId id: ObjectId) throws -> PlaceRealmModel? {
        let realm = try realmManager.getRealm()
        return realm.object(ofType: PlaceRealmModel.self, forPrimaryKey: id)
    }

    /// 카테고리별 장소 조회
    func getPlaces(byCategory category: PlaceCategory) throws -> [PlaceRealmModel] {
        let realm = try realmManager.getRealm()
        return Array(realm.objects(PlaceRealmModel.self)
            .filter("category == %@", category.rawValue)
            .sorted(byKeyPath: "savedDate", ascending: false))
    }

    // MARK: - Update

    /// 장소 평점 업데이트
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

    /// 장소 삭제
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

    /// 폴더에서 장소 제거 (장소는 유지)
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
}
