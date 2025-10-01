//
//  TabbarType.swift
//  BookMarker
//
//  Created by Reimos on 9/28/25.
//

import UIKit

enum TabbarType: CaseIterable {
    case map
    case home
    case my
    
    var viewController: UIViewController {
        switch self {
        case .map:
            return ViewController()
        case .home:
            return HomeViewController()
        case .my:
            return LibraryViewController()
        }
    }
    
    var imageName: String {
        switch self {
        case .map:
            return "map.fill"
        case .home:
            return "house.fill"
        case .my:
            return "person.fill"
        }
    }
    
    var tag: Int {
        switch self {
        case .map:
            return 0
        case .home:
            return 1
        case .my:
            return 2
        }
    }
    
    var title: String {
        switch self {
        case .map:
            return "지도"
        case .home:
            return "홈"
        case .my:
            return "내 파일"
        }
    }
}
