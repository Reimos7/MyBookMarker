//
//  BestSellerCarouselCell.swift
//  BookMarker
//
//  Created by Reimos on 9/27/25.
//

import UIKit
import SnapKit
import Then

final class BestSellerCarouselCell: BaseCollectionViewCell {

    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 10
    }

    private let rankLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .bold)
        $0.textColor = .white
        $0.backgroundColor = .systemTeal
        $0.textAlignment = .center
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    private let coverImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.15
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .bold)
        $0.textColor = .black
        $0.numberOfLines = 4
        $0.lineBreakMode = .byTruncatingTail
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.7
    }

    private let authorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .medium)
        $0.textColor = .darkGray
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.8
    }

    private let publisherLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .systemGray
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.8
    }

    private let categoryTagLabel = PaddingLabel().then {
        $0.font = .systemFont(ofSize: 11, weight: .medium)
        $0.textColor = .systemGreen
        $0.backgroundColor = .systemGreen.withAlphaComponent(0.15)
        $0.textAlignment = .center
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.text = "소설"
        $0.padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }

    // 별점 컨테이너
    private let ratingContainer = UIView()

    // 별 5개 스택뷰
    private let starsStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 2
        $0.alignment = .center
    }

    // 평점 라벨
    private let ratingLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .semibold)
        $0.textColor = .systemOrange
        $0.textAlignment = .left
    }

    override func configureHierarchy() {
        contentView.addSubview(containerView)

        [rankLabel, coverImageView, titleLabel, authorLabel, publisherLabel, ratingContainer, categoryTagLabel].forEach {
            containerView.addSubview($0)
        }

        [starsStackView, ratingLabel].forEach {
            ratingContainer.addSubview($0)
        }

        // 별 5개 추가
        for _ in 0..<5 {
            let starImageView = UIImageView().then {
                $0.image = UIImage(systemName: "star.fill")
                $0.tintColor = .systemGray4
                $0.contentMode = .scaleAspectFit
            }
            starsStackView.addArrangedSubview(starImageView)
        }
    }

    override func configureLayout() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(8)
        }

        rankLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().offset(12)
            $0.size.equalTo(24)
        }

        coverImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalTo(rankLabel.snp.bottom).offset(4)
            $0.bottom.equalToSuperview().offset(-20)
            $0.width.equalTo(100)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(coverImageView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalTo(coverImageView.snp.top)
        }

        authorLabel.snp.makeConstraints {
            $0.leading.trailing.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        publisherLabel.snp.makeConstraints {
            $0.leading.trailing.equalTo(titleLabel)
            $0.top.equalTo(authorLabel.snp.bottom).offset(6)
        }

        ratingContainer.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(publisherLabel.snp.bottom).offset(8)
            $0.trailing.lessThanOrEqualTo(titleLabel.snp.trailing)
            $0.height.equalTo(18)
        }

        starsStackView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }

        // 각 별의 크기 설정
        starsStackView.arrangedSubviews.forEach { star in
            star.snp.makeConstraints {
                $0.size.equalTo(13)
            }
        }

        ratingLabel.snp.makeConstraints {
            $0.leading.equalTo(starsStackView.snp.trailing).offset(8)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualToSuperview()
        }

        categoryTagLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.bottom.equalTo(coverImageView.snp.bottom)
        }
    }

    override func configureView() {
        backgroundColor = .clear
    }

    func configure(with item: Item, rank: Int) {
        rankLabel.text = "\(rank)"
        titleLabel.text = item.title

        // 저자명 정제: 첫 번째 저자만 표시
        let mainAuthor = item.author?
            .components(separatedBy: ",").first?
            .components(separatedBy: "(").first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        authorLabel.text = mainAuthor ?? item.author

        publisherLabel.text = item.publisher

        // 카테고리: 마지막 카테고리만 표시
        let lastCategory = item.categoryName?
            .components(separatedBy: ">")
            .last?
            .trimmingCharacters(in: .whitespaces)
        categoryTagLabel.text = lastCategory ?? getCategoryTag(from: item.categoryName)

        // 평점 설정
        let rating = Double(item.customerReviewRank ?? 0)
        configureRating(rating)

        coverImageView.setBookCover(with: item)
    }

    private func configureRating(_ rating: Double) {
        // 평점 라벨 설정
        ratingLabel.text = String(format: "%.1f", rating)

        // 별 5개 설정
        let fullStars = Int(rating)
        let hasHalfStar = rating - Double(fullStars) >= 0.5

        for (index, starView) in starsStackView.arrangedSubviews.enumerated() {
            guard let starImageView = starView as? UIImageView else { continue }

            if index < fullStars {
                // 가득 찬 별
                starImageView.image = UIImage(systemName: "star.fill")
                starImageView.tintColor = .systemOrange
            } else if index == fullStars && hasHalfStar {
                // 반 별
                starImageView.image = UIImage(systemName: "star.leadinghalf.filled")
                starImageView.tintColor = .systemOrange
            } else {
                // 빈 별
                starImageView.image = UIImage(systemName: "star")
                starImageView.tintColor = .systemGray4
            }
        }
    }

    private func getCategoryTag(from categoryName: String?) -> String {
        guard let category = categoryName else { return "도서" }

        if category.contains("소설") { return "소설" }
        if category.contains("인문") { return "인문/철학" }
        if category.contains("자기계발") { return "자기계발" }
        if category.contains("경영") { return "경제/경영" }
        if category.contains("에세이") { return "에세이" }
        if category.contains("과학") { return "과학" }
        if category.contains("역사") { return "역사" }

        return "기타"
    }
}
