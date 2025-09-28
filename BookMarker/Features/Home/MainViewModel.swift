//
//  MainViewModel.swift
//  BookMarker
//
//  Created by Reimos on 9/27/25.
//

import Foundation
import RxSwift
import RxCocoa

final class HomeViewModel: BaseViewModel {

    private let disposeBag = DisposeBag()
    private let networkManager = NetworkManager.shared

    private let categories: [BookCategory] = [.computer, .science, .novel, .selfDevolop, .humanities, .business]

    struct Input {
        let viewDidLoad: Observable<Void>
        let categorySelected: Observable<IndexPath>
        let searchButtonTapped: Observable<Void>
    }

    struct Output {
        let bestSellers: Driver<[Item]>
        let newBooks: Driver<[Item]>
        let categories: Driver<[BookCategory]>
        let categoryBooks: Driver<[Item]>
        let navigateToSearch: Driver<Void>
        let isLoading: Driver<Bool>
        let error: Driver<String>
    }

    func transform(_ input: Input) -> Output {
        let errorTracker = PublishSubject<String>()
        let loadingTracker = PublishSubject<Bool>()

        // 베스트셀러 데이터
        let bestSellers = input.viewDidLoad
            .do(onNext: { loadingTracker.onNext(true) })
            .flatMapLatest { [weak self] _ -> Observable<[Item]> in
                guard let self = self else { return .empty() }

                return self.networkManager
                    .request(.bestSeller, responseType: Book.self)
                    .asObservable()
                    .compactMap { result -> [Item]? in
                        switch result {
                        case .success(let book):
                            print("베스트셀러 API 응답: \(book.item.count)개 아이템")
                            book.item.enumerated().forEach { index, item in
                                print("  \(index + 1). \(item.title ?? "제목없음")")
                            }

                            // 무한 스크롤을 위해 데이터를 복제 (앞에 마지막 아이템, 뒤에 첫 번째 아이템 추가)
                            var infiniteItems = book.item
                            if book.item.count > 1 {
                                // 마지막 아이템을 맨 앞에 추가
                                if let lastItem = book.item.last {
                                    infiniteItems.insert(lastItem, at: 0)
                                }
                                // 첫 번째 아이템을 맨 뒤에 추가
                                if let firstItem = book.item.first {
                                    infiniteItems.append(firstItem)
                                }
                            }

                            print("무한 스크롤용 아이템: \(infiniteItems.count)개")
                            return infiniteItems
                        case .failure(let error):
                            print("베스트셀러 API 에러: \(error.localizedDescription)")
                            errorTracker.onNext(error.localizedDescription)
                            return nil
                        }
                    }
                    .do(onNext: { items in
                        loadingTracker.onNext(false)
                        print("베스트셀러 Observable 방출: \(items.count)개")
                    })
            }
            .asDriver(onErrorJustReturn: [])

        // 신간 데이터
        let newBooks = input.viewDidLoad
            .flatMapLatest { [weak self] _ -> Observable<[Item]> in
                guard let self = self else { return .empty() }

                return self.networkManager
                    .request(.newBooks, responseType: Book.self)
                    .asObservable()
                    .compactMap { result -> [Item]? in
                        switch result {
                        case .success(let book):
                            return book.item
                        case .failure(let error):
                            errorTracker.onNext(error.localizedDescription)
                            return nil
                        }
                    }
            }
            .asDriver(onErrorJustReturn: [])

        // 카테고리 데이터
        let categoriesDriver = Driver.just(categories)

        // 선택된 카테고리에 따른 도서 데이터
        let selectedCategoryIndex = BehaviorRelay<Int>(value: 0)

        input.categorySelected
            .map { indexPath in
                print("🎯 카테고리 선택 이벤트 수신: \(indexPath.item)")
                return indexPath.item
            }
            .do(onNext: { index in
                print("🎯 selectedCategoryIndex에 바인딩: \(index)")
            })
            .bind(to: selectedCategoryIndex)
            .disposed(by: disposeBag)

        // selectedCategoryIndex 값 변화 추적
        selectedCategoryIndex
            .asObservable()
            .subscribe(onNext: { index in
                print("🎯 selectedCategoryIndex 값 변경됨: \(index)")
            })
            .disposed(by: disposeBag)

        let categoryBooks = selectedCategoryIndex
            .asObservable()
            .startWith(0) // 초기값
            .flatMapLatest { [weak self] index -> Observable<[Item]> in
                guard let self = self,
                      index < self.categories.count else {
                    print("카테고리 인덱스 범위 오류: \(index)")
                    return .empty()
                }

                let category = self.categories[index]
                print("카테고리 API 요청: 인덱스=\(index), 카테고리=\(category.displayName), ID=\(category.rawValue)")
                print("API URL 체크용 - CategoryId=\(category.rawValue)")

                return self.networkManager
                    .request(.categoryBest(categoryId: category), responseType: Book.self)
                    .asObservable()
                    .compactMap { result -> [Item]? in
                        switch result {
                        case .success(let book):
                            print("카테고리 \(category.displayName) API 응답: \(book.item.count)개 아이템")
                            return book.item
                        case .failure(let error):
                            print("카테고리 API 에러: \(error.localizedDescription)")
                            errorTracker.onNext(error.localizedDescription)
                            return nil
                        }
                    }
            }
            .asDriver(onErrorJustReturn: [])

        return Output(
            bestSellers: bestSellers,
            newBooks: newBooks,
            categories: categoriesDriver,
            categoryBooks: categoryBooks,
            navigateToSearch: input.searchButtonTapped.asDriver(onErrorJustReturn: ()),
            isLoading: loadingTracker.asDriver(onErrorJustReturn: false),
            error: errorTracker.asDriver(onErrorJustReturn: "")
        )
    }

}
