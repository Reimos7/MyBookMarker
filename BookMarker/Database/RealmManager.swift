//
//  RealmManager.swift
//  BookMarker
//
//  Created by Reimos on 10/1/25.
//

import Foundation
import RealmSwift

// Realm 데이터베이스 관리 클래스
// 데이터베이스 초기화, 마이그레이션, 인스턴스 제공을 담당
final class RealmManager {

    // MARK: - Singleton
    static let shared = RealmManager()
    private init() {}

    // MARK: - Properties

    // 현재 스키마 버전
    // 모델 구조가 변경될 때마다 증가시켜야 함
    private let schemaVersion: UInt64 = 1

    // Realm 설정
    private lazy var config: Realm.Configuration = {
        var config = Realm.Configuration()
        config.schemaVersion = schemaVersion
        config.migrationBlock = migrationBlock

        // 파일 경로 설정 (선택적)
        if let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            let realmPath = documentsPath + "/BookMarker.realm"
            config.fileURL = URL(fileURLWithPath: realmPath)
        }

        return config
    }()

    // MARK: - Public Methods

    // Realm 인스턴스 반환
    // - Returns: Realm 인스턴스
    // - Throws: Realm 초기화 에러
    func getRealm() throws -> Realm {
        return try Realm(configuration: config)
    }

    // 데이터베이스 초기화
    // 앱 최초 실행 시 기본 폴더들을 생성
    func initializeDatabase() {
        do {
            let realm = try getRealm()

            // 기본 폴더가 없으면 생성
            if realm.objects(FolderRealmModel.self).filter("isBasic == true").isEmpty {
                try createDefaultFolders(in: realm)
            }

            print("Realm 데이터베이스 초기화 완료")
            print("Realm 파일 경로: \(realm.configuration.fileURL?.absoluteString ?? "Unknown")")

        } catch {
            print("Realm 데이터베이스 초기화 실패: \(error)")
        }
    }

    // MARK: - Private Methods

    // 기본 폴더들 생성
    // - Parameter realm: Realm 인스턴스
    private func createDefaultFolders(in realm: Realm) throws {
        try realm.write {
            // 기본 도서 폴더 (Teal 색상)
            let defaultBookFolder = FolderRealmModel(
                name: "기본",
                description: "기본 도서 폴더",
                type: .book,
                isBasic: true,
                colorHex: "#5AC8FA"  // systemTeal
            )
            realm.add(defaultBookFolder)

            // 기본 장소 폴더 (Orange 색상)
            let defaultPlaceFolder = FolderRealmModel(
                name: "기본",
                description: "기본 장소 폴더",
                type: .place,
                isBasic: true,
                colorHex: "#FF9500"  // systemOrange
            )
            realm.add(defaultPlaceFolder)

            print("기본 폴더 생성 완료 (도서: Teal, 장소: Orange)")
        }
    }

    /// 데이터베이스 마이그레이션 블록
    private lazy var migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        print("Realm 마이그레이션 시작: \(oldSchemaVersion) -> \(self.schemaVersion)")

        // 버전별 마이그레이션 로직
        if oldSchemaVersion < 1 {
            // 버전 1로 마이그레이션
            // 새로운 프로퍼티 추가나 기존 데이터 변환 로직
        }

        print("Realm 마이그레이션 완료")
    }

    // 안전한 쓰기 작업 수행
    // - Parameter block: 쓰기 작업 블록
    // - Throws: Realm 에러
    func safeWrite(_ block: (Realm) throws -> Void) throws {
        let realm = try getRealm()

        if realm.isInWriteTransaction {
            try block(realm)
        } else {
            try realm.write {
                try block(realm)
            }
        }
    }
}
