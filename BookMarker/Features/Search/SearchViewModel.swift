//
//  SearchViewModel.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import Foundation
import RxSwift
import RxCocoa

final class SearchViewModel: BaseViewModel {

    private let disposeBag = DisposeBag()
    private let networkManager = NetworkManager.shared
    private let folderRepository = FolderRepository()
    private let bookRepository = BookRepository()

    struct Input {
        let searchText: Observable<String>
        let searchTrigger: Observable<Void>
        let favoriteButtonTapped: Observable<(Item, Int)>  // (도서, 인덱스)
        let deleteConfirmed: Observable<(Item, Int)>  // 삭제 확인 (도서, 인덱스)
    }

    struct Output {
        let books: Driver<[Item]>
        let isLoading: Driver<Bool>
        let error: Driver<String>
        let resultCount: Driver<String>
        let showToast: Driver<String>
        let showFolderSelection: Driver<(Item, Int)>  // 폴더 선택 Alert (도서, 인덱스)
        let showDeleteConfirmation: Driver<(Item, Int)>  // 삭제 확인 Alert (도서, 인덱스)
        let updateFavoriteState: Driver<(Int, Bool)>  // (인덱스, 좋아요 상태)
    }

    func transform(_ input: Input) -> Output {
        let errorTracker = PublishSubject<String>()
        let loadingTracker = PublishSubject<Bool>()
        let toastMessage = PublishSubject<String>()
        let showFolderSelectionSubject = PublishSubject<(Item, Int)>()
        let showDeleteConfirmationSubject = PublishSubject<(Item, Int)>()
        let updateFavoriteStateSubject = PublishSubject<(Int, Bool)>()

        let searchResult = input.searchTrigger
            .withLatestFrom(input.searchText)
            .filter { !$0.isEmpty }
            .do(onNext: { _ in loadingTracker.onNext(true) })
            .flatMapLatest { [weak self] query -> Observable<Book> in
                guard let self = self else { return .empty() }

                return self.networkManager
                    .request(.keyword(keyword: query), responseType: Book.self)
                    .asObservable()
                    .do(onNext: { _ in loadingTracker.onNext(false) })
                    .compactMap { result -> Book? in
                        switch result {
                        case .success(let book):
                            return book
                        case .failure(let error):
                            errorTracker.onNext(error.localizedDescription)
                            return nil
                        }
                    }
            }
            .share()

        let books = searchResult
            .map { $0.item }
            .asDriver(onErrorJustReturn: [])

        let resultCount = books
            .map { items in
                "검색 결과 (\(items.count)건)"
            }

        // 좋아요 버튼 탭 처리
        input.favoriteButtonTapped
            .subscribe(onNext: { [weak self] (item, index) in
                guard let self = self else { return }

                do {
                    guard let isbn13 = item.isbn13 else { return }

                    // 현재 저장 상태 확인
                    let existingBook = try self.bookRepository.getBook(byISBN: isbn13)
                    let isFavorite = existingBook != nil

                    if !isFavorite {
                        // 추가 로직
                        let allFolders = try self.folderRepository.getAllFolders(type: .book)
                        let userCreatedFolders = allFolders.filter { !$0.isBasic }

                        if userCreatedFolders.isEmpty {
                            // 기본 폴더에 바로 추가
                            if let defaultFolder = try self.folderRepository.getBasicFolder(type: .book) {
                                let bookRealmModel = BookMapper.toRealmModel(from: item)
                                try self.bookRepository.addBookAndAddToFolder(
                                    bookRealmModel,
                                    folderId: defaultFolder.id
                                )
                                print("도서가 기본 폴더에 저장되었습니다: \(bookRealmModel.title)")

                                updateFavoriteStateSubject.onNext((index, true))
                                toastMessage.onNext("내 서재에 추가되었습니다.")
                            }
                        } else {
                            // 폴더 선택 Alert 표시
                            showFolderSelectionSubject.onNext((item, index))
                        }
                    } else {
                        // 삭제 확인 Alert 표시
                        showDeleteConfirmationSubject.onNext((item, index))
                    }
                } catch {
                    print("좋아요 처리 실패: \(error)")
                    toastMessage.onNext("오류가 발생했습니다.")
                }
            })
            .disposed(by: disposeBag)

        // 삭제 확인 후 실제 삭제 처리
        input.deleteConfirmed
            .subscribe(onNext: { [weak self] (item, index) in
                guard let self = self else { return }

                do {
                    if let isbn13 = item.isbn13,
                       let existingBook = try self.bookRepository.getBook(byISBN: isbn13),
                       let defaultFolder = try self.folderRepository.getBasicFolder(type: .book) {

                        try self.bookRepository.removeBookFromFolderAndDelete(
                            bookId: existingBook.id,
                            folderId: defaultFolder.id
                        )

                        updateFavoriteStateSubject.onNext((index, false))
                        toastMessage.onNext("내 서재에서 제거되었습니다.")
                    }
                } catch {
                    print("도서 삭제 실패: \(error)")
                    toastMessage.onNext("오류가 발생했습니다.")
                }
            })
            .disposed(by: disposeBag)

        return Output(
            books: books,
            isLoading: loadingTracker.asDriver(onErrorJustReturn: false),
            error: errorTracker.asDriver(onErrorJustReturn: ""),
            resultCount: resultCount,
            showToast: toastMessage.asDriver(onErrorJustReturn: ""),
            showFolderSelection: showFolderSelectionSubject.asDriver(onErrorDriveWith: .empty()),
            showDeleteConfirmation: showDeleteConfirmationSubject.asDriver(onErrorDriveWith: .empty()),
            updateFavoriteState: updateFavoriteStateSubject.asDriver(onErrorDriveWith: .empty())
        )
    }

    // MARK: - Public Methods

    /// 선택한 폴더에 도서 추가
    func addBookToSelectedFolder(item: Item, folder: FolderRealmModel, index: Int) -> Observable<(Int, Bool, String)> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext((index, false, "오류가 발생했습니다."))
                observer.onCompleted()
                return Disposables.create()
            }

            do {
                guard let isbn13 = item.isbn13 else {
                    observer.onNext((index, false, "도서 정보가 올바르지 않습니다."))
                    observer.onCompleted()
                    return Disposables.create()
                }

                if try self.bookRepository.getBook(byISBN: isbn13) == nil {
                    let bookRealmModel = BookMapper.toRealmModel(from: item)
                    try self.bookRepository.addBookAndAddToFolder(
                        bookRealmModel,
                        folderId: folder.id
                    )
                    print("도서가 \(folder.name ?? "폴더")에 저장되었습니다: \(bookRealmModel.title)")

                    observer.onNext((index, true, "\(folder.name ?? "폴더")에 추가되었습니다."))
                } else {
                    observer.onNext((index, false, "이미 추가된 도서입니다."))
                }

                observer.onCompleted()
            } catch {
                print("폴더에 도서 추가 실패: \(error)")
                observer.onNext((index, false, "오류가 발생했습니다."))
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
