//
//  PlaceDetailViewModel.swift
//  BookMarker
//
//  Created by Reimos on 10/20/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class PlaceDetailViewModel: BaseViewModel {

    // MARK: - Properties
    private let place: PlaceRealmModel
    private let bookRepository = BookRepository()
    private let disposeBag = DisposeBag()

    // MARK: - Init
    init(place: PlaceRealmModel) {
        self.place = place
    }

    // MARK: - Input/Output
    struct Input {
        let refreshTrigger: Observable<Void>
        let addBookTrigger: Observable<Void>
    }

    struct Output {
        let books: Driver<[Item]>
        let bookCount: Driver<Int>
        let showBookSelector: Driver<Void>
    }

    func transform(_ input: Input) -> Output {
        // 장소 ID를 String으로 변환
        let placeId = place.id.stringValue

        // 책 목록 가져오기
        let books = input.refreshTrigger
            .flatMapLatest { [weak self] _ -> Observable<[Item]> in
                guard let self = self else { return .just([]) }

                do {
                    // placeId로 필터링된 책 목록 가져오기
                    let allBooks = try self.bookRepository.getAllBooks()
                    let filteredBooks = allBooks.filter { $0.placeId == placeId }

                    // BookRealmModel → Item 변환
                    let items = filteredBooks.map { book -> Item in
                        return Item(
                            title: book.title,
                            link: nil,
                            author: book.author,
                            pubDate: book.publishedDate,
                            description: book.bookDescription,
                            isbn13: book.isbn13,
                            itemId: nil,
                            priceSales: nil,
                            priceStandard: nil,
                            cover: book.coverImageURL,
                            categoryId: nil,
                            categoryName: book.category,
                            publisher: book.publisher,
                            salesPoint: nil,
                            customerReviewRank: nil,
                            bestDuration: nil,
                            bestRank: nil
                        )
                    }

                    return .just(items)
                } catch {
                    print("책 목록 로드 실패: \(error)")
                    return .just([])
                }
            }
            .asDriver(onErrorJustReturn: [])

        // 책 개수
        let bookCount = books
            .map { $0.count }

        // 책 추가 트리거
        let showBookSelector = input.addBookTrigger
            .asDriver(onErrorJustReturn: ())

        return Output(
            books: books,
            bookCount: bookCount,
            showBookSelector: showBookSelector
        )
    }
}
