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

    private let titleLabel = UILabel.BookMarkerStyle(text: "", alignment: .left, textFontSize: 16, color: .black, textFontWeight: .bold).then {
        $0.numberOfLines = 2
        $0.lineBreakMode = .byTruncatingTail
    }

    private let authorLabel = UILabel.BookMarkerStyle(text: "", alignment: .left, textFontSize: 14, color: .black, textFontWeight: .medium)

    private let publishInfoStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .leading
        $0.distribution = .fill
    }

    private let publisherLabel = UILabel.BookMarkerStyle(text: "", alignment: .left, textFontSize: 13, color: .systemGray, textFontWeight: .regular)

    private let publishDateLabel = UILabel.BookMarkerStyle(text: "", alignment: .left, textFontSize: 13, color: .systemGray, textFontWeight: .regular)

    private let categoryTagLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.textColor = .systemGreen
        $0.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        $0.textAlignment = .center
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
        $0.text = "카테고리"
    }
    
    // 좋아요 버튼
    private let favoriteButton = FavoriteButton()

    private var disposeBag = DisposeBag()
    
    private lazy var bookInfoStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .fill
        $0.distribution = .fill
    }
    
    
    override func configureHierarchy() {
        [publisherLabel, publishDateLabel].forEach {
            publishInfoStackView.addArrangedSubview($0)
        }

        [titleLabel, authorLabel, publishInfoStackView, categoryTagLabel].forEach {
            bookInfoStackView.addArrangedSubview($0)
        }

        [coverImageView, bookInfoStackView, favoriteButton].forEach {
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

        categoryTagLabel.snp.makeConstraints {
            $0.height.equalTo(24)
            $0.width.greaterThanOrEqualTo(50)
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

    func configure(with item: Item) {
        titleLabel.text = item.title
        authorLabel.text = item.author
        publisherLabel.text = item.publisher
        publishDateLabel.text = item.pubDate
        categoryTagLabel.text = getCategoryTag(from: item.categoryName)

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

        setupFavoriteButton()
    }

    private func setupFavoriteButton() {
        favoriteButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.favoriteButton.isSelected.toggle()
                // TODO: 즐겨찾기 저장/삭제 로직 추가
                print("Favorite button tapped")
            })
            .disposed(by: disposeBag)
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
