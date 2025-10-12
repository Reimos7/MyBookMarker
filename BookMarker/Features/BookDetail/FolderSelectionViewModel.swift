//
//  FolderSelectionViewModel.swift
//  BookMarker
//
//  Created by Reimos on 10/2/25.
//

import Foundation
import RxSwift
import RxCocoa

/// 폴더 선택 ViewModel
final class FolderSelectionViewModel: BaseViewModel {

    struct Input {
        let viewDidLoad: Observable<Void>
        let folderSelected: Observable<FolderRealmModel>
        let createFolderTapped: Observable<Void>
    }

    struct Output {
        let folders: Driver<[FolderRealmModel]>
        let selectedFolder: Driver<FolderRealmModel>
        let showCreateFolder: Driver<Void>
    }

    private let folderRepository = FolderRepository()
    private let disposeBag = DisposeBag()
    private let folderType: FolderType

    init(folderType: FolderType = .book) {
        self.folderType = folderType
    }

    func transform(_ input: Input) -> Output {
        // 폴더 목록 조회 (타입에 따라)
        let folders = input.viewDidLoad
            .flatMap { [weak self] _ -> Observable<[FolderRealmModel]> in
                guard let self = self else { return .just([]) }

                do {
                    let allFolders = try self.folderRepository.getAllFolders(type: self.folderType)
                    // 기본 폴더를 맨 위로 정렬
                    let sorted = allFolders.sorted { folder1, folder2 in
                        if folder1.isBasic && !folder2.isBasic {
                            return true
                        } else if !folder1.isBasic && folder2.isBasic {
                            return false
                        } else {
                            return folder1.createdDate < folder2.createdDate
                        }
                    }
                    return .just(sorted)
                } catch {
                    print("폴더 목록 조회 실패: \(error)")
                    return .just([])
                }
            }
            .asDriver(onErrorJustReturn: [])

        // 선택된 폴더
        let selectedFolder = input.folderSelected
            .asDriver(onErrorDriveWith: .empty())

        // 새 폴더 만들기
        let showCreateFolder = input.createFolderTapped
            .asDriver(onErrorJustReturn: ())

        return Output(
            folders: folders,
            selectedFolder: selectedFolder,
            showCreateFolder: showCreateFolder
        )
    }
}
