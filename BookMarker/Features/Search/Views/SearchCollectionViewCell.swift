//
//  SearchCollectionViewCell.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher
import RxSwift

final class SearchCollectionViewCell: BaseCollectionViewCell {
    
    private let coverImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    private let titleLabel = UILabel.BookMarkerStyle(text: "", alignment: .left, textFontSize: 14, color: .black, textFontWeight: .bold).then {
        $0.numberOfLines = 3
        $0.lineBreakMode = .byTruncatingTail
    }

    // 별점 뷰
    private let starRatingView = StarRatingView()

    private let categoryTagLabel = PaddingLabel().then {
        $0.font = .systemFont(ofSize: 11, weight: .medium)
        $0.textColor = .systemGreen
        $0.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        $0.textAlignment = .center
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.text = "카테고리"
        $0.padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }
    
    // 좋아요 버튼
    private let favoriteButton = FavoriteButton()

    private var disposeBag = DisposeBag()

    // 좋아요 버튼 탭 이벤트를 외부로 전달
    var favoriteButtonTapped: (() -> Void)?
    
    private lazy var bookInfoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .fill
        $0.distribution = .fill
    }
    
    
    override func configureHierarchy() {
        [titleLabel, starRatingView].forEach {
            bookInfoStackView.addArrangedSubview($0)
        }

        [coverImageView, bookInfoStackView, categoryTagLabel, favoriteButton].forEach {
            contentView.addSubview($0)
        }
    }
    
    override func configureLayout() {
        coverImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.verticalEdges.equalToSuperview().inset(16)
            make.width.equalTo(70)
        }

        bookInfoStackView.snp.makeConstraints { make in
            make.leading.equalTo(coverImageView.snp.trailing).offset(16)
            make.top.equalTo(coverImageView.snp.top)
            make.trailing.equalTo(favoriteButton.snp.leading).offset(-12)
        }

        favoriteButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
            make.size.equalTo(32)
        }

        starRatingView.snp.makeConstraints {
            $0.height.equalTo(16)
        }

        // 카테고리 - 도서 이미지 하단에 고정
        categoryTagLabel.snp.makeConstraints {
            $0.leading.equalTo(bookInfoStackView.snp.leading)
            $0.bottom.equalTo(coverImageView.snp.bottom)
        }
    }
    
    override func configureView() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
    }

    func configure(with item: Item, isFavorite: Bool) {
        titleLabel.text = item.title

        // 별점 설정
        if let reviewRank = item.customerReviewRank {
            starRatingView.rating = Double(reviewRank)
            starRatingView.isHidden = false
        } else {
            starRatingView.rating = 0.0
            starRatingView.isHidden = true
        }

        // 카테고리 - 마지막 카테고리만 표시
        let lastCategory = item.categoryName?
            .components(separatedBy: ">")
            .last?
            .trimmingCharacters(in: .whitespaces)
        categoryTagLabel.text = lastCategory ?? "도서"

        if let coverURL = item.cover, let url = URL(string: coverURL) {
            coverImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "book.closed"),
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage
                ]
            )
        } else {
            coverImageView.image = UIImage(systemName: "book.closed")
        }

        // 좋아요 상태 설정
        favoriteButton.isSelected = isFavorite

        setupFavoriteButton()
    }

    private func setupFavoriteButton() {
        favoriteButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.favoriteButtonTapped?()
            })
            .disposed(by: disposeBag)
    }

    /// 좋아요 상태 업데이트 (외부에서 호출)
    func updateFavoriteState(_ isFavorite: Bool) {
        favoriteButton.isSelected = isFavorite
    }
}
