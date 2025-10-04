//
//  BookDiaryViewModel.swift
//  BookMarker
//
//  Created by Reimos on 10/3/25.
//

import Foundation
import RxSwift
import RxCocoa

final class BookDiaryViewModel: BaseViewModel {

    struct Input {
        let saveTapped: Observable<Void>
        let diaryText: Observable<String>
        let rating: Observable<Int>
        let quote: Observable<String>
        let tags: Observable<[String]>
        let startDate: Observable<String>
        let endDate: Observable<String>
    }

    struct Output {
        let saveSuccess: Driver<Bool>
        let errorMessage: Driver<String>
    }

    private let disposeBag = DisposeBag()

    func transform(_ input: Input) -> Output {
        let saveResult = PublishSubject<Bool>()
        let errorMessage = PublishSubject<String>()

        // 저장 로직
        input.saveTapped
            .withLatestFrom(Observable.combineLatest(
                input.diaryText,
                input.rating,
                input.quote,
                input.tags,
                input.startDate,
                input.endDate
            ))
            .subscribe(onNext: { (diary, rating, quote, tags, startDate, endDate) in
                // TODO: Realm에 독서 일기 저장
                print("""
                독서 일기 저장:
                - 일기: \(diary)
                - 평점: \(rating)
                - 구절: \(quote)
                - 태그: \(tags)
                - 시작일: \(startDate)
                - 완료일: \(endDate)
                """)

                saveResult.onNext(true)
            })
            .disposed(by: disposeBag)

        return Output(
            saveSuccess: saveResult.asDriver(onErrorJustReturn: false),
            errorMessage: errorMessage.asDriver(onErrorJustReturn: "")
        )
    }
}
