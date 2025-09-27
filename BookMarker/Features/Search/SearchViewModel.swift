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

    struct Input {
        let searchText: Observable<String>
        let searchTrigger: Observable<Void>
    }

    struct Output {
        let books: Driver<[Item]>
        let isLoading: Driver<Bool>
        let error: Driver<String>
        let resultCount: Driver<String>
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

        return Output(
            books: books,
            isLoading: loadingTracker.asDriver(onErrorJustReturn: false),
            error: errorTracker.asDriver(onErrorJustReturn: ""),
            resultCount: resultCount
        )
    }
}
