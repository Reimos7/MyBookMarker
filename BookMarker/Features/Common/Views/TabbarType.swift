//
//  TabbarType.swift
//  BookMarker
//
//  Created by Reimos on 9/28/25.
//

import UIKit

enum TabbarType: CaseIterable {
//    case map
    case realMap
    case home
    case my

    var viewController: UIViewController {
        switch self {
//        case .map:
//            return SearchViewController()
//            //return ViewController()
        case .realMap:
            return MapViewController()
        case .home:
            return HomeViewController()
        case .my:
            return LibraryViewController()
        }
    }

    var imageName: String {
        switch self {
//        case .map:
//            return "magnifyingglass"
        case .realMap:
            return "map.fill"
        case .home:
            return "house.fill"
        case .my:
            return "person.fill"
        }
    }

    var tag: Int {
        switch self {
//        case .map:
//            return 0
        case .realMap:
            return 0
        case .home:
            return 1
        case .my:
            return 2
        }
    }

    var title: String {
        switch self {
//        case .map:
//            return ""
        case .realMap:
            return ""
        case .home:
            return ""
        case .my:
            return ""
        }
    }
}
