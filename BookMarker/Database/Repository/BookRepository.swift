//
//  BookRepository.swift
//  BookMarker
//
//  Created by Reimos on 10/1/25.
//

import Foundation
import RealmSwift

/// 도서 데이터 관리를 위한 Repository
final class BookRepository {

    private let realmManager: RealmManager

    init(realmManager: RealmManager = .shared) {
        self.realmManager = realmManager
    }

    // MARK: - Create

    /// 도서 추가
    func addBook(_ book: BookRealmModel) throws {
        let realm = try realmManager.getRealm()
        try realm.write {
            realm.add(book)
        }
    }

    /// 폴더에 도서 추가
    func addBookToFolder(bookId: ObjectId, folderId: ObjectId) throws {
        let realm = try realmManager.getRealm()

        guard let book = realm.object(ofType: BookRealmModel.self, forPrimaryKey: bookId),
              let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "BookRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "도서 또는 폴더를 찾을 수 없습니다."
            ])
        }

        try realm.write {
            folder.books.append(book)
        }
    }

    // MARK: - Read

    /// 모든 도서 조회
    func getAllBooks() throws -> [BookRealmModel] {
        let realm = try realmManager.getRealm()
        let results = realm.objects(BookRealmModel.self)
            .sorted(byKeyPath: "savedDate", ascending: false)
        return Array(results)
    }

    /// 특정 폴더의 도서 조회
    func getBooks(in folderId: ObjectId) throws -> [BookRealmModel] {
        let realm = try realmManager.getRealm()

        guard let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "BookRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "폴더를 찾을 수 없습니다."
            ])
        }

        return Array(folder.books)
    }

    /// ID로 도서 조회
    func getBook(byId id: ObjectId) throws -> BookRealmModel? {
        let realm = try realmManager.getRealm()
        return realm.object(ofType: BookRealmModel.self, forPrimaryKey: id)
    }

    /// ISBN으로 도서 조회
    func getBook(byISBN isbn13: String) throws -> BookRealmModel? {
        let realm = try realmManager.getRealm()
        return realm.objects(BookRealmModel.self)
            .filter("isbn13 == %@", isbn13)
            .first
    }

    // MARK: - Update

    /// 도서 평점 업데이트
    func updateBookRating(id: ObjectId, rating: Double) throws {
        let realm = try realmManager.getRealm()

        guard let book = realm.object(ofType: BookRealmModel.self, forPrimaryKey: id) else {
            throw NSError(domain: "BookRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "도서를 찾을 수 없습니다."
            ])
        }

        // 평점은 0.0 ~ 5.0 범위로 제한
        let clampedRating = min(max(rating, 0.0), 5.0)

        try realm.write {
            book.userRating = clampedRating
        }
    }

    // MARK: - Delete

    /// 도서 삭제
    func deleteBook(id: ObjectId) throws {
        let realm = try realmManager.getRealm()

        guard let book = realm.object(ofType: BookRealmModel.self, forPrimaryKey: id) else {
            throw NSError(domain: "BookRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "도서를 찾을 수 없습니다."
            ])
        }

        try realm.write {
            realm.delete(book)
        }
    }

    /// 폴더에서 도서 제거 (도서는 유지)
    func removeBookFromFolder(bookId: ObjectId, folderId: ObjectId) throws {
        let realm = try realmManager.getRealm()

        guard let book = realm.object(ofType: BookRealmModel.self, forPrimaryKey: bookId),
              let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "BookRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "도서 또는 폴더를 찾을 수 없습니다."
            ])
        }

        try realm.write {
            if let index = folder.books.index(of: book) {
                folder.books.remove(at: index)
            }
        }
    }

    /// 도서 추가 및 폴더에 추가 (하나의 트랜잭션으로 처리)
    func addBookAndAddToFolder(_ book: BookRealmModel, folderId: ObjectId) throws {
        let realm = try realmManager.getRealm()

        guard let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "BookRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "폴더를 찾을 수 없습니다."
            ])
        }

        // 하나의 트랜잭션에서 도서 추가 + 폴더에 추가 처리
        try realm.write {
            // 1. 도서 저장
            realm.add(book)
            // 2. 폴더에 추가
            folder.books.append(book)
        }
    }

    /// 폴더에서 제거하고 도서도 삭제 (하나의 트랜잭션으로 처리)
    func removeBookFromFolderAndDelete(bookId: ObjectId, folderId: ObjectId) throws {
        let realm = try realmManager.getRealm()

        guard let book = realm.object(ofType: BookRealmModel.self, forPrimaryKey: bookId),
              let folder = realm.object(ofType: FolderRealmModel.self, forPrimaryKey: folderId) else {
            throw NSError(domain: "BookRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "도서 또는 폴더를 찾을 수 없습니다."
            ])
        }

        // 하나의 트랜잭션에서 폴더 제거 + 도서 삭제 처리
        try realm.write {
            // 1. 폴더에서 제거
            if let index = folder.books.index(of: book) {
                folder.books.remove(at: index)
            }
            // 2. 도서 삭제
            realm.delete(book)
        }
    }
}
