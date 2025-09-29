//
//  SearchViewController.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then

final class SearchViewController: UIViewController {

    private let searchBar = SearchBar()
    private let resultCountLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .black
        $0.text = "검색 결과 (0건)"
    }

    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    ).then {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 150)
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        $0.collectionViewLayout = layout
        $0.register(SearchCollectionViewCell.self, forCellWithReuseIdentifier: SearchCollectionViewCell.reuseIdentifier)
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .systemGray6
    }

    private let disposeBag = DisposeBag()
    private let viewModel = SearchViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        configureHierarchy()
        configureLayout()
        configureView()
        bind()
    }

    private func setupNavigationBar() {
        title = ""
        navigationController?.navigationBar.tintColor = .black

        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton

        let searchButton = UIBarButtonItem(
            image: UIImage(systemName: "magnifyingglass"),
            style: .plain,
            target: self,
            action: #selector(searchButtonTapped)
        )
        navigationItem.rightBarButtonItem = searchButton
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func searchButtonTapped() {
        searchBar.textField.becomeFirstResponder()
    }
    
   
}


// MARK: - DesiginProtocolBind
extension SearchViewController: DesiginProtocolBind {
    
    func bind() {
        let searchTrigger = PublishSubject<Void>()

        let input = SearchViewModel.Input(
            searchText: searchBar.textField.rx.text.orEmpty.asObservable(),
            searchTrigger: searchTrigger.asObservable()
        )

        let output = viewModel.transform(input)

        // 검색 결과를 컬렉션뷰에 바인딩
        output.books
            .drive(collectionView.rx.items(
                cellIdentifier: SearchCollectionViewCell.reuseIdentifier,
                cellType: SearchCollectionViewCell.self
            )) { index, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: disposeBag)

        // 검색 결과 개수 표시
        output.resultCount
            .drive(resultCountLabel.rx.text)
            .disposed(by: disposeBag)

        // 로딩 상태 처리
        output.isLoading
            .drive(onNext: { [weak self] isLoading in
                // TODO: 로딩 인디케이터 표시/숨김
            })
            .disposed(by: disposeBag)

        // 에러 처리
        output.error
            .filter { !$0.isEmpty }
            .drive(onNext: { [weak self] error in
                // TODO: Toast 메시지로 에러 표시
                print("Error: \(error)")
            })
            .disposed(by: disposeBag)

        // 검색 트리거
        searchBar.textField.rx.controlEvent(.editingDidEndOnExit)
            .bind(to: searchTrigger)
            .disposed(by: disposeBag)

        // 네비게이션 검색 버튼 트리거
        navigationItem.rightBarButtonItem?.rx.tap
            .bind(to: searchTrigger)
            .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .asDriver()
            .withLatestFrom(output.books) { indexPath, items in
                return items[indexPath.item]
            }
            .drive(with: self) { owner, item in
                let detailVC = BookDetailViewController(book: item)
                owner.navigationController?.pushViewController(detailVC, animated: true)
            }
            .disposed(by: disposeBag)

        
            

        
        
        
    }
    
    func configureHierarchy() {
        [searchBar, resultCountLabel, collectionView].forEach {
            view.addSubview($0)
        }
    }

    func configureLayout() {
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }

        resultCountLabel.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(resultCountLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    func configureView() {
        view.backgroundColor = .white
        navigationController?.navigationBar.isHidden = false
    }
    
    
}

