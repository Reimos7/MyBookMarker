//
//  FolderRepository.swift
//  BookMarker
//
//  Created by Reimos on 10/1/25.
//

import Foundation
import RealmSwift

/// 폴더 데이터 관리를 위한 Repository
final class FolderRepository {

    private let realmManager: RealmManager

    init(realmManager: RealmManager = .shared) {
        self.realmManager = realmManager
    }

    // MARK: - Create

    /// 새 폴더 생성
    func createFolder(name: String, description: String? = nil, type: FolderType, isBasic: Bool = false) throws -> FolderRealmModel {
        let realm = try realmManager.getRealm()

        let folder = FolderRealmModel(
            name: name,
            description: description,
            type: type,
            isBasic: isBasic
        )

        try realm.write {
            realm.add(folder)
        }

        return folder
    }

    // MARK: - Read

    /// 모든 폴더 조회
    func getAllFolders(type: FolderType? = nil) throws -> [FolderRealmModel] {
        let realm = try realmManager.getRealm()
        var results = realm.objects(FolderRealmModel.self)

        // 타입 필터링
        if let type = type {
            results = results.filter("type == %@", type.rawValue)
        }

        // 정렬: 기본 폴더 우선, 그 다음 생성일 순
        results = results.sorted(by: [
            SortDescriptor(keyPath: "isBasic", ascending: false),
            SortDescriptor(keyPath: "createdDate", ascending: true)
        ])

        return Array(results)
    }

    /// ID로 폴더 조회
    func getFolder(by id: ObjectId) throws -> FolderRealmModel? {
        let realm = try realmManager.getRealm()
        return realm.object(ofType: FolderRealmModel.self, forPrimaryKey: id)
    }

    /// 기본 폴더 조회
    func getBasicFolder(type: FolderType) throws -> FolderRealmModel? {
        let realm = try realmManager.getRealm()
        return realm.objects(FolderRealmModel.self)
            .filter("type == %@ AND isBasic == true", type.rawValue)
            .first
    }

    // MARK: - Update

    /// 폴더 이름/설명 업데이트
    func updateFolder(id: ObjectId, name: String? = nil, description: String? = nil) throws {
        let realm = try realmManager.getRealm()

        guard let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: id) else {
            throw NSError(domain: "FolderRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "폴더를 찾을 수 없습니다."
            ])
        }

        // 기본 폴더는 이름 변경 불가
        if folder.isBasic && name != nil {
            throw NSError(domain: "FolderRepository", code: 1001, userInfo: [
                NSLocalizedDescriptionKey: "기본 폴더의 이름은 변경할 수 없습니다."
            ])
        }

        try realm.write {
            if let name = name {
                folder.name = name
            }
            if let description = description {
                folder.folderDescription = description
            }
            folder.updateModificationDate()
        }
    }

    // MARK: - Delete

    /// 폴더 삭제
    func deleteFolder(id: ObjectId) throws {
        let realm = try realmManager.getRealm()

        guard let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: id) else {
            throw NSError(domain: "FolderRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "폴더를 찾을 수 없습니다."
            ])
        }

        // 기본 폴더는 삭제 불가
        if folder.isBasic {
            throw NSError(domain: "FolderRepository", code: 1002, userInfo: [
                NSLocalizedDescriptionKey: "기본 폴더는 삭제할 수 없습니다."
            ])
        }

        try realm.write {
            // 폴더 내 아이템들도 함께 삭제
            realm.delete(folder.books)
            realm.delete(folder.places)
            realm.delete(folder)
        }
    }
}
