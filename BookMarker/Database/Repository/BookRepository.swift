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

    /// 도서의 장소 ID 업데이트
    func updateBookPlaceId(id: ObjectId, placeId: String?) throws {
        let realm = try realmManager.getRealm()

        guard let book = realm.object(ofType: BookRealmModel.self, forPrimaryKey: id) else {
            throw NSError(domain: "BookRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "도서를 찾을 수 없습니다."
            ])
        }

        try realm.write {
            book.placeId = placeId
        }
    }

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

    /// 독서 일기 업데이트
    /// - Parameters:
    ///   - id: 도서 ID
    ///   - isReadingComplete: 읽기 완료 여부
    ///   - startDate: 독서 시작일
    ///   - endDate: 독서 완료일
    ///   - rating: 평점 (0.0 ~ 5.0)
    ///   - diaryContent: 독서 일기 내용
    ///   - quotes: 인상 깊은 구절 목록
    ///   - tags: 태그 목록
    func updateBookDiary(
        id: ObjectId,
        isReadingComplete: Bool,
        startDate: Date?,
        endDate: Date?,
        rating: Double,
        diaryContent: String?,
        quotes: [String],
        tags: [String]
    ) throws {
        let realm = try realmManager.getRealm()

        guard let book = realm.object(ofType: BookRealmModel.self, forPrimaryKey: id) else {
            throw NSError(domain: "BookRepository", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "도서를 찾을 수 없습니다."
            ])
        }

        // 평점은 0.0 ~ 5.0 범위로 제한
        let clampedRating = min(max(rating, 0.0), 5.0)

        try realm.write {
            book.isReadingComplete = isReadingComplete
            book.startDate = startDate
            book.endDate = endDate
            book.userRating = clampedRating
            book.diaryContent = diaryContent

            // 기존 구절/태그 제거 후 새로운 데이터 추가
            book.quotes.removeAll()
            book.quotes.append(objectsIn: quotes)

            book.tags.removeAll()
            book.tags.append(objectsIn: tags)
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

    // MARK: - Debug Helpers

    /// 디버깅: 도서의 독서 일기 정보를 출력
    func printBookDiaryInfo(id: ObjectId) {
        do {
            let realm = try realmManager.getRealm()
            guard let book = realm.object(ofType: BookRealmModel.self, forPrimaryKey: id) else {
                print("[DEBUG] 도서를 찾을 수 없습니다.")
                return
            }

            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("[도서 정보]")
            print("제목: \(book.title)")
            print("저자: \(book.author ?? "미상")")
            print("ISBN: \(book.isbn13 ?? "없음")")
            print("")
            print("[독서 일기 정보]")
            print("읽기 완료: \(book.isReadingComplete ? "완료" : "읽는 중")")
            print("시작일: \(book.startDate?.description ?? "없음")")
            print("완료일: \(book.endDate?.description ?? "없음")")
            print("평점: \(book.userRating)점")
            print("독서 일기: \(book.diaryContent ?? "없음")")
            print("인상 깊은 구절 (\(book.quotes.count)개): \(Array(book.quotes))")
            print("태그 (\(book.tags.count)개): \(Array(book.tags))")
            print("저장일: \(book.savedDate)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        } catch {
            print("[DEBUG ERROR] \(error.localizedDescription)")
        }
    }

    /// 디버깅: 모든 도서의 독서 일기 정보를 출력
    func printAllBooksWithDiary() {
        do {
            let books = try getAllBooks()
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("[전체 도서 목록] 총 \(books.count)권")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            for (index, book) in books.enumerated() {
                print("\n[\(index + 1)] \(book.title)")
                print("   저자: \(book.author ?? "미상")")
                print("   읽기 완료: \(book.isReadingComplete ? "✓" : "✗")")
                print("   평점: \(book.userRating)점")
                print("   일기: \(book.hasDiary ? "작성됨" : "없음")")
                print("   구절: \(book.quotes.count)개, 태그: \(book.tags.count)개")
            }
            print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        } catch {
            print("[DEBUG ERROR] \(error.localizedDescription)")
        }
    }
}
