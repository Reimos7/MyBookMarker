//
//  BookDetailViewModel.swift
//  BookMarker
//
//  Created by Reimos on 9/28/25.
//

import Foundation
import RxSwift
import RxCocoa

final class BookDetailViewModel: BaseViewModel {

    struct Input {
        let bookItem: Observable<Item>
        let heartButtonTapped: Observable<Void>
    }

    struct Output {
        let otherBooks: Driver<[Item]>
        let recommendedBooks: Driver<[Item]>
        let isFavorite: Driver<Bool>
        let showToast: Driver<String>
    }

    private let disposeBag = DisposeBag()

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


        // 즐겨찾기 상태 (임시로 false)
        let isFavorite = PublishSubject<Bool>()
        let favoriteState = BehaviorRelay<Bool>(value: false)

        input.heartButtonTapped
            .withLatestFrom(favoriteState.asObservable())
            .map { !$0 }
            .do(onNext: { newState in
                favoriteState.accept(newState)
                print("즐겨찾기 상태 변경: \(newState)")
            })
            .subscribe()
            .disposed(by: disposeBag)

        // 토스트 메시지
        let showToast = favoriteState.asObservable()
            .skip(1) // 초기값 스킵
            .map { isFavorite in
                isFavorite ? "즐겨찾기에 추가되었습니다." : "즐겨찾기에서 제거되었습니다."
            }
            .asDriver(onErrorJustReturn: "")

        return Output(
            otherBooks: otherBooks,
            recommendedBooks: recommendedBooks,
            isFavorite: favoriteState.asDriver(),
            showToast: showToast
        )
    }

    // 카테고리 ID 추출 헬퍼 함수
    private func extractCategoryId(from book: Item) -> BookCategory? {
        // 책의 categoryId 필드가 있다면 직접 매핑
        // 없다면 categoryName으로 추론하거나 기본값 사용
        // 임시로 기본 카테고리들 중 하나를 반환 (추후 개선 가능)
        let categories: [BookCategory] = [.computer, .science, .novel, .selfDevolop, .humanities, .business]
        return categories.randomElement()
    }
}
