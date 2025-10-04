//
//  FolderDetailViewModel.swift
//  BookMarker
//
//  Created by Reimos on 10/3/25.
//

import Foundation
import RxSwift
import RxCocoa

final class FolderDetailViewModel: BaseViewModel {

    struct Input {
        // 현재는 초기 데이터만 표시하므로 Input 없음
    }

    struct Output {
        let books: Driver<[Item]>
    }

    private let disposeBag = DisposeBag()
    private let folderData: BookCardView.FolderBookData

    init(folderData: BookCardView.FolderBookData) {
        self.folderData = folderData
    }

    func transform(_ input: Input) -> Output {
        // 폴더에 저장된 책 목록을 Driver로 변환
        let books = Observable.just(folderData.books)
            .asDriver(onErrorJustReturn: [])

        return Output(books: books)
    }
}
