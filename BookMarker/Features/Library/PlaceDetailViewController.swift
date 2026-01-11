//
//  PlaceDetailViewController.swift
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
import Kingfisher

final class PlaceDetailViewController: UIViewController {

    // MARK: - Properties
    private let place: PlaceRealmModel
    private let viewModel: PlaceDetailViewModel
    private let disposeBag = DisposeBag()
    private let refreshTrigger = PublishSubject<Void>()
    private let addBookTrigger = PublishSubject<Void>()
    private let placeRepository = PlaceRepository()
    private let imageManager = ImageManager.shared
    private let bookRepository = BookRepository()

    // 삭제 모드 관련
    private var deleteModeCellIndexPath: IndexPath?

    // MARK: - UI Components
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView()

    // 장소 이미지
    private let placeImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
        $0.isUserInteractionEnabled = true  // 탭 제스처를 위해 활성화
    }

    // 장소 정보 컨테이너
    private let infoContainerView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    private let nameLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 24, weight: .bold)
        $0.textColor = .label
        $0.numberOfLines = 2
    }

    private let addressLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 2
    }

    private let ratingStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 4
        $0.alignment = .center
    }

    private let descriptionLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .label
        $0.numberOfLines = 0
    }

    // 책 섹션
    private let booksSectionHeaderView = UIView().then {
        $0.backgroundColor = .systemBackground
    }

    private let booksSectionTitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textColor = .label
    }

    // 책 컬렉션뷰
    private let booksCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 140, height: 220)
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(NewBookCell.self, forCellWithReuseIdentifier: NewBookCell.reuseIdentifier)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    private let emptyBookLabel = UILabel().then {
        $0.text = "이 장소에서 읽은 책이 없습니다"
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.textAlignment = .center
        $0.isHidden = true
    }

    private let addBookButton = UIButton().then {
        var config = UIButton.Configuration.filled()
        config.title = "책 추가하기"
        config.image = UIImage(systemName: "plus.circle.fill")
        config.imagePadding = 8
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        $0.configuration = config
    }

    // MARK: - Init
    init(place: PlaceRealmModel) {
        self.place = place
        self.viewModel = PlaceDetailViewModel(place: place)
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
        setupImageTapGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refreshTrigger.onNext(())
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        title = "장소 상세"
        navigationController?.navigationBar.tintColor = .black
        navigationItem.backButtonTitle = ""
    }

    private func configurePlaceInfo() {
        // 장소명
        nameLabel.text = place.name

        // 주소
        if let address = place.address {
            addressLabel.text = "📍 \(address)"
            addressLabel.isHidden = false
        } else {
            addressLabel.isHidden = true
        }

        // 평점
        configureRatingView()

        // 설명
        if let description = place.placeDescription, !description.isEmpty {
            descriptionLabel.text = "\"\(description)\""
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }

        // 장소 이미지
        loadPlaceImage()
    }

    private func configureRatingView() {
        // 기존 별 제거
        ratingStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let rating = place.userRating
        let fullStars = Int(rating)
        let hasHalfStar = rating - Double(fullStars) >= 0.5

        // 꽉 찬 별
        for _ in 0..<fullStars {
            let starImageView = UIImageView(image: UIImage(systemName: "star.fill"))
            starImageView.tintColor = .systemYellow
            starImageView.snp.makeConstraints { $0.size.equalTo(16) }
            ratingStackView.addArrangedSubview(starImageView)
        }

        // 반 별
        if hasHalfStar {
            let starImageView = UIImageView(image: UIImage(systemName: "star.leadinghalf.filled"))
            starImageView.tintColor = .systemYellow
            starImageView.snp.makeConstraints { $0.size.equalTo(16) }
            ratingStackView.addArrangedSubview(starImageView)
        }

        // 빈 별
        let emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0)
        for _ in 0..<emptyStars {
            let starImageView = UIImageView(image: UIImage(systemName: "star"))
            starImageView.tintColor = .systemGray4
            starImageView.snp.makeConstraints { $0.size.equalTo(16) }
            ratingStackView.addArrangedSubview(starImageView)
        }

        // 평점 숫자 레이블
        let ratingLabel = UILabel().then {
            $0.text = String(format: "(%.1f)", rating)
            $0.font = .systemFont(ofSize: 14, weight: .medium)
            $0.textColor = .secondaryLabel
        }
        ratingStackView.addArrangedSubview(ratingLabel)

        ratingStackView.isHidden = rating == 0
    }
}

// MARK: - DesignProtocol
extension PlaceDetailViewController: DesignProtocol {
    func configureHierarchy() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [placeImageView, infoContainerView, booksSectionHeaderView, booksCollectionView, emptyBookLabel, addBookButton].forEach {
            contentView.addSubview($0)
        }

        [nameLabel, addressLabel, ratingStackView, descriptionLabel].forEach {
            infoContainerView.addSubview($0)
        }

        booksSectionHeaderView.addSubview(booksSectionTitleLabel)
    }

    func configureLayout() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        placeImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(280)
        }

        infoContainerView.snp.makeConstraints {
            $0.top.equalTo(placeImageView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        addressLabel.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }

        ratingStackView.snp.makeConstraints {
            $0.top.equalTo(addressLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }

        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(ratingStackView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-20)
        }

        booksSectionHeaderView.snp.makeConstraints {
            $0.top.equalTo(infoContainerView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(50)
        }

        booksSectionTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        booksCollectionView.snp.makeConstraints {
            $0.top.equalTo(booksSectionHeaderView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(220)
        }

        emptyBookLabel.snp.makeConstraints {
            $0.top.equalTo(booksSectionHeaderView.snp.bottom).offset(40)
            $0.centerX.equalToSuperview()
        }

        addBookButton.snp.makeConstraints {
            $0.top.equalTo(booksCollectionView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(50)
            $0.bottom.equalToSuperview().offset(-20)
        }
    }

    func configureView() {
        view.backgroundColor = .systemBackground
        configurePlaceInfo()
    }

    private func setupBindings() {
        let input = PlaceDetailViewModel.Input(
            refreshTrigger: refreshTrigger.asObservable(),
            addBookTrigger: addBookButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input)

        // 책 목록 바인딩
        output.books
            .drive(booksCollectionView.rx.items(
                cellIdentifier: NewBookCell.reuseIdentifier,
                cellType: NewBookCell.self
            )) { [weak self] (index, book, cell) in
                cell.configure(with: book)

                // 삭제 버튼 콜백 설정
                cell.onDeleteButtonTapped = { [weak self] in
                    self?.handleBookDelete(book: book, indexPath: IndexPath(item: index, section: 0))
                }
            }
            .disposed(by: disposeBag)

        // 책 개수 업데이트
        output.bookCount
            .drive(with: self) { owner, count in
                owner.booksSectionTitleLabel.text = "📚 여기서 읽은 책 (\(count))"
                owner.emptyBookLabel.isHidden = count > 0
                owner.booksCollectionView.isHidden = count == 0
            }
            .disposed(by: disposeBag)

        // 책 선택 이벤트
        booksCollectionView.rx.modelSelected(Item.self)
            .bind(with: self) { owner, book in
                // 삭제 모드가 활성화되어 있으면 선택 무시
                guard owner.deleteModeCellIndexPath == nil else { return }
                owner.handleBookSelection(book: book)
            }
            .disposed(by: disposeBag)

        // 책 추가 버튼
        output.showBookSelector
            .drive(with: self) { owner, _ in
                owner.showBookSelectorAlert()
            }
            .disposed(by: disposeBag)

        // 롱프레스 제스처 추가
        setupLongPressGesture()

        // 탭 제스처 추가 (빈 공간 탭으로 삭제 모드 해제)
        setupTapGesture()
    }

    // MARK: - Gesture Setup

    /// 롱프레스 제스처 설정 (책 삭제 모드 진입)
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        booksCollectionView.addGestureRecognizer(longPressGesture)
    }

    /// 탭 제스처 설정 (빈 공간 탭으로 삭제 모드 해제)
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnEmptySpace(_:)))
        tapGesture.cancelsTouchesInView = false
        booksCollectionView.addGestureRecognizer(tapGesture)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: booksCollectionView)
        guard let indexPath = booksCollectionView.indexPathForItem(at: point),
              let cell = booksCollectionView.cellForItem(at: indexPath) as? NewBookCell else {
            return
        }

        // 기존 삭제 모드 해제
        dismissDeleteMode()

        // 새로운 셀에 삭제 모드 활성화
        deleteModeCellIndexPath = indexPath
        cell.showDeleteMode()
    }

    @objc private func handleTapOnEmptySpace(_ gesture: UITapGestureRecognizer) {
        // 삭제 모드가 활성화되어 있지 않으면 무시
        guard deleteModeCellIndexPath != nil else { return }

        let point = gesture.location(in: booksCollectionView)

        // 탭한 위치에 셀이 있는지 확인
        if let indexPath = booksCollectionView.indexPathForItem(at: point),
           let cell = booksCollectionView.cellForItem(at: indexPath) as? NewBookCell,
           cell.isDeleteModeActive {
            // 삭제 모드가 활성화된 셀을 탭한 경우 무시 (삭제 버튼이 처리)
            return
        }

        // 빈 공간이나 다른 셀을 탭한 경우 삭제 모드 해제
        dismissDeleteMode()
    }

    /// 삭제 모드 해제
    private func dismissDeleteMode() {
        guard let indexPath = deleteModeCellIndexPath,
              let cell = booksCollectionView.cellForItem(at: indexPath) as? NewBookCell else {
            deleteModeCellIndexPath = nil
            return
        }

        cell.hideDeleteMode()
        deleteModeCellIndexPath = nil
    }

    // MARK: - Book Deletion

    /// 책 삭제 처리 (알림창 표시)
    private func handleBookDelete(book: Item, indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "장소에서 제거",
            message: "이 장소에서 제거하시겠습니까?",
            preferredStyle: .alert
        )

        let confirmAction = UIAlertAction(title: "제거", style: .destructive) { [weak self] _ in
            self?.removeBookFromPlace(book: book)
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(confirmAction)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    /// 책의 placeId를 nil로 설정하여 장소에서 제거
    private func removeBookFromPlace(book: Item) {
        guard let isbn13 = book.isbn13 else {
            print("DEBUG: ISBN13이 없어서 제거 불가")
            return
        }

        do {
            // ISBN으로 책 찾기
            if let savedBook = try bookRepository.getBook(byISBN: isbn13) {
                // placeId를 nil로 설정
                try bookRepository.updateBookPlaceId(id: savedBook.id, placeId: nil)

                print("DEBUG: 책 장소 제거 성공")

                // 삭제 모드 해제
                dismissDeleteMode()

                // 책 목록 새로고침
                refreshTrigger.onNext(())
            }
        } catch {
            print("DEBUG: 책 제거 실패: \(error)")
        }
    }

    // MARK: - Helper Methods
    private func showBookSelectorAlert() {
        print("DEBUG: showBookSelectorAlert 호출됨")
        let placeId = place.id.stringValue
        print("DEBUG: placeId = \(placeId)")

        let bookSelectorVC = PlaceBookSelectorViewController(placeId: placeId) { [weak self] in
            print("DEBUG: 책 선택 완료 콜백")
            // 책이 추가되면 목록 새로고침
            self?.refreshTrigger.onNext(())
        }

        print("DEBUG: PlaceBookSelectorViewController 생성 완료")
        let navController = UINavigationController(rootViewController: bookSelectorVC)
        print("DEBUG: present 직전")
        present(navController, animated: true) {
            print("DEBUG: present 완료")
        }
    }

    /// 책 선택 처리: 독서 일기 유무에 따라 다른 화면으로 이동
    private func handleBookSelection(book: Item) {
        print("DEBUG: handleBookSelection 호출 - \(book.title)")

        // ISBN13으로 Realm에서 책 찾기
        guard let isbn13 = book.isbn13 else {
            print("DEBUG: ISBN13이 없음")
            return
        }

        do {
            let bookRepository = BookRepository()

            // Realm에서 책 조회
            if let savedBook = try bookRepository.getBook(byISBN: isbn13) {
                print("DEBUG: Realm에서 책 찾음 - hasDiary: \(savedBook.hasDiary)")

                // 독서 일기가 있으면 → BookReviewViewController (독서 카드 보기)
                if savedBook.hasDiary {
                    print("DEBUG: BookReviewViewController로 이동")
                    let reviewVC = BookReviewViewController(bookId: savedBook.id)
                    navigationController?.pushViewController(reviewVC, animated: true)
                } else {
                    // 독서 일기가 없으면 → BookDiaryViewController (독서 일기 작성)
                    print("DEBUG: BookDiaryViewController로 이동")
                    let diaryVC = BookDiaryViewController(book: book)
                    navigationController?.pushViewController(diaryVC, animated: true)
                }
            } else {
                print("DEBUG: Realm에 책이 없음 - BookDiaryViewController로 이동")
                // Realm에 책이 없으면 독서 일기 작성 화면으로
                let diaryVC = BookDiaryViewController(book: book)
                navigationController?.pushViewController(diaryVC, animated: true)
            }
        } catch {
            print("DEBUG: 책 조회 실패 - \(error)")
            // 에러 발생 시 독서 일기 작성 화면으로
            let diaryVC = BookDiaryViewController(book: book)
            navigationController?.pushViewController(diaryVC, animated: true)
        }
    }

    // MARK: - Image Management

    /// 장소 이미지 로드 (웹 URL vs 로컬 파일 구분)
    private func loadPlaceImage() {
        print("DEBUG: loadPlaceImage() 호출됨")

        // 이미지 초기화 (기존 이미지 제거)
        placeImageView.image = nil
        placeImageView.kf.cancelDownloadTask()

        guard let imageURL = place.imageURL, !imageURL.isEmpty else {
            // 이미지 URL이 없으면 기본 아이콘 표시
            print("DEBUG: imageURL이 nil 또는 비어있음")
            placeImageView.image = UIImage(systemName: "photo")
            placeImageView.tintColor = .systemGray4
            return
        }

        print("DEBUG: imageURL = '\(imageURL)'")

        // 웹 URL 확인 (http:// 또는 https://로 시작)
        if imageURL.hasPrefix("http://") || imageURL.hasPrefix("https://") {
            print("DEBUG: 웹 URL로 인식 - Kingfisher 사용")
            // 웹 URL → Kingfisher로 로드
            if let url = URL(string: imageURL) {
                placeImageView.kf.setImage(
                    with: url,
                    placeholder: UIImage(systemName: "photo"),
                    options: [.transition(.fade(0.3))]
                )
            } else {
                // URL 변환 실패
                print("DEBUG: URL 변환 실패")
                placeImageView.image = UIImage(systemName: "photo")
                placeImageView.tintColor = .systemGray4
            }
        } else {
            print("DEBUG: 로컬 파일로 인식 - ImageManager 사용")
            // 로컬 파일 → ImageManager로 로드
            if let image = imageManager.loadImage(fileName: imageURL) {
                print("DEBUG: 로컬 이미지 로드 성공")
                placeImageView.image = image
                placeImageView.tintColor = nil  // tintColor 제거
            } else {
                // 로컬 파일이 없으면 기본 아이콘
                print("DEBUG: 로컬 파일을 찾을 수 없음: \(imageURL)")
                placeImageView.image = UIImage(systemName: "photo")
                placeImageView.tintColor = .systemGray4
            }
        }
    }

    /// 이미지뷰에 탭 제스처 추가
    private func setupImageTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped))
        placeImageView.addGestureRecognizer(tapGesture)
    }

    /// 이미지뷰 탭 시 액션시트 표시
    @objc private func imageViewTapped() {
        let hasImage = place.imageURL != nil && !place.imageURL!.isEmpty

        let alert = UIAlertController(
            title: "장소 사진",
            message: "사진을 선택해주세요",
            preferredStyle: .actionSheet
        )

        // 카메라로 촬영
        let cameraAction = UIAlertAction(title: "카메라", style: .default) { [weak self] _ in
            self?.openCamera()
        }
        alert.addAction(cameraAction)

        // 갤러리에서 선택
        let galleryAction = UIAlertAction(title: "앨범에서 선택", style: .default) { [weak self] _ in
            self?.openGallery()
        }
        alert.addAction(galleryAction)

        // 이미지 삭제 (이미 이미지가 있을 때만 표시)
        if hasImage {
            let deleteAction = UIAlertAction(title: "이미지 삭제", style: .destructive) { [weak self] _ in
                self?.deleteImage()
            }
            alert.addAction(deleteAction)
        }

        // 취소
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(cancelAction)

        // iPad 지원 (UIAlertController는 iPad에서 popover로 표시)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = placeImageView
            popoverController.sourceRect = placeImageView.bounds
        }

        present(alert, animated: true)
    }

    /// 카메라 열기
    private func openCamera() {
        // 카메라 사용 가능 여부 확인
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("카메라를 사용할 수 없습니다")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true  // 이미지 편집 허용
        present(picker, animated: true)
    }

    /// 갤러리 열기
    private func openGallery() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("갤러리를 사용할 수 없습니다")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true  // 이미지 편집 허용
        present(picker, animated: true)
    }

    /// 이미지 삭제
    private func deleteImage() {
        guard let imageURL = place.imageURL else { return }

        // 로컬 파일이면 파일 삭제
        if !imageURL.hasPrefix("http") {
            imageManager.deleteImage(fileName: imageURL)
        }

        // Realm에서 imageURL 제거
        do {
            try placeRepository.updatePlaceImage(placeId: place.id, imageURL: nil)

            // UI 업데이트
            placeImageView.image = UIImage(systemName: "photo")
            placeImageView.tintColor = .systemGray4

            print("이미지 삭제 완료")
        } catch {
            print("이미지 삭제 실패: \(error)")
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension PlaceDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 편집된 이미지 또는 원본 이미지 가져오기
        let selectedImage: UIImage?
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
        } else {
            selectedImage = nil
        }

        picker.dismiss(animated: true) { [weak self] in
            guard let self = self, let image = selectedImage else { return }

            // 이미지 저장
            self.saveSelectedImage(image)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    /// 선택한 이미지 저장 및 Realm 업데이트
    private func saveSelectedImage(_ image: UIImage) {
        let placeId = place.id.stringValue

        // 1. ImageManager로 이미지 저장
        guard let fileName = imageManager.saveImage(image, identifier: placeId) else {
            print("이미지 저장 실패")
            return
        }

        // 2. Realm에 파일명 저장
        do {
            try placeRepository.updatePlaceImage(placeId: place.id, imageURL: fileName)

            // 3. UI 업데이트
            placeImageView.image = image

            print("이미지 저장 및 업데이트 완료: \(fileName)")
        } catch {
            print("Realm 업데이트 실패: \(error)")
            // 실패 시 저장한 이미지 파일 삭제
            imageManager.deleteImage(fileName: fileName)
        }
    }
}
