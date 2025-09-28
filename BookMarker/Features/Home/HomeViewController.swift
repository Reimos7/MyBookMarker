//
//  MainViewController.swift
//  BookMarker
//
//  Created by Reimos on 9/27/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class HomeViewController: UIViewController {

    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    // MARK: - 베스트셀러 캐러셀
    private let bestSellerTitleLabel = UILabel().then {
        $0.text = "베스트셀러"
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .black
    }

    private let bestSellerCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 250)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero

        $0.collectionViewLayout = layout
        $0.register(BestSellerCarouselCell.self, forCellWithReuseIdentifier: BestSellerCarouselCell.reuseIdentifier)
        $0.isPagingEnabled = true
        $0.showsHorizontalScrollIndicator = false
        $0.backgroundColor = .clear
        $0.decelerationRate = .fast
    }

    private let pageControl = UIPageControl().then {
        $0.currentPageIndicatorTintColor = .systemTeal
        $0.pageIndicatorTintColor = .systemGray4
        $0.numberOfPages = 10
    }

    // MARK: - 추천 신간
    private let newBookTitleLabel = UILabel().then {
        $0.text = "추천 신간"
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .black
    }

    private let newBooksCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 140, height: 220)
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        $0.collectionViewLayout = layout
        $0.register(NewBookCell.self, forCellWithReuseIdentifier: NewBookCell.reuseIdentifier)
        $0.showsHorizontalScrollIndicator = false
        $0.backgroundColor = .clear
    }

    // MARK: - 카테고리별 베스트셀러
    private let categoryBestSellerTitleLabel = UILabel().then {
        $0.text = "카테고리별 베스트셀러"
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .black
    }

    private let categoryScrollView = UIScrollView().then {
        $0.showsHorizontalScrollIndicator = false
        $0.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    private let categoryStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.distribution = .equalSpacing
    }

    private var categoryButtons: [UIButton] = []
    private let categorySelectedSubject = PublishSubject<Int>()
    private var currentCategoryItems: [Item] = []

    private let categoryBooksCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 140, height: 220)
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        $0.collectionViewLayout = layout
        $0.register(NewBookCell.self, forCellWithReuseIdentifier: NewBookCell.reuseIdentifier)
        $0.showsHorizontalScrollIndicator = false
        $0.backgroundColor = .clear
    }

    private let disposeBag = DisposeBag()
    private let viewModel = HomeViewModel()
    private var navigationSearchButton: UIBarButtonItem?

    private var carouselTimer: Timer?
    private var originalItemCount = 0
    private var currentRealIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureHierarchy()
        configureLayout()
        configureView()
        setupCollectionView()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)

        // 화면에 나타날 때 타이머 재시작 (데이터가 있는 경우)
        if pageControl.numberOfPages > 1 {
            setupCarouselTimer()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        carouselTimer?.invalidate()
        carouselTimer = nil
    }

    private func setupCarouselTimer() {
        carouselTimer?.invalidate()

        guard pageControl.numberOfPages > 1 else {
            print("페이지가 1개 이하라서 타이머를 시작하지 않음")
            return
        }

        carouselTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.autoScrollCarousel()
        }

        print("타이머 시작됨 - 페이지 수: \(pageControl.numberOfPages)")
    }

    private func autoScrollCarousel() {
        let numberOfItems = bestSellerCollectionView.numberOfItems(inSection: 0)
        guard originalItemCount > 1, numberOfItems > 2 else {
            print("아이템 개수 부족: \(numberOfItems)")
            return
        }

        // 현재 실제 인덱스에서 다음으로 이동
        currentRealIndex = (currentRealIndex + 1) % originalItemCount
        let nextCollectionIndex = currentRealIndex + 1 // 첫 번째 복제 아이템 때문에 +1

        print("자동 스크롤: 실제 \(currentRealIndex) (컬렉션 인덱스: \(nextCollectionIndex))")

        // 다음 페이지로 스크롤
        let targetOffset = CGPoint(x: CGFloat(nextCollectionIndex) * bestSellerCollectionView.frame.width, y: 0)
        bestSellerCollectionView.setContentOffset(targetOffset, animated: true)

        pageControl.currentPage = currentRealIndex

        // 무한 스크롤 처리를 위한 지연 체크
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAndHandleInfiniteScroll()
        }
    }

    private func setupNavigationBar() {
        // 앱 타이틀 설정
        let titleLabel = UILabel().then {
            $0.text = "BookMarker"
            $0.font = .systemFont(ofSize: 20, weight: .bold)
            $0.textColor = .systemTeal
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleLabel)

        // 검색 버튼 설정
        let searchButton = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: nil,
            action: nil
        )
        searchButton.tintColor = .black
        navigationItem.rightBarButtonItem = searchButton

        // 검색 버튼 탭 이벤트를 위해 참조 저장
        self.navigationSearchButton = searchButton
    }

    private func checkAndHandleInfiniteScroll() {
        guard originalItemCount > 1 else { return }

        let currentOffset = bestSellerCollectionView.contentOffset
        let itemWidth = bestSellerCollectionView.frame.width
        let currentIndex = Int(round(currentOffset.x / itemWidth))

        print("🔍 무한 스크롤 체크: 현재 인덱스 \(currentIndex), 원본 개수: \(originalItemCount)")

        // 첫 번째 복제 아이템(인덱스 0)에 있을 때 → 마지막 실제 아이템으로 점프
        if currentIndex == 0 {
            let lastRealItemIndex = originalItemCount // 마지막 실제 아이템
            bestSellerCollectionView.setContentOffset(
                CGPoint(x: CGFloat(lastRealItemIndex) * itemWidth, y: 0),
                animated: false
            )
            currentRealIndex = originalItemCount - 1
            pageControl.currentPage = currentRealIndex
            print(" 처음으로 점프: 인덱스 \(lastRealItemIndex)  실제 \(currentRealIndex)")
        }
        // 마지막 복제 아이템에 있을 때  첫 번째 실제 아이템으로 점프
        else if currentIndex == originalItemCount + 1 {
            bestSellerCollectionView.setContentOffset(
                CGPoint(x: itemWidth, y: 0),
                animated: false
            )
            currentRealIndex = 0
            pageControl.currentPage = currentRealIndex
            print("끝으로 점프: 인덱스 1 실제 \(currentRealIndex)")
        }
    }

    private func handleInfiniteScroll() {
        // didEndDecelerating에서 호출되는 함수
        checkAndHandleInfiniteScroll()
    }

    private func getRealIndex(from collectionIndex: Int) -> Int {
        if originalItemCount <= 1 {
            return collectionIndex
        }

        // 첫 번째는 복제된 마지막 아이템
        if collectionIndex == 0 {
            return originalItemCount - 1
        }
        // 마지막은 복제된 첫 번째 아이템
        else if collectionIndex == originalItemCount + 1 {
            return 0
        }
        // 나머지는 실제 인덱스 - 1
        else {
            return collectionIndex - 1
        }
    }
}

// MARK: - UI Configuration
extension HomeViewController: DesignProtocol {

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [bestSellerTitleLabel, bestSellerCollectionView, pageControl,
         newBookTitleLabel, newBooksCollectionView,
         categoryBestSellerTitleLabel, categoryScrollView, categoryBooksCollectionView].forEach {
            contentView.addSubview($0)
        }
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // 베스트셀러
        bestSellerTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(16)
        }

        bestSellerCollectionView.snp.makeConstraints {
            $0.top.equalTo(bestSellerTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(250)
        }

        pageControl.snp.makeConstraints {
            $0.top.equalTo(bestSellerCollectionView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }

        // 추천 신간
        newBookTitleLabel.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(16)
        }

        newBooksCollectionView.snp.makeConstraints {
            $0.top.equalTo(newBookTitleLabel.snp.bottom).offset(2)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(250)
        }

        // 카테고리별 베스트셀러
        categoryBestSellerTitleLabel.snp.makeConstraints {
            $0.top.equalTo(newBooksCollectionView.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(16)
        }

        categoryScrollView.snp.makeConstraints {
            $0.top.equalTo(categoryBestSellerTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }

        categoryScrollView.addSubview(categoryStackView)
        categoryStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }

        categoryBooksCollectionView.snp.makeConstraints {
            $0.top.equalTo(categoryScrollView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(220)
            $0.bottom.equalToSuperview().offset(-32)
        }
    }

    func configureView() {
        view.backgroundColor = .systemGray6
    }

    func setupCollectionView() {
        // 카테고리 선택 이벤트를 API 호출로 연결
        categorySelectedSubject
            .flatMapLatest { [weak self] index -> Observable<[Item]> in
                guard let self = self else { return Observable.empty() }

                let categories: [BookCategory] = [.computer, .science, .novel, .selfDevolop, .humanities, .business]
                guard index < categories.count else { return Observable.empty() }

                let category = categories[index]
                print("카테고리 API 호출: \(category.displayName) (ID: \(category.rawValue))")

                return NetworkManager.shared
                    .request(.categoryBest(categoryId: category), responseType: Book.self)
                    .asObservable()
                    .compactMap { result -> [Item]? in
                        switch result {
                        case .success(let book):
                            print("RxSwift API 성공: \(book.item.count)개 아이템")
                            return book.item
                        case .failure(let error):
                            print("RxSwift API 실패: \(error.localizedDescription)")
                            return nil
                        }
                    }
                    .catchAndReturn([])
            }
            .observe(on: MainScheduler.instance)
            .bind(to: categoryBooksCollectionView.rx.items(
                cellIdentifier: NewBookCell.reuseIdentifier,
                cellType: NewBookCell.self
            )) { (index: Int, item: Item, cell: NewBookCell) in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - Binding
extension HomeViewController {

    func bind() {
        let input = HomeViewModel.Input(
            viewDidLoad: Observable.just(()),
            categorySelected: Observable.never(), // 일단 비활성화
            searchButtonTapped: navigationSearchButton?.rx.tap.asObservable() ?? Observable.never()
        )

        let output = viewModel.transform(input)

        // 베스트셀러 바인딩
        output.bestSellers
            .drive(bestSellerCollectionView.rx.items(
                cellIdentifier: BestSellerCarouselCell.reuseIdentifier,
                cellType: BestSellerCarouselCell.self
            )) { [weak self] (index: Int, item: Item, cell: BestSellerCarouselCell) in
                guard let self = self else { return }

                // 무한 스크롤을 위한 실제 인덱스 계산
                let realIndex = self.getRealIndex(from: index)
                cell.configure(with: item, rank: realIndex + 1)
                print("베스트셀러 셀 구성: \(index) - 실제 순위: \(realIndex + 1) - \(item.title ?? "제목없음")")
            }
            .disposed(by: disposeBag)

        // 추천 신간 바인딩
        output.newBooks
            .drive(newBooksCollectionView.rx.items(
                cellIdentifier: NewBookCell.reuseIdentifier,
                cellType: NewBookCell.self
            )) { (_: Int, item: Item, cell: NewBookCell) in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        // 카테고리 바인딩 (스크롤뷰로 변경)
        output.categories
            .drive(with: self) { owner, categories in
                owner.setupCategoryButtons(categories: categories)
            }
            .disposed(by: disposeBag)

        // 카테고리별 베스트셀러는 setupCollectionView()에서 처리

        // 베스트셀러 개수로 페이지 컨트롤 업데이트 및 타이머 시작
        output.bestSellers
            .drive(with: self) { owner, items in
                // 무한 스크롤용 데이터에서 원본 개수 계산
                if items.count > 2 {
                    owner.originalItemCount = items.count - 2 // 앞뒤 복제 아이템 제외
                } else {
                    owner.originalItemCount = items.count
                }
                
                self.pageControl.numberOfPages = self.originalItemCount
                print("베스트셀러 아이템 개수: \(items.count) (원본: \(self.originalItemCount))")
                
                if owner.originalItemCount > 1 {
                    // 컬렉션뷰가 완전히 로드된 후 초기 위치 설정 및 타이머 시작
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // 첫 번째 실제 아이템으로 이동 (인덱스 1)
                        owner.bestSellerCollectionView.setContentOffset(
                            CGPoint(x: owner.bestSellerCollectionView.frame.width, y: 0),
                            animated: false
                        )
                        owner.currentRealIndex = 0
                        owner.pageControl.currentPage = 0
                        owner.setupCarouselTimer()
                    }
                }
            }
            .disposed(by: disposeBag)

        // 스크롤 이벤트로 페이지 컨트롤 업데이트
        bestSellerCollectionView.rx.didEndDecelerating
            .asDriver()
            .drive(with: self) { owner, _ in
                let pageWidth = self.bestSellerCollectionView.frame.width
                let currentCollectionIndex = Int(round(owner.bestSellerCollectionView.contentOffset.x / pageWidth))
                
                // 무한 스크롤 처리
                owner.handleInfiniteScroll()
                
                // 실제 페이지 인덱스 업데이트
                owner.currentRealIndex = self.getRealIndex(from: currentCollectionIndex)
                owner.pageControl.currentPage = self.currentRealIndex
                
                print(" 사용자 스크롤: 컬렉션 인덱스 \(currentCollectionIndex)  실제 인덱스 \(self.currentRealIndex)")
                
                // 사용자가 수동 스크롤 시 타이머 재시작
                self.setupCarouselTimer()
            }
            .disposed(by: disposeBag)

        // 검색 버튼 탭 이벤트
        output.navigateToSearch
            .drive(with: self) { owner, _ in
                print("검색 버튼 탭됨 - 화면 전환 시작")
                let searchVC = SearchViewController()
                owner.navigationController?.pushViewController(searchVC, animated: true)
                print("SearchViewController 푸시 완료")
            }
            .disposed(by: disposeBag)
    }

    private func setupCategoryButtons(categories: [BookCategory]) {
        // 기존 버튼들 제거
        categoryButtons.forEach { $0.removeFromSuperview() }
        categoryButtons.removeAll()

        // 새로운 버튼들 생성
        for (index, category) in categories.enumerated() {
            let button = UIButton().then {
                $0.setTitle(category.displayName, for: .normal)
                $0.setTitleColor(.black, for: .normal)
                $0.setTitleColor(.white, for: .selected)
                $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
                $0.backgroundColor = .systemGray6
                $0.layer.cornerRadius = 20
                $0.layer.borderWidth = 1
                $0.layer.borderColor = UIColor.systemGray4.cgColor
                $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
                $0.tag = index
            }

            button.rx.tap
                .asDriver()
                .drive(with: self) { owner, _ in
                    print("카테고리 \(index) 버튼 클릭됨: \(category.displayName)")
                    owner.selectCategory(at: index)
                    owner.categorySelectedSubject.onNext(index)
                }
                .disposed(by: disposeBag)

            categoryStackView.addArrangedSubview(button)
            categoryButtons.append(button)
        }

        // 첫 번째 카테고리 선택
        if !categoryButtons.isEmpty {
            selectCategory(at: 0)
            categorySelectedSubject.onNext(0)
        }
    }

    private func selectCategory(at index: Int) {
        print(" 카테고리 선택됨: \(index)")

        // 모든 버튼 선택 해제
        categoryButtons.forEach { button in
            button.isSelected = false
            button.backgroundColor = .systemGray6
            button.layer.borderColor = UIColor.systemGray4.cgColor
        }

        // 선택된 버튼 활성화
        if index < categoryButtons.count {
            let selectedButton = categoryButtons[index]
            selectedButton.isSelected = true
            selectedButton.backgroundColor = .systemTeal
            selectedButton.layer.borderColor = UIColor.systemTeal.cgColor
        }
    }
}

