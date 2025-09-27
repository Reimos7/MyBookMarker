//
//  FavoriteButton.swift
//  BookMarker
//
//  Created by Reimos on 9/26/25.
//


// MARK: - 좋아요 버튼 
import UIKit

final class FavoriteButton: UIButton {
    init() {
        super.init(frame: .zero)
        
        setImage(UIImage(systemName: "heart"), for: .normal)
        setImage(UIImage(systemName: "heart.fill"), for: .selected)
        
        layer.borderColor = UIColor.red.cgColor
        tintColor = .red
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
