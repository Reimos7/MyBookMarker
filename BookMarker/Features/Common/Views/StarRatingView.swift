//
//  StarRatingView.swift
//  BookMarker
//
//  Created by Reimos on 9/29/25.
//

import UIKit
import SnapKit
import Then

final class StarRatingView: UIView {

    private let containerStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 6
        $0.alignment = .center
    }

    private let starStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 2
        $0.distribution = .fillEqually
    }

    private let ratingLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .darkGray
        $0.text = "0.0"
    }

    private var starImageViews: [UIImageView] = []
    
    // 10점 만점 평점 (API에서 받은 값 그대로 사용)
    var rating: Double = 0.0 {
        didSet {
            updateStars()
            updateRatingLabel()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerStackView)
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 별 스택뷰와 평점 라벨 추가
        containerStackView.addArrangedSubview(starStackView)
        containerStackView.addArrangedSubview(ratingLabel)

        // 별 5개 만들기
        for _ in 0..<5 {
            let star = UIImageView()
            star.contentMode = .scaleAspectFit
            starStackView.addArrangedSubview(star)
            starImageViews.append(star)
            star.snp.makeConstraints { make in
                make.size.equalTo(14)
            }
        }
    }
    
    private func updateStars() {
        // 별 5개니까 10점 -> 5점
        let score = rating / 2.0
        
        for (index, star) in starImageViews.enumerated() {
            let difference = score - Double(index)
            
            if difference >= 1.0 {
                // 꽉찬 별
                star.image = UIImage(systemName: "star.fill")
                star.tintColor = .systemOrange
            } else if difference >= 0.5 {
                // 반쪽 별
                star.image = UIImage(systemName: "star.leadinghalf.filled")
                star.tintColor = .systemOrange
            } else {
                star.image = UIImage(systemName: "star")
                star.tintColor = .systemGray3
            }
        }
    }

    private func updateRatingLabel() {
        if rating > 0 {
            ratingLabel.text = String(format: "%.1f", rating)
        } else {
            ratingLabel.text = "0.0"
        }
    }
}
