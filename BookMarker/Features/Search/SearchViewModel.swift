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

    private let networkManager = NetworkManager.shared
    private let folderRepository = FolderRepository()
    private let bookRepository = BookRepository()

    struct Input {
        let searchText: Observable<String>
        let searchTrigger: Observable<Void>
        let favoriteButtonTapped: Observable<Item>  // 좋아요 버튼을 누른 도서
        let deleteConfirmed: Observable<Item>  // 삭제 확인 Alert에서 확인을 누른 도서
    }

    struct Output {
        // 상태: 화면이 지금 어떤 모습이어야 하는지 → Driver (마지막 값을 기억)
        let books: Driver<[Item]>
        let isLoading: Driver<Bool>
        let resultCount: Driver<String>

        // 이벤트: 한 번 일어나고 끝나는 일 → Signal (지난 값을 기억하지 않음)
        let error: Signal<String>
        let showToast: Signal<String>
        let showFolderSelection: Signal<Item>  // 폴더 선택 Alert
        let showDeleteConfirmation: Signal<Item>  // 삭제 확인 Alert
        let favoriteChanged: Signal<(isbn13: String, isFavorite: Bool)>  // 좋아요 상태 변경
    }

    // 좋아요 탭 / 삭제 확인을 처리한 결과
    private enum FavoriteEvent {
        case added(isbn13: String)    // 기본 폴더에 저장됨
        case removed(isbn13: String)  // 내 서재에서 삭제됨
        case askFolder(Item)          // 사용자가 만든 폴더가 있어서 폴더 선택 필요
        case askDelete(Item)          // 이미 저장된 도서라 삭제 확인 필요
        case failed                   // Realm 처리 실패
    }

    func transform(_ input: Input) -> Output {
        let errorTracker = PublishSubject<String>()
        let loadingTracker = PublishSubject<Bool>()

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

        // 좋아요 탭과 삭제 확인을 각각 FavoriteEvent로 변환한 뒤 하나의 스트림으로 합침
        // share(): 아래에서 이 스트림을 여러 번 구독해도 Realm 처리는 이벤트당 한 번만 실행됨
        let favoriteEvents = Observable.merge(
            input.favoriteButtonTapped.compactMap { [weak self] item in self?.handleFavoriteTap(item) },
            input.deleteConfirmed.compactMap { [weak self] item in self?.handleDeleteConfirmed(item) }
        )
        .share()

        let showFolderSelection = favoriteEvents
            .compactMap { event -> Item? in
                guard case .askFolder(let item) = event else { return nil }
                return item
            }
            .asSignal(onErrorSignalWith: .empty())

        let showDeleteConfirmation = favoriteEvents
            .compactMap { event -> Item? in
                guard case .askDelete(let item) = event else { return nil }
                return item
            }
            .asSignal(onErrorSignalWith: .empty())

        let favoriteChanged = favoriteEvents
            .compactMap { event -> (isbn13: String, isFavorite: Bool)? in
                switch event {
                case .added(let isbn13): return (isbn13, true)
                case .removed(let isbn13): return (isbn13, false)
                case .askFolder, .askDelete, .failed: return nil
                }
            }
            .asSignal(onErrorSignalWith: .empty())

        let showToast = favoriteEvents
            .compactMap { event -> String? in
                switch event {
                case .added: return "내 서재에 추가되었습니다."
                case .removed: return "내 서재에서 제거되었습니다."
                case .failed: return "오류가 발생했습니다."
                case .askFolder, .askDelete: return nil
                }
            }
            .asSignal(onErrorSignalWith: .empty())

        return Output(
            books: books,
            isLoading: loadingTracker.asDriver(onErrorJustReturn: false),
            resultCount: resultCount,
            error: errorTracker.asSignal(onErrorSignalWith: .empty()),
            showToast: showToast,
            showFolderSelection: showFolderSelection,
            showDeleteConfirmation: showDeleteConfirmation,
            favoriteChanged: favoriteChanged
        )
    }

    // MARK: - Favorite

    /// 좋아요 버튼 탭 처리: 저장 상태에 따라 저장 / 폴더 선택 / 삭제 확인 중 하나로 결정
    private func handleFavoriteTap(_ item: Item) -> FavoriteEvent? {
        guard let isbn13 = item.isbn13 else { return nil }

        do {
            // 이미 저장된 도서면 삭제 확인
            if try bookRepository.getBook(byISBN: isbn13) != nil {
                return .askDelete(item)
            }

            // 사용자가 만든 폴더가 있으면 폴더 선택
            let userCreatedFolders = try folderRepository.getAllFolders(type: .book).filter { !$0.isBasic }
            if !userCreatedFolders.isEmpty {
                return .askFolder(item)
            }

            // 없으면 기본 폴더에 바로 저장
            guard let defaultFolder = try folderRepository.getBasicFolder(type: .book) else { return nil }
            try bookRepository.addBookAndAddToFolder(
                BookMapper.toRealmModel(from: item),
                folderId: defaultFolder.id
            )
            return .added(isbn13: isbn13)
        } catch {
            print("좋아요 처리 실패: \(error)")
            return .failed
        }
    }

    // 삭제 확인 처리
    private func handleDeleteConfirmed(_ item: Item) -> FavoriteEvent? {
        do {
            guard let isbn13 = item.isbn13,
                  let existingBook = try bookRepository.getBook(byISBN: isbn13),
                  let defaultFolder = try folderRepository.getBasicFolder(type: .book) else { return nil }

            try bookRepository.removeBookFromFolderAndDelete(
                bookId: existingBook.id,
                folderId: defaultFolder.id
            )
            return .removed(isbn13: isbn13)
        } catch {
            print("도서 삭제 실패: \(error)")
            return .failed
        }
    }

    // MARK: - Public Methods

    // 선택한 폴더에 도서 추가
    func addBookToSelectedFolder(item: Item, folder: FolderRealmModel) -> Observable<(isAdded: Bool, message: String)> {
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

                if try self.bookRepository.getBook(byISBN: isbn13) == nil {
                    let bookRealmModel = BookMapper.toRealmModel(from: item)
                    try self.bookRepository.addBookAndAddToFolder(
                        bookRealmModel,
                        folderId: folder.id
                    )
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
}
