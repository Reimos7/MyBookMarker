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

    // 저장된 구절 표시 StackView
    private let quotesStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
        $0.distribution = .fill
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

    // 저장된 태그 표시 StackView (가로로 Wrap되는 FlowLayout)
    private let tagsContainerView = UIView().then {
        $0.backgroundColor = .clear
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

            // 태그: savedTags를 그대로 사용 (빈 배열도 허용 - 모두 삭제한 경우)
            let finalTags = savedTags

            // 구절: savedQuotes를 그대로 사용 (빈 배열도 허용 - 모두 삭제한 경우)
            let finalQuotes = savedQuotes

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

                // UI 업데이트
                updateQuotesUI()
                updateTagsUI()

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
                owner.updateQuotesUI()  // UI 업데이트 추가
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
                owner.updateTagsUI()  // UI 업데이트 추가
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
        [quoteTitleLabel, quotesStackView, quoteTextField, addQuoteButton].forEach {
            quoteCardView.addSubview($0)
        }

        // 태그 카드
        [tagTitleLabel, tagsContainerView, tagTextField, addTagButton].forEach {
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

        // 저장된 구절 표시 영역
        quotesStackView.snp.makeConstraints {
            $0.top.equalTo(quoteTitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        quoteTextField.snp.makeConstraints {
            $0.top.equalTo(quotesStackView.snp.bottom).offset(12)
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

        // 저장된 태그 표시 영역
        tagsContainerView.snp.makeConstraints {
            $0.top.equalTo(tagTitleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(0)  // 동적으로 업데이트
        }

        tagTextField.snp.makeConstraints {
            $0.top.equalTo(tagsContainerView.snp.bottom).offset(12)
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

    // MARK: - Update UI

    /// 저장된 구절들을 UI에 표시
    private func updateQuotesUI() {
        // 기존 뷰 제거
        quotesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 구절이 없으면 빈 상태 표시
//        guard !savedQuotes.isEmpty else {
//            let emptyLabel = UILabel().then {
//                $0.text = "← 왼쪽으로 스와이프하세요!"
//                $0.font = .systemFont(ofSize: 13, weight: .regular)
//                $0.textColor = .secondaryLabel
//                $0.textAlignment = .left
//            }
//            quotesStackView.addArrangedSubview(emptyLabel)
//            return
//        }

        // 각 구절을 카드로 표시
        for (index, quote) in savedQuotes.enumerated() {
            let quoteView = createQuoteCardView(quote: quote, index: index)
            quotesStackView.addArrangedSubview(quoteView)
        }
    }

    // 구절 카드 뷰 생성 (스와이프로 편집/삭제)
    private func createQuoteCardView(quote: String, index: Int) -> UIView {
        // 최상위 컨테이너 (clipsToBounds로 버튼 숨김)
        let wrapperView = UIView()
        wrapperView.backgroundColor = .clear
        wrapperView.clipsToBounds = true
        wrapperView.layer.cornerRadius = 12

        // 버튼 영역 (배경에 고정)
        let buttonContainer = UIView()
        buttonContainer.backgroundColor = .clear

        // 편집 버튼
        let editButton = UIButton().then {
            $0.setTitle("편집", for: .normal)
            $0.setTitleColor(.white, for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            $0.backgroundColor = .systemBlue
            $0.layer.cornerRadius = 8
            $0.tag = index
        }

        // 삭제 버튼
        let deleteButton = UIButton().then {
            $0.setTitle("삭제", for: .normal)
            $0.setTitleColor(.white, for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            $0.backgroundColor = .systemRed
            $0.layer.cornerRadius = 8
            $0.tag = index
        }

        // 구절 카드 (슬라이드되는 부분)
        let contentView = UIView()
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 12

        // 구절 레이블
        let quoteLabel = UILabel().then {
            $0.text = quote
            $0.font = .systemFont(ofSize: 14, weight: .regular)
            $0.textColor = .label
            $0.numberOfLines = 0
        }

        // 버튼 액션
        editButton.rx.tap
            .subscribe(with: self, onNext: { owner, _ in
                owner.editQuote(at: index)
            })
            .disposed(by: disposeBag)

        deleteButton.rx.tap
            .subscribe(with: self, onNext: { owner, _ in
                owner.deleteQuote(at: index)
            })
            .disposed(by: disposeBag)

        // 스와이프 제스처
        let swipeGesture = UIPanGestureRecognizer()
        swipeGesture.rx.event
            .subscribe(with: self, onNext: { owner, gesture in
                owner.handleQuoteSwipe(gesture, contentView: contentView)
            })
            .disposed(by: disposeBag)
        contentView.addGestureRecognizer(swipeGesture)

        // 계층 구조
        wrapperView.addSubview(buttonContainer)
        buttonContainer.addSubview(editButton)
        buttonContainer.addSubview(deleteButton)
        wrapperView.addSubview(contentView)
        contentView.addSubview(quoteLabel)

        // 레이아웃
        buttonContainer.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        editButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-8)
            $0.width.equalTo(70)
            $0.height.equalTo(40)
        }

        deleteButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(editButton.snp.leading).offset(-8)
            $0.width.equalTo(70)
            $0.height.equalTo(40)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        quoteLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview().inset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
        }

        wrapperView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(60)
        }

        return wrapperView
    }

    // 스와이프 제스처 처리
    private func handleQuoteSwipe(_ gesture: UIPanGestureRecognizer, contentView: UIView) {
        let translation = gesture.translation(in: contentView)

        switch gesture.state {
        case .changed:
            // 왼쪽으로만 스와이프 허용
            if translation.x < 0 {
                let offset = max(translation.x, -156)  // 최대 156 (버튼 2개 + 간격)
                contentView.transform = CGAffineTransform(translationX: offset, y: 0)
            }

        case .ended:
            if translation.x < -50 {
                // 버튼 표시 (왼쪽으로 156만큼 이동)
                UIView.animate(withDuration: 0.3) {
                    contentView.transform = CGAffineTransform(translationX: -156, y: 0)
                }
            } else {
                // 원위치
                UIView.animate(withDuration: 0.3) {
                    contentView.transform = .identity
                }
            }

        default:
            break
        }
    }

    // 구절 편집
    private func editQuote(at index: Int) {
        let alert = UIAlertController(title: "구절 편집", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = self.savedQuotes[index]
        }

        let saveAction = UIAlertAction(title: "저장", style: .default) { [weak self] _ in
            guard let self = self,
                  let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { return }

            self.savedQuotes[index] = text
            self.updateQuotesUI()
            self.view.makeToast("구절이 수정되었습니다")
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(saveAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    // 구절 삭제
    private func deleteQuote(at index: Int) {
        let quoteToDelete = savedQuotes[index] // 삭제할 구절 미리 가져오기
        
        // [수정] 확인 Alert 생성
        let alert = UIAlertController(title: "구절 삭제", message: "이 구절을 삭제하시겠습니까?\n\"\(quoteToDelete)\"", preferredStyle: .alert)
        
        // 삭제 확인 액션
        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // [추가/이동] 실제 삭제 로직
            self.savedQuotes.remove(at: index)
            self.updateQuotesUI()
            self.view.makeToast("구절이 삭제되었습니다 (\(self.savedQuotes.count)개)")
        }
        
        // 취소 액션
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { [weak self] _ in
            // 취소 시 스와이프 상태 복원
            self?.updateQuotesUI()
        }
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

    // 저장된 태그들을 UI에 표시
    private func updateTagsUI() {
        // 기존 뷰 제거
        tagsContainerView.subviews.forEach { $0.removeFromSuperview() }

        guard !savedTags.isEmpty else { return }

        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        let spacing: CGFloat = 8
        let maxWidth = UIScreen.main.bounds.width - 72  // 좌우 여백 고려

        for (index, tag) in savedTags.enumerated() {
            let tagButton = createTagButton(tag: tag, index: index)
            tagsContainerView.addSubview(tagButton)

            let tagWidth = tagButton.intrinsicContentSize.width

            // 다음 줄로 넘어가야 하는지 체크
            if xOffset + tagWidth > maxWidth && xOffset > 0 {
                xOffset = 0
                yOffset += 36 + spacing
            }

            tagButton.frame = CGRect(x: xOffset, y: yOffset, width: tagWidth, height: 36)
            xOffset += tagWidth + spacing
        }

        // Container 높이 업데이트
        tagsContainerView.snp.updateConstraints {
            $0.height.equalTo(yOffset + 36)
        }
    }

    // 태그 버튼 생성 (롱프레스로 삭제)
    private func createTagButton(tag: String, index: Int) -> UIButton {
        let button = UIButton().then {
            $0.setTitle("#\(tag)", for: .normal)
            $0.setTitleColor(.systemBlue, for: .normal)
            $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            $0.backgroundColor = .systemGray6
            $0.layer.cornerRadius = 18
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.systemBlue.cgColor
            $0.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            $0.tag = index
        }

        // 롱프레스 제스처
        let longPress = UILongPressGestureRecognizer()
        longPress.rx.event
            .filter { $0.state == .began }
            .subscribe(with: self, onNext: { owner, _ in
                owner.deleteTag(at: index)
            })
            .disposed(by: disposeBag)
        button.addGestureRecognizer(longPress)

        return button
    }

    // 태그 삭제
    private func deleteTag(at index: Int) {
        let alert = UIAlertController(title: "태그 삭제", message: "'\(savedTags[index])' 태그를 삭제하시겠습니까?", preferredStyle: .alert)

        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.savedTags.remove(at: index)
            self.updateTagsUI()
            self.view.makeToast("태그가 삭제되었습니다 (\(self.savedTags.count)개)")
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }
}
