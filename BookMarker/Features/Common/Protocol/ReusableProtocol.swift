//
//  ReusableProtocol.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import UIKit

// 테이블뷰 컬렉션뷰 셀에 사용
protocol ReusableProtocol: AnyObject {
    static var reuseIdentifier: String {get}
}

extension UIView: ReusableProtocol {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

