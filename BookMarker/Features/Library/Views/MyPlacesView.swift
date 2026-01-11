//
//  MyPlacesView.swift
//  BookMarker
//
//  Created by Reimos on 10/11/25.
//

import UIKit
import SnapKit
import Then

// 내 장소 탭에 표시될 뷰
// 장소 폴더 목록을 스크롤 가능하게 표시
final class MyPlacesView: UIView {

    // MARK: - UI Components

    // 스크롤뷰 (폴더 목록 스크롤용)
    let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    // 컨텐츠 뷰 (스크롤뷰 내부)
    private let contentView = UIView()

    // 폴더 스택뷰 (폴더 카드들을 세로로 쌓음)
    let foldersStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 20
        $0.distribution = .fill
    }

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemBackground

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(foldersStackView)
    }

    private func setupLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        foldersStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-20)
        }
    }
}
