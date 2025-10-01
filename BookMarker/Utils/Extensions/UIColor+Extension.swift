//
//  UIColor+Extension.swift
//  BookMarker
//
//  Created by Reimos on 10/2/25.
//

import UIKit

extension UIColor {

    /// Hex String으로부터 UIColor 생성
    /// - Parameter hexString: "#RRGGBB" 또는 "RRGGBB" 형태의 문자열
    convenience init?(hexString: String) {
        var hexSanitized = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    /// UIColor를 Hex String으로 변환
    /// - Returns: "#RRGGBB" 형태의 문자열
    var hexString: String? {
        guard let components = cgColor.components, components.count >= 3 else {
            return nil
        }

        let red = Int(components[0] * 255.0)
        let green = Int(components[1] * 255.0)
        let blue = Int(components[2] * 255.0)

        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
