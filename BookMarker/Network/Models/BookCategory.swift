//
//  BookCategory.swift
//  BookMarker
//
//  Created by Reimos on 9/27/25.
//

import Foundation

enum BookCategory: Int, CaseIterable {
    case computer = 351
    case science = 987
    case novel = 1
    case selfDevolop = 336
    case humanities = 656
    case business = 170
    
    var displayName: String {
        switch self {
        case .computer:
            return "컴퓨터/모바일"
        case .science:
            return "과학"
        case .novel:
            return "소설/시/희곡"
        case .selfDevolop:
            return "자기계발"
        case .humanities:
            return "인문"
        case .business:
            return "경제/경영"
        }
    }
}
