//
//  UILabel+Extensions.swift
//  BookMarker
//
//  Created by Reimos on 9/26/25.
//

import UIKit

extension UILabel {
    static func BookMarkerStyle(text: String, alignment: NSTextAlignment, textFontSize: CGFloat, color: UIColor, textFontWeight: UIFont.Weight) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = color
        label.textAlignment = alignment
        label.font = UIFont.systemFont(ofSize: textFontSize, weight: textFontWeight)

        return label
    }
}

// MARK: - PaddingLabel
class PaddingLabel: UILabel {
    var padding = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.height += padding.top + padding.bottom
        contentSize.width += padding.left + padding.right
        return contentSize
    }
}
