//
//  PlaceBookSelectorViewController.swift
//  BookMarker
//
//  Created by Claude on 10/24/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa
import Kingfisher
import Toast

/// 장소에 책을 추가하기 위한 책 선택 화면
final class PlaceBookSelectorViewController: UIViewController {

    // MARK: - Properties
    private let placeId: String
    private let onBookSelected: () -> Void
    private let bookRepository = BookRepository()
    private let disposeBag = DisposeBag()

    // 책과 해당 폴더명을 함께 저장하는 데이터 모델
    private var bookItems: [(book: BookRealmModel, folderNames: String)] = []

    // MARK: - UI Components
    private let tableView = UITableView().then {
        $0.register(PlaceBookSelectorCell.self, forCellReuseIdentifier: PlaceBookSelectorCell.reuseIdentifier)
        $0.rowHeight = 90
        $0.separatorStyle = .singleLine
        $0.backgroundColor = .systemBackground
    }

    private let emptyLabel = UILabel().then {
        $0.text = "내 서재에 저장된 책이 없습니다"
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.isHidden = true
    }

    // MARK: - Init
    init(placeId: String, onBookSelected: @escaping () -> Void) {
        self.placeId = placeId
        self.onBookSelected = onBookSelected
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DEBUG: PlaceBookSelectorViewController viewDidLoad")
        setupNavigationBar()
        configureHierarchy()
        configureLayout()
        configureView()
        setupBindings()
        loadBooks()
        print("DEBUG: PlaceBookSelectorViewController viewDidLoad 완료")
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = "책 선택"
        navigationController?.navigationBar.prefersLargeTitles = false

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "취소",
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
    }

    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    private func loadBooks() {
        print("DEBUG: loadBooks 시작")
        do {
            // 모든 책 가져오기
            let allBooks = try bookRepository.getAllBooks()
            print("DEBUG: 전체 책 개수 = \(allBooks.count)")

            // 책과 폴더명 매핑
            bookItems = allBooks.map { book in
                let folderNames = Array(book.folders)
                    .map { $0.name ?? "" }
                    .joined(separator: ", ")
                print("DEBUG: 책 = \(book.title), 폴더 = \(folderNames)")
                return (book: book, folderNames: folderNames.isEmpty ? "폴더 없음" : folderNames)
            }

            print("DEBUG: bookItems 개수 = \(bookItems.count)")
            print("DEBUG: emptyLabel.isHidden = \(!bookItems.isEmpty)")
            print("DEBUG: tableView.isHidden = \(bookItems.isEmpty)")

            emptyLabel.isHidden = !bookItems.isEmpty
            tableView.isHidden = bookItems.isEmpty
            tableView.reloadData()

            print("DEBUG: tableView frame = \(tableView.frame)")
            print("DEBUG: tableView numberOfRows = \(tableView.numberOfRows(inSection: 0))")
        } catch {
            print("DEBUG: 책 목록 로드 실패: \(error)")
        }
    }
}

// MARK: - DesignProtocol
extension PlaceBookSelectorViewController: DesignProtocol {
    func configureHierarchy() {
        [tableView, emptyLabel].forEach {
            view.addSubview($0)
        }
    }

    func configureLayout() {
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    func configureView() {
        view.backgroundColor = .systemBackground
    }

    func setupBindings() {
        // TableView Delegate/DataSource 설정
        tableView.delegate = self
        tableView.dataSource = self
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension PlaceBookSelectorViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("DEBUG: numberOfRowsInSection = \(bookItems.count)")
        return bookItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("DEBUG: cellForRowAt \(indexPath.row)")
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PlaceBookSelectorCell.reuseIdentifier,
            for: indexPath
        ) as? PlaceBookSelectorCell else {
            return UITableViewCell()
        }

        let item = bookItems[indexPath.row]
        cell.configure(book: item.book, folderNames: item.folderNames)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("DEBUG: didSelectRowAt \(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedItem = bookItems[indexPath.row]

        // 책의 placeId 업데이트
        do {
            try bookRepository.updateBookPlaceId(
                id: selectedItem.book.id,
                placeId: placeId
            )

            print("DEBUG: 책 장소 연결 성공")

            // dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.onBookSelected()
                self?.dismiss(animated: true)
            }
        } catch {
            print("DEBUG: 책 장소 연결 실패: \(error)")
        }
    }
}

// MARK: - PlaceBookSelectorCell
final class PlaceBookSelectorCell: UITableViewCell {
    // ReusableProtocol 사용

    // MARK: - UI Components
    private let bookImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 6
        $0.backgroundColor = .systemGray6
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .label
        $0.numberOfLines = 2
    }

    private let folderLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .systemBlue
        $0.numberOfLines = 1
    }

    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        [bookImageView, titleLabel, folderLabel].forEach {
            contentView.addSubview($0)
        }

        bookImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(50)
            $0.height.equalTo(70)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(bookImageView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(16)
        }

        folderLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
    }

    // MARK: - Configure
    func configure(book: BookRealmModel, folderNames: String) {
        titleLabel.text = book.title
        folderLabel.text = "📁 \(folderNames)"

        if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
            bookImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "book.closed"),
                options: [.transition(.fade(0.2))]
            )
        } else {
            bookImageView.image = UIImage(systemName: "book.closed")
            bookImageView.tintColor = .systemGray3
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bookImageView.kf.cancelDownloadTask()
        bookImageView.image = nil
        titleLabel.text = nil
        folderLabel.text = nil
    }
}
