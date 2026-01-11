//
//  BookSelectorViewController.swift
//  BookMarker
//
//  Created by Reimos on 10/20/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa
import RealmSwift

final class BookSelectorViewController: UIViewController {

    // MARK: - Properties
    private let placeId: String
    private let onBookSelected: (ObjectId) -> Void
    private let bookRepository = BookRepository()
    private let disposeBag = DisposeBag()

    private var books: [BookRealmModel] = []

    // MARK: - UI Components
    private let tableView = UITableView().then {
        $0.register(BookSelectorCell.self, forCellReuseIdentifier: BookSelectorCell.reuseIdentifier)
        $0.rowHeight = 80
        $0.separatorStyle = .singleLine
    }

    private let emptyLabel = UILabel().then {
        $0.text = "내 서재에 저장된 책이 없습니다"
        $0.font = .systemFont(ofSize: 16, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.isHidden = true
    }

    // MARK: - Init
    init(placeId: String, onBookSelected: @escaping (ObjectId) -> Void) {
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
        setupNavigationBar()
        configureHierarchy()
        configureLayout()
        configureView()
        setupBindings()
        loadBooks()
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = "책 선택"
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
        do {
            // 모든 책 가져오기 (이미 이 장소에 연결된 책은 제외)
            let allBooks = try bookRepository.getAllBooks()
            books = allBooks.filter { $0.placeId != placeId }

            emptyLabel.isHidden = !books.isEmpty
            tableView.isHidden = books.isEmpty
            tableView.reloadData()
        } catch {
            print("책 목록 로드 실패: \(error)")
        }
    }
}

// MARK: - DesignProtocol
extension BookSelectorViewController: DesignProtocol {
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

    private func setupBindings() {
        // 셀 선택 이벤트
        tableView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
                let selectedBook = owner.books[indexPath.row]

                // 책의 placeId 업데이트
                do {
                    try owner.bookRepository.updateBookPlaceId(id: selectedBook.id, placeId: owner.placeId)
                    owner.onBookSelected(selectedBook.id)
                    owner.dismiss(animated: true)
                } catch {
                    print("책 장소 연결 실패: \(error)")
                    owner.view.makeToast("책을 추가하는데 실패했습니다.")
                }
            }
            .disposed(by: disposeBag)

        // 데이터 바인딩
        Observable.just(books)
            .bind(to: tableView.rx.items(
                cellIdentifier: BookSelectorCell.reuseIdentifier,
                cellType: BookSelectorCell.self
            )) { (index, book, cell) in
                cell.configure(with: book)
            }
            .disposed(by: disposeBag)
    }
}

// MARK: - BookSelectorCell
final class BookSelectorCell: UITableViewCell {
    //static let reuseIdentifier = "BookSelectorCell"

    private let bookImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 4
        $0.backgroundColor = .systemGray6
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .label
        $0.numberOfLines = 2
    }

    private let authorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 1
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        [bookImageView, titleLabel, authorLabel].forEach {
            contentView.addSubview($0)
        }

        bookImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(45)
            $0.height.equalTo(65)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(bookImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalToSuperview().offset(12)
        }

        authorLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
    }

    func configure(with book: BookRealmModel) {
        titleLabel.text = book.title
        authorLabel.text = book.cleanAuthorName

        if let coverURL = book.coverImageURL, let url = URL(string: coverURL) {
            bookImageView.kf.setImage(
                with: url,
                placeholder: UIImage(systemName: "book.closed"),
                options: [.transition(.fade(0.3))]
            )
        } else {
            bookImageView.image = UIImage(systemName: "book.closed")
            bookImageView.tintColor = .systemGray4
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bookImageView.kf.cancelDownloadTask()
        bookImageView.image = nil
        titleLabel.text = nil
        authorLabel.text = nil
    }
}
