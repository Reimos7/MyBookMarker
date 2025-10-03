//
//  LibraryViewModel.swift
//  BookMarker
//
//  Created by Reimos on 9/30/25.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift

final class LibraryViewModel: BaseViewModel {

    struct Input {
        let viewWillAppear: Observable<Void>
        let segmentChanged: Observable<Int>
        let addButtonTapped: Observable<Void>
        let folderMenuTapped: Observable<BookCardView.FolderBookData>
        let folderTapped: Observable<BookCardView.FolderBookData>  // 폴더 카드 탭
        let bookTapped: Observable<Item>
    }

    struct Output {
        let folders: Driver<[BookCardView.FolderBookData]>
        let showAddFolderAlert: Driver<Void>
        let selectedSegment: Driver<Int>
        let navigateToBookDetail: Driver<Item>
        let showFolderMenu: Driver<BookCardView.FolderBookData>
        let navigateToFolderDetail: Driver<BookCardView.FolderBookData>  // 폴더 상세 화면 이동
    }

    // MARK: - Dependencies
    private let folderRepository: FolderRepository
    private let bookRepository: BookRepository

    private let disposeBag = DisposeBag()
    private let foldersSubject = BehaviorSubject<[BookCardView.FolderBookData]>(value: [])

    // 현재 선택된 폴더 타입 (0: 도서, 1: 장소)
    private var currentFolderType: FolderType = .book

    // MARK: - Init
    init(
        folderRepository: FolderRepository = FolderRepository(),
        bookRepository: BookRepository = BookRepository()
    ) {
        self.folderRepository = folderRepository
        self.bookRepository = bookRepository
    }

    func transform(_ input: Input) -> Output {
        // 화면 진입 시 Realm에서 데이터 로드
        input.viewWillAppear
            .bind(with: self) { owner, _ in
                owner.loadFoldersFromRealm()
            }
            .disposed(by: disposeBag)

        // 세그먼트 변경 시 타입 변경 및 데이터 로드
        input.segmentChanged
            .bind(with: self) { owner, index in
                let folderType: FolderType = index == 0 ? .book : .place
                owner.currentFolderType = folderType
                owner.loadFoldersFromRealm()
            }
            .disposed(by: disposeBag)

        // 폴더 데이터 스트림
        let folders = foldersSubject.asDriver(onErrorJustReturn: [])

        // 추가 버튼 탭 이벤트
        let showAddFolderAlert = input.addButtonTapped
            .asDriver(onErrorJustReturn: ())

        // 세그먼트 변경
        let selectedSegment = input.segmentChanged
            .asDriver(onErrorJustReturn: 0)

        // 책 탭 이벤트
        let navigateToBookDetail = input.bookTapped
            .asDriver(onErrorJustReturn: Item(title: nil, link: nil, author: nil, pubDate: nil, description: nil, isbn13: nil, itemId: nil, priceSales: nil, priceStandard: nil, cover: nil, categoryId: nil, categoryName: nil, publisher: nil, salesPoint: nil, customerReviewRank: nil, bestDuration: nil, bestRank: nil))

        // 폴더 메뉴 탭 이벤트
        let showFolderMenu = input.folderMenuTapped
            .asDriver(onErrorJustReturn: BookCardView.FolderBookData(title: "", subtitle: ""))

        // 폴더 카드 탭 이벤트 (폴더 상세 화면으로 이동)
        let navigateToFolderDetail = input.folderTapped
            .asDriver(onErrorJustReturn: BookCardView.FolderBookData(title: "", subtitle: ""))

        return Output(
            folders: folders,
            showAddFolderAlert: showAddFolderAlert,
            selectedSegment: selectedSegment,
            navigateToBookDetail: navigateToBookDetail,
            showFolderMenu: showFolderMenu,
            navigateToFolderDetail: navigateToFolderDetail
        )
    }

    // MARK: - Public Methods

    /// Realm에서 폴더 목록 로드 (현재 선택된 타입에 맞춰)
    func loadFoldersFromRealm() {
        do {
            let realmFolders = try folderRepository.getAllFolders(type: currentFolderType)
            let folderData = realmFolders.map { convertToFolderBookData($0) }
            foldersSubject.onNext(folderData)
        } catch {
            print("Error loading folders: \(error)")
            foldersSubject.onNext([])
        }
    }

    /// 새 폴더 추가 (현재 선택된 타입으로)
    func addFolder(name: String) {
        do {
            _ = try folderRepository.createFolder(name: name, type: currentFolderType, isBasic: false)
            loadFoldersFromRealm() // 다시 로드
        } catch {
            print("Error adding folder: \(error)")
        }
    }

    /// 폴더 이름 수정
    func updateFolderName(folderId: String, newName: String) {
        do {
            guard let objectId = try? ObjectId(string: folderId) else {
                print("Invalid folder ID")
                return
            }
            try folderRepository.updateFolder(id: objectId, name: newName)
            loadFoldersFromRealm() // 다시 로드
        } catch {
            print("Error updating folder name: \(error)")
        }
    }

    /// 폴더 삭제
    func deleteFolder(folderId: String) {
        do {
            guard let objectId = try? ObjectId(string: folderId) else {
                print("Invalid folder ID")
                return
            }
            try folderRepository.deleteFolder(id: objectId)
            loadFoldersFromRealm() // 다시 로드
        } catch {
            print("Error deleting folder: \(error)")
        }
    }

    // MARK: - Private Methods

    /// Realm 모델을 UI 모델로 변환
    private func convertToFolderBookData(_ folder: FolderRealmModel) -> BookCardView.FolderBookData {
        // Realm의 Book을 Item으로 변환
        let books = Array(folder.books).map { bookRealm -> Item in
            return Item(
                title: bookRealm.title,
                link: nil,
                author: bookRealm.author,
                pubDate: bookRealm.publishedDate,
                description: bookRealm.bookDescription,
                isbn13: bookRealm.isbn13,
                itemId: nil,
                priceSales: nil,
                priceStandard: nil,
                cover: bookRealm.coverImageURL,
                categoryId: nil,
                categoryName: bookRealm.category,
                publisher: bookRealm.publisher,
                salesPoint: nil,
                customerReviewRank: nil,
                bestDuration: nil,
                bestRank: nil
            )
        }

        // 폴더 색상 결정 (저장된 색상 또는 기본 색상)
        let iconColor: UIColor = {
            if let colorHex = folder.colorHex, let color = UIColor(hexString: colorHex) {
                return color
            }
            return folder.isBasic ? .systemTeal : .systemBlue
        }()

        return BookCardView.FolderBookData(
            id: folder.id.stringValue,  // ObjectId를 String으로 변환
            title: folder.name ?? "제목 없음",
            subtitle: formatDate(folder.createdDate),
            iconColor: iconColor,
            books: books,
            isEditable: !folder.isBasic
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월 d일"
        return "만들어진 날짜 \(formatter.string(from: date))"
    }
}
