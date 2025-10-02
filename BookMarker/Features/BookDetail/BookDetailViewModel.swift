//
//  BookDetailViewModel.swift
//  BookMarker
//
//  Created by Reimos on 9/28/25.
//

import Foundation
import RxSwift
import RxCocoa
import Toast

final class BookDetailViewModel: BaseViewModel {

    struct Input {
        let bookItem: Observable<Item>
        let heartButtonTapped: Observable<Void>
        let deleteConfirmed: Observable<Void>  // 삭제 확인 버튼 탭
    }

    struct Output {
        let otherBooks: Driver<[Item]>
        let recommendedBooks: Driver<[Item]>
        let isFavorite: Driver<Bool>
        let showToast: Driver<String>
        let showFolderSelection: Driver<Item>  // 폴더 선택 Alert 표시
        let showDeleteConfirmation: Driver<Item>  // 삭제 확인 Alert 표시
    }

    private let disposeBag = DisposeBag()
    private let folderRepository = FolderRepository()
    private let bookRepository = BookRepository()
    private var favoriteStateRelay: BehaviorRelay<Bool>?  // favoriteState 외부 접근용

    func transform(_ input: Input) -> Output {
        // 저자의 다른 작품 조회
        let otherBooks = input.bookItem
            .flatMapLatest { [weak self] currentBook -> Observable<[Item]> in
                guard let self = self,
                      let rawAuthor = currentBook.author, !rawAuthor.isEmpty else {
                    return .just([])
                }
                
                // 1) 저자명 정제: 첫 번째 저자, 역할/괄호 제거, 공백 트림
                let authorQuery = rawAuthor
                    .components(separatedBy: ",").first?         // 첫 번째 저자만
                    .components(separatedBy: "(").first?         // "(지은이" 등 제거
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                ?? rawAuthor

                print("저자의 다른 작품 검색: \(authorQuery)")

                return NetworkManager.shared
                    .request(.author(author: authorQuery), responseType: Book.self)
                    .asObservable()
                    .compactMap { result -> [Item]? in
                        switch result {
                        case .success(let bookResponse):
                            // 현재 책을 제외한 다른 작품들 필터링
                            let filteredItems = bookResponse.item.filter { item in
                                item.isbn13 != currentBook.isbn13
                            }
                            print("저자의 다른 작품 \(filteredItems.count)개 조회됨")
                            return Array(filteredItems.prefix(5))
                        case .failure(let error):
                            print("저자 다른 작품 조회 실패: \(error.localizedDescription)")
                            return []
                        }
                    }
                    .catchAndReturn([])
            }
            .asDriver(onErrorJustReturn: [])

        // 편집자 추천 도서 조회 (같은 카테고리)
        let recommendedBooks = input.bookItem
            .flatMapLatest { [weak self] currentBook -> Observable<[Item]> in
                guard let self = self,
                      let categoryId = self.extractCategoryId(from: currentBook) else {
                    print("카테고리 ID를 찾을 수 없어서 기본 카테고리 사용")
                    // 기본 카테고리로 컴퓨터 사용
                    return NetworkManager.shared
                        .request(.editorChoice(categoryId: .computer), responseType: Book.self)
                        .asObservable()
                        .map { result in
                            switch result {
                            case .success(let book):
                                print("편집자 추천 도서 \(book.item.count)개 조회됨 (기본)")
                                return Array(book.item.prefix(10))
                            case .failure(let error):
                                print("편집자 추천 도서 조회 실패: \(error.localizedDescription)")
                                return []
                            }
                        }
                        .catchAndReturn([])
                }

                print("편집자 추천 도서 검색 - 카테고리: \(categoryId.displayName)")

                return NetworkManager.shared
                    .request(.editorChoice(categoryId: categoryId), responseType: Book.self)
                    .asObservable()
                    .compactMap { result -> [Item]? in
                        switch result {
                        case .success(let bookResponse):
                            // 현재 책을 제외한 편집자 추천 도서
                            let filteredItems = bookResponse.item.filter { item in
                                item.isbn13 != currentBook.isbn13
                            }
                            print("편집자 추천 도서 \(filteredItems.count)개 조회됨")
                            return Array(filteredItems.prefix(10))
                        case .failure(let error):
                            print("편집자 추천 도서 조회 실패: \(error.localizedDescription)")
                            return []
                        }
                    }
                    .catchAndReturn([])
            }
            .asDriver(onErrorJustReturn: [])


        // 즐겨찾기 상태 관리
        let favoriteState = BehaviorRelay<Bool>(value: false)
        self.favoriteStateRelay = favoriteState  // 외부 접근용 저장
        let toastMessage = PublishSubject<String>()
        let showFolderSelectionSubject = PublishSubject<Item>()
        let showDeleteConfirmationSubject = PublishSubject<Item>()

        // 현재 도서의 즐겨찾기 상태 확인
        input.bookItem
            .take(1)
            .flatMap { [weak self] item -> Observable<Bool> in
                guard let self = self,
                      let isbn13 = item.isbn13 else {
                    return .just(false)
                }

                do {
                    let existingBook = try self.bookRepository.getBook(byISBN: isbn13)
                    return .just(existingBook != nil)
                } catch {
                    print("즐겨찾기 상태 확인 실패: \(error)")
                    return .just(false)
                }
            }
            .subscribe(onNext: { isFavorite in
                favoriteState.accept(isFavorite)
            })
            .disposed(by: disposeBag)

        // 하트 버튼 탭 시 처리
        input.heartButtonTapped
            .withLatestFrom(Observable.combineLatest(input.bookItem, favoriteState.asObservable()))
            .subscribe(onNext: { [weak self] (item, currentFavorite) in
                guard let self = self else { return }

                let newState = !currentFavorite

                do {
                    if newState {
                        // 즐겨찾기 추가 - 폴더 선택 로직
                        let allFolders = try self.folderRepository.getAllFolders(type: .book)
                        let userCreatedFolders = allFolders.filter { !$0.isBasic }

                        if userCreatedFolders.isEmpty {
                            // 사용자 생성 폴더가 없으면 바로 기본 폴더에 추가
                            if let isbn13 = item.isbn13,
                               try self.bookRepository.getBook(byISBN: isbn13) == nil,
                               let defaultFolder = try self.folderRepository.getBasicFolder(type: .book) {

                                let bookRealmModel = BookMapper.toRealmModel(from: item)
                                try self.bookRepository.addBookAndAddToFolder(
                                    bookRealmModel,
                                    folderId: defaultFolder.id
                                )
                                print("도서가 기본 폴더에 저장되었습니다: \(bookRealmModel.title)")

                                favoriteState.accept(true)
                                toastMessage.onNext("내 서재에 추가되었습니다.")
                            }
                        } else {
                            // 사용자 생성 폴더가 있으면 폴더 선택 Alert 표시
                            showFolderSelectionSubject.onNext(item)
                        }
                    } else {
                        // 즐겨찾기 제거 - 삭제 확인 Alert 표시
                        showDeleteConfirmationSubject.onNext(item)
                    }
                } catch {
                    print("즐겨찾기 처리 실패: \(error)")
                    toastMessage.onNext("오류가 발생했습니다.")
                }
            })
            .disposed(by: disposeBag)

        // 삭제 확인 후 실제 삭제 처리
        input.deleteConfirmed
            .withLatestFrom(input.bookItem)
            .bind(with: self) { owner, item in
                do {
                    if let isbn13 = item.isbn13,
                       let existingBook = try self.bookRepository.getBook(byISBN: isbn13),
                       let defaultFolder = try self.folderRepository.getBasicFolder(type: .book) {
                        
                        // 하나의 트랜잭션에서 폴더 제거 + 도서 삭제 처리
                        try self.bookRepository.removeBookFromFolderAndDelete(
                            bookId: existingBook.id,
                            folderId: defaultFolder.id
                        )
                       
                        
                        favoriteState.accept(false)
                        toastMessage.onNext("내 서재에서 제거되었습니다.")
                    }
                } catch {
                    print("도서 삭제 실패: \(error)")
                    toastMessage.onNext("오류가 발생했습니다.")
                }
            }
            .disposed(by: disposeBag)
            
        // 토스트 메시지
        let showToast = toastMessage
            .asDriver(onErrorJustReturn: "")

        // 폴더 선택 Alert 표시
        let showFolderSelection = showFolderSelectionSubject
            .asDriver(onErrorDriveWith: .empty())

        // 삭제 확인 Alert 표시
        let showDeleteConfirmation = showDeleteConfirmationSubject
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            otherBooks: otherBooks,
            recommendedBooks: recommendedBooks,
            isFavorite: favoriteState.asDriver(),
            showToast: showToast,
            showFolderSelection: showFolderSelection,
            showDeleteConfirmation: showDeleteConfirmation
        )
    }

    // MARK: - Public Methods

    /// 선택한 폴더에 도서 추가 (favoriteState도 함께 업데이트)
    func addBookToSelectedFolder(item: Item, folder: FolderRealmModel) -> Observable<(Bool, String)> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext((false, "오류가 발생했습니다."))
                observer.onCompleted()
                return Disposables.create()
            }

            do {
                guard let isbn13 = item.isbn13 else {
                    observer.onNext((false, "도서 정보가 올바르지 않습니다."))
                    observer.onCompleted()
                    return Disposables.create()
                }

                // 이미 존재하는지 확인
                if try self.bookRepository.getBook(byISBN: isbn13) == nil {
                    // Item -> BookRealmModel 변환
                    let bookRealmModel = BookMapper.toRealmModel(from: item)

                    // 하나의 트랜잭션에서 도서 저장 + 폴더에 추가
                    try self.bookRepository.addBookAndAddToFolder(
                        bookRealmModel,
                        folderId: folder.id
                    )
                    print("도서가 \(folder.name ?? "폴더")에 저장되었습니다: \(bookRealmModel.title)")

                    // favoriteState 업데이트 ← 추가!
                    self.favoriteStateRelay?.accept(true)

                    observer.onNext((true, "\(folder.name ?? "폴더")에 추가되었습니다."))
                } else {
                    observer.onNext((false, "이미 추가된 도서입니다."))
                }

                observer.onCompleted()
            } catch {
                print("폴더에 도서 추가 실패: \(error)")
                observer.onNext((false, "오류가 발생했습니다."))
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    // MARK: - Private Methods

    // 카테고리 ID 추출 헬퍼 함수
    private func extractCategoryId(from book: Item) -> BookCategory? {
        // 책의 categoryId 필드가 있다면 직접 매핑
        // 없다면 categoryName으로 추론하거나 기본값 사용
        // 임시로 기본 카테고리들 중 하나를 반환 (추후 개선 가능)
        let categories: [BookCategory] = [.computer, .science, .novel, .selfDevolop, .humanities, .business]
        return categories.randomElement()
    }
}
