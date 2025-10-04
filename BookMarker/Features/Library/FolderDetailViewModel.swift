//
//  FolderDetailViewModel.swift
//  BookMarker
//
//  Created by Reimos on 10/3/25.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class FolderDetailViewModel: BaseViewModel {

    struct Input {
        let refresh: Observable<Void>
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
        // refresh 트리거가 발생할 때마다 폴더 데이터를 다시 로드
        let books = input.refresh
            .startWith(()) // 초기 로드
            .map { [weak self] _ -> [Item] in
                guard let self = self else { return [] }
                // Realm에서 최신 폴더의 도서 목록 조회
                let repository = BookRepository()
                do {
                    guard let objectId = try? ObjectId(string: self.folderData.id) else {
                        return self.folderData.books
                    }
                    let realmBooks = try repository.getBooks(in: objectId)
                    return realmBooks.map { BookMapper.toItem(from: $0) }
                } catch {
                    print("[폴더 도서 조회 오류] \(error.localizedDescription)")
                }
                return self.folderData.books
            }
            .asDriver(onErrorJustReturn: [])

        return Output(books: books)
    }
}
