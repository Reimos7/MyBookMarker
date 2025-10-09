//
//  BookDiaryViewController.swift
//  BookMarker
//
//  Created by Reimos on 10/3/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa
import Kingfisher
import IQKeyboardManagerSwift

final class BookDiaryViewController: UIViewController {

    // MARK: - Properties
    private let bookItem: Item
    private let disposeBag = DisposeBag()
    private let bookRepository = BookRepository()

    // 독서 일기 데이터
    private var savedQuotes: [String] = []
    private var savedTags: [String] = []

    // 기존 저장된 데이터 (수정 모드일 때 사용)
    private var existingBook: BookRealmModel?

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.keyboardDismissMode = .onDrag
    }

    private let contentView = UIView()

    // 도서 정보 카드
    private let bookInfoCardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    // 도서 정보 섹션
    private let bookInfoContainer = UIView().then {
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 12
    }

    private let bookCoverImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
    }

    private let bookTitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 2
    }

    private let bookAuthorLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
    }

    private let readingStatusBadge = UILabel().then {
        $0.text = "읽기 완료"
        $0.font = .systemFont(ofSize: 12, weight: .semibold)
        $0.textColor = .white
        $0.backgroundColor = .systemTeal
        $0.textAlignment = .center
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    // 읽기 정보 카드
    private let readingInfoCardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    // 읽기 정보 섹션
    private let readingInfoTitleLabel = UILabel().then {
        $0.text = "읽기 정보"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .label
    }

    // 읽기 상태
    private let readingStatusTitleLabel = UILabel().then {
        $0.text = "읽기 상태"
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .label
    }

    private let readingStatusButton = UIButton().then {
        $0.setTitle("읽는 중", for: .normal)
        $0.setTitleColor(.label, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }

    private let readingCompleteButton = UIButton().then {
        $0.setTitle("읽기 완료", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.backgroundColor = .systemTeal
        $0.layer.cornerRadius = 8
        $0.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
    }

    // 시작일
    private let startDateTitleLabel = UILabel().then {
        $0.text = "시작일"
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .label
    }

    private let startDatePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .compact
        $0.locale = Locale(identifier: "ko_KR")
    }

    // 완료일
    private let endDateTitleLabel = UILabel().then {
        $0.text = "완료일"
        $0.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.textColor = .label
    }

    private let endDatePicker = UIDatePicker().then {
        $0.datePickerMode = .date
        $0.preferredDatePickerStyle = .compact
        $0.locale = Locale(identifier: "ko_KR")
    }

    // 평점 카드
    private let ratingCardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    // 평점
    private let ratingTitleLabel = UILabel().then {
        $0.text = "평점"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .label
    }

    private let starStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.distribution = .fillEqually
    }

    private let ratingLabel = UILabel().then {
        $0.text = "평점 없음"
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .secondaryLabel
    }

    private var starButtons: [UIButton] = []
    private var selectedRating: Int = 0

    // 읽기 상태
    private var isReadingComplete: Bool = true {
        didSet {
            updateReadingStatus()
        }
    }

    // 독서 메모 카드
    private let diaryCardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    // 독서 일기 섹션
    private let diaryTitleLabel = UILabel().then {
        $0.text = "독서 메모"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .label
    }

    private let diaryTextView = UITextView().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .label
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 12
        $0.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        $0.isScrollEnabled = false
    }

    private let diaryPlaceholderLabel = UILabel().then {
        $0.text = "이 책을 읽으면서 느낀 점, 인상 깊었던 부분,\n생각해볼 점 등을 자유롭게 작성해보세요."
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .tertiaryLabel
        $0.numberOfLines = 0
    }

    private let characterCountLabel = UILabel().then {
        $0.text = "0/2000"
        $0.font = .systemFont(ofSize: 12, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .right
    }

    // 인상 깊은 구절 카드
    private let quoteCardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    // 인상 깊은 구절
    private let quoteTitleLabel = UILabel().then {
        $0.text = "인상 깊은 구절"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .label
    }

    private let quoteTextField = UITextField().then {
        $0.placeholder = "기억하고 싶은 구절을 입력하세요"
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .label
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        $0.leftViewMode = .always
    }

    private let addQuoteButton = UIButton().then {
        $0.setTitle("구절 추가", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.backgroundColor = .systemTeal
        $0.layer.cornerRadius = 8
        $0.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }

    // 태그 카드
    private let tagCardView = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.cornerRadius = 16
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.08
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 8
    }

    // 태그
    private let tagTitleLabel = UILabel().then {
        $0.text = "태그"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .label
    }

    private let tagTextField = UITextField().then {
        $0.placeholder = "태그를 입력하세요"
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .label
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 8
        $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        $0.leftViewMode = .always
    }

    private let addTagButton = UIButton().then {
        $0.setTitle("추가", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.backgroundColor = .systemTeal
        $0.layer.cornerRadius = 8
        $0.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
    }

    // MARK: - Init
    init(book: Item) {
        self.bookItem = book
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
        setupStars()
        setupDatePickers()
        loadExistingData() // 기존 데이터 불러오기
        setupBindings()
        configureBookInfo()
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = "독서 기록"
        
        navigationController?.navigationBar.tintColor = .black
        navigationItem.backButtonTitle = ""

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "저장",
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = .systemTeal
    }

    @objc private func saveButtonTapped() {
        // 1. ISBN으로 저장된 도서 찾기
        guard let isbn13 = bookItem.isbn13 else {
            view.makeToast("도서 정보를 찾을 수 없습니다.")
            return
        }

        do {
            // 2. Realm에서 도서 조회
            guard let book = try bookRepository.getBook(byISBN: isbn13) else {
                view.makeToast("저장된 도서를 찾을 수 없습니다.\n먼저 도서를 폴더에 저장해주세요.")
                return
            }

            // 3. 입력값 수집 (빈값이면 기존값 유지)
            let currentDiaryText = diaryTextView.text ?? ""
            let finalDiaryContent: String?
            if currentDiaryText.isEmpty {
                // 입력값이 비어있으면 기존 값 유지
                finalDiaryContent = existingBook?.diaryContent
            } else {
                finalDiaryContent = currentDiaryText
            }

            // 평점: 0이면 기존 값 유지, 아니면 새 값 사용
            let finalRating: Double
            if selectedRating == 0 {
                finalRating = existingBook?.userRating ?? 0
            } else {
                finalRating = Double(selectedRating)
            }

            // 태그: 비어있으면 기존 값 유지
            let finalTags: [String]
            if savedTags.isEmpty {
                if let existingTags = existingBook?.tags {
                    finalTags = Array(existingTags)
                } else {
                    finalTags = []
                }
            } else {
                finalTags = savedTags
            }

            // 구절: 비어있으면 기존 값 유지
            let finalQuotes: [String]
            if savedQuotes.isEmpty {
                if let existingQuotes = existingBook?.quotes {
                    finalQuotes = Array(existingQuotes)
                } else {
                    finalQuotes = []
                }
            } else {
                finalQuotes = savedQuotes
            }

            // "읽는 중" 상태일 때는 완료일을 nil로 설정
            let finalEndDate = isReadingComplete ? endDatePicker.date : nil

            // 4. Repository를 통해 독서 일기 저장
            try bookRepository.updateBookDiary(
                id: book.id,
                isReadingComplete: isReadingComplete,
                startDate: startDatePicker.date,
                endDate: finalEndDate,
                rating: finalRating,
                diaryContent: finalDiaryContent,
                quotes: finalQuotes,
                tags: finalTags
            )

            // 5. 저장 성공 메시지 및 화면 닫기
            view.makeToast("독서 일기가 저장되었습니다.") { [weak self] _ in
                // 디버깅: 저장된 데이터 확인
                self?.bookRepository.printBookDiaryInfo(id: book.id)
                self?.bookRepository.printAllBooksWithDiary()

                self?.navigationController?.popViewController(animated: true)
            }

        } catch {
            view.makeToast("저장 중 오류가 발생했습니다: \(error.localizedDescription)")
            print("[저장 실패] \(error.localizedDescription)")
        }
    }

    private func setupStars() {
        for i in 1...5 {
            let button = UIButton()
            button.setImage(UIImage(systemName: "star"), for: .normal)
            button.setImage(UIImage(systemName: "star.fill"), for: .selected)
            button.tintColor = .systemGray3
            button.tag = i
            button.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            starStackView.addArrangedSubview(button)
            starButtons.append(button)
        }
    }

    @objc private func starTapped(_ sender: UIButton) {
        selectedRating = sender.tag
        updateStars()
        ratingLabel.text = "\(selectedRating)점"
    }

    private func updateStars() {
        for (index, button) in starButtons.enumerated() {
            if index < selectedRating {
                button.isSelected = true
                button.tintColor = .systemOrange
            } else {
                button.isSelected = false
                button.tintColor = .systemGray3
            }
        }
    }

    private func setupDatePickers() {
        // compact 스타일은 직접 뷰에 배치되므로 별도 설정 불필요
        // 기본 날짜를 오늘로 설정
        startDatePicker.date = Date()
        endDatePicker.date = Date()
    }

    private func loadExistingData() {
        guard let isbn13 = bookItem.isbn13 else { return }

        do {
            // Realm에서 기존 저장된 도서 정보 불러오기
            if let book = try bookRepository.getBook(byISBN: isbn13) {
                existingBook = book

                // 기존 데이터가 있으면 UI에 표시
                if let diaryContent = book.diaryContent, !diaryContent.isEmpty {
                    diaryTextView.text = diaryContent
                }

                if book.userRating > 0 {
                    selectedRating = Int(book.userRating)
                    updateStars()
                    ratingLabel.text = "\(selectedRating)점"
                }

                if !book.tags.isEmpty {
                    savedTags = Array(book.tags)
                }

                if !book.quotes.isEmpty {
                    savedQuotes = Array(book.quotes)
                }

                // 읽기 상태
                isReadingComplete = book.isReadingComplete

                // 날짜
                if let startDate = book.startDate {
                    startDatePicker.date = startDate
                }

                if let endDate = book.endDate {
                    endDatePicker.date = endDate
                }
            }
        } catch {
            print("[기존 데이터 로드 실패] \(error.localizedDescription)")
        }
    }

    private func configureBookInfo() {
        bookTitleLabel.text = bookItem.title
        bookAuthorLabel.text = bookItem.author

        if let coverURL = bookItem.cover, let url = URL(string: coverURL) {
            bookCoverImageView.kf.setImage(with: url)
        }
    }

    private func setupBindings() {
        // 텍스트뷰 placeholder 처리
        diaryTextView.rx.text.orEmpty
            .asDriver()
            .drive(with: self) { owner, text in
                owner.diaryPlaceholderLabel.isHidden = !text.isEmpty
                owner.characterCountLabel.text = "\(text.count)/2000"
            }
            .disposed(by: disposeBag)

        // 읽는 중 버튼
        readingStatusButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.isReadingComplete = false
            }
            .disposed(by: disposeBag)

        // 읽기 완료 버튼
        readingCompleteButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.isReadingComplete = true
            }
            .disposed(by: disposeBag)

        // 구절 추가 버튼
        addQuoteButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                guard let quote = owner.quoteTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !quote.isEmpty else {
                    owner.view.makeToast("구절을 입력해주세요")
                    return
                }

                // 중복 체크
                if owner.savedQuotes.contains(quote) {
                    owner.view.makeToast("이미 추가된 구절입니다")
                    return
                }

                owner.savedQuotes.append(quote)
                owner.quoteTextField.text = ""
                owner.view.makeToast("구절이 추가되었습니다 (\(owner.savedQuotes.count)개)")
                
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)

        // 태그 추가 버튼
        addTagButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                guard let tag = owner.tagTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !tag.isEmpty else {
                    owner.view.makeToast("태그를 입력해주세요")
                    return
                }

                // 중복 체크
                if owner.savedTags.contains(tag) {
                    owner.view.makeToast("이미 추가된 태그입니다")
                    return
                }

                owner.savedTags.append(tag)
                owner.tagTextField.text = ""
                owner.view.makeToast("태그가 추가되었습니다 (\(owner.savedTags.count)개)")
                
                owner.view.endEditing(true)
            }
            .disposed(by: disposeBag)
    }

    private func updateReadingStatus() {
        if isReadingComplete {
            // 읽기 완료 상태 - 시작일/완료일 둘 다 표시
            readingStatusButton.backgroundColor = .systemGray6
            readingStatusButton.setTitleColor(.label, for: .normal)
            readingStatusButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)

            readingCompleteButton.backgroundColor = .systemTeal
            readingCompleteButton.setTitleColor(.white, for: .normal)
            readingCompleteButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)

            readingStatusBadge.isHidden = false
            readingStatusBadge.text = "읽기 완료"
            readingStatusBadge.backgroundColor = .systemTeal

            startDateTitleLabel.isHidden = false
            startDatePicker.isHidden = false
            endDateTitleLabel.isHidden = false
            endDatePicker.isHidden = false
        } else {
            // 읽는 중 상태 - 시작일만 표시
            readingStatusButton.backgroundColor = .systemTeal
            readingStatusButton.setTitleColor(.white, for: .normal)
            readingStatusButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)

            readingCompleteButton.backgroundColor = .systemGray6
            readingCompleteButton.setTitleColor(.label, for: .normal)
            readingCompleteButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)

            readingStatusBadge.isHidden = false
            readingStatusBadge.text = "읽는 중"
            readingStatusBadge.backgroundColor = .systemOrange

            startDateTitleLabel.isHidden = false
            startDatePicker.isHidden = false
            endDateTitleLabel.isHidden = true
            endDatePicker.isHidden = true
        }
    }
}

// MARK: - UI Configuration
extension BookDiaryViewController: DesignProtocol {

    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // 카드뷰들을 contentView에 추가
        [bookInfoCardView, readingInfoCardView, ratingCardView,
         diaryCardView, quoteCardView, tagCardView].forEach {
            contentView.addSubview($0)
        }

        // 도서 정보 카드
        bookInfoCardView.addSubview(bookInfoContainer)
        bookInfoContainer.addSubview(bookCoverImageView)
        bookInfoContainer.addSubview(bookTitleLabel)
        bookInfoContainer.addSubview(bookAuthorLabel)
        bookInfoContainer.addSubview(readingStatusBadge)

        // 읽기 정보 카드
        [readingInfoTitleLabel, readingStatusTitleLabel, readingStatusButton,
         readingCompleteButton, startDateTitleLabel, startDatePicker,
         endDateTitleLabel, endDatePicker].forEach {
            readingInfoCardView.addSubview($0)
        }

        // 평점 카드
        [ratingTitleLabel, starStackView, ratingLabel].forEach {
            ratingCardView.addSubview($0)
        }

        // 독서 메모 카드
        diaryTextView.addSubview(diaryPlaceholderLabel)
        [diaryTitleLabel, diaryTextView, characterCountLabel].forEach {
            diaryCardView.addSubview($0)
        }

        // 인상 깊은 구절 카드
        [quoteTitleLabel, quoteTextField, addQuoteButton].forEach {
            quoteCardView.addSubview($0)
        }

        // 태그 카드
        [tagTitleLabel, tagTextField, addTagButton].forEach {
            tagCardView.addSubview($0)
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

        // ===== 도서 정보 카드 =====
        bookInfoCardView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        // 도서 정보 컨테이너
        bookInfoContainer.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
            $0.height.equalTo(120)
        }

        bookCoverImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(70)
            $0.height.equalTo(90)
        }

        bookTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalTo(bookCoverImageView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        bookAuthorLabel.snp.makeConstraints {
            $0.top.equalTo(bookTitleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(bookTitleLabel)
        }

        readingStatusBadge.snp.makeConstraints {
            $0.top.equalTo(bookAuthorLabel.snp.bottom).offset(8)
            $0.leading.equalTo(bookTitleLabel)
            $0.width.equalTo(70)
            $0.height.equalTo(24)
        }

        // ===== 읽기 정보 카드 =====
        readingInfoCardView.snp.makeConstraints {
            $0.top.equalTo(bookInfoCardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        // 읽기 정보
        readingInfoTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        readingStatusTitleLabel.snp.makeConstraints {
            $0.top.equalTo(readingInfoTitleLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(24)
        }

        readingStatusButton.snp.makeConstraints {
            $0.top.equalTo(readingStatusTitleLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(24)
            $0.width.equalTo((UIScreen.main.bounds.width - 88) / 2)
            $0.height.equalTo(44)
        }

        readingCompleteButton.snp.makeConstraints {
            $0.top.equalTo(readingStatusButton)
            $0.trailing.equalToSuperview().offset(-24)
            $0.width.equalTo(readingStatusButton)
            $0.height.equalTo(44)
        }

        // 시작일
        startDateTitleLabel.snp.makeConstraints {
            $0.top.equalTo(readingStatusButton.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(24)
        }

        startDatePicker.snp.makeConstraints {
            $0.top.equalTo(startDateTitleLabel.snp.bottom).offset(8)
            $0.leading.equalTo(startDateTitleLabel)
            $0.trailing.equalTo(readingInfoCardView.snp.centerX).offset(-8)
        }

        // 완료일
        endDateTitleLabel.snp.makeConstraints {
            $0.top.equalTo(startDateTitleLabel)
            $0.leading.equalTo(readingInfoCardView.snp.centerX).offset(8)
        }

        endDatePicker.snp.makeConstraints {
            $0.top.equalTo(endDateTitleLabel.snp.bottom).offset(8)
            $0.leading.equalTo(endDateTitleLabel)
            $0.trailing.equalToSuperview().offset(-24)
            $0.bottom.equalToSuperview().offset(-24)
        }

        // ===== 평점 카드 =====
        ratingCardView.snp.makeConstraints {
            $0.top.equalTo(readingInfoCardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        // 평점
        ratingTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        starStackView.snp.makeConstraints {
            $0.top.equalTo(ratingTitleLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(24)
            $0.height.equalTo(32)
        }

        ratingLabel.snp.makeConstraints {
            $0.centerY.equalTo(starStackView)
            $0.leading.equalTo(starStackView.snp.trailing).offset(12)
            $0.bottom.equalToSuperview().offset(-24)
        }

        // ===== 독서 메모 카드 =====
        diaryCardView.snp.makeConstraints {
            $0.top.equalTo(ratingCardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        // 독서 메모
        diaryTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        diaryTextView.snp.makeConstraints {
            $0.top.equalTo(diaryTitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.greaterThanOrEqualTo(200)
        }

        diaryPlaceholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        characterCountLabel.snp.makeConstraints {
            $0.top.equalTo(diaryTextView.snp.bottom).offset(8)
            $0.trailing.equalToSuperview().offset(-24)
            $0.bottom.equalToSuperview().offset(-24)
        }

        // ===== 인상 깊은 구절 카드 =====
        quoteCardView.snp.makeConstraints {
            $0.top.equalTo(diaryCardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        // 인상 깊은 구절
        quoteTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        quoteTextField.snp.makeConstraints {
            $0.top.equalTo(quoteTitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(44)
        }

        addQuoteButton.snp.makeConstraints {
            $0.top.equalTo(quoteTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview().offset(-24)
        }

        // ===== 태그 카드 =====
        tagCardView.snp.makeConstraints {
            $0.top.equalTo(quoteCardView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(4)
        }

        // 태그
        tagTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        tagTextField.snp.makeConstraints {
            $0.top.equalTo(tagTitleLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(24)
            $0.trailing.equalTo(addTagButton.snp.leading).offset(-12)
            $0.height.equalTo(44)
        }

        addTagButton.snp.makeConstraints {
            $0.centerY.equalTo(tagTextField)
            $0.trailing.equalToSuperview().offset(-24)
            $0.width.equalTo(80)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview().offset(-24)
        }
    }

    func configureView() {
        view.backgroundColor = UIColor.systemGray6
    }
}
