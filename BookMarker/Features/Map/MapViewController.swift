//
//  MapViewController.swift
//  BookMarker
//
//  Created by Reimos on 10/5/25.
//

import UIKit
import MapKit
import SnapKit
import Then
import RxSwift
import RxCocoa
import SafariServices

final class MapViewController: UIViewController {

    // 장소를 핀으로 표시
    private let mapView = MKMapView().then {
        $0.showsUserLocation = true      // 현재 위치 파란 점 표시
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    // 현재 위치로 이동 버튼
    private let currentLocationButton = UIButton().then {
        $0.setImage(UIImage(systemName: "location.fill"), for: .normal)
        $0.tintColor = .darkGray
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 8
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowOffset = CGSize(width: 0, height: 2)
        $0.layer.shadowRadius = 4
    }

    // 카테고리 필터 버튼을 담는 스택뷰
    private let filterStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.distribution = .fillProportionally
    }

    // 전체 필터 버튼
    private let allFilterButton = UIButton().then {
        $0.setTitle("전체", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = UIColor.systemTeal
        $0.layer.cornerRadius = 20
        $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        $0.tag = 0  // 태그로 카테고리 구분 (0은 전체)
    }

    // 카페 필터 버튼
    private let cafeFilterButton = UIButton().then {
        $0.setTitle("카페", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.setTitleColor(.darkGray, for: .normal)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        $0.tag = 1  // 태그로 카테고리 구분
    }

    // 도서관 필터 버튼
    private let libraryFilterButton = UIButton().then {
        $0.setTitle("도서관", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.setTitleColor(.darkGray, for: .normal)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        $0.tag = 2
    }

    // 스터디카페 필터 버튼
    private let studyCafeFilterButton = UIButton().then {
        $0.setTitle("스터디카페", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.setTitleColor(.darkGray, for: .normal)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        $0.tag = 3
    }

    // 장소 목록 컬렉션뷰
    private lazy var placeCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0

        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGray6
        collectionView.register(MapPlaceCell.self, forCellWithReuseIdentifier: MapPlaceCell.reuseIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    // 로딩 인디케이터
    private let activityIndicator = UIActivityIndicatorView(style: .large).then {
        $0.color = .systemTeal
        $0.hidesWhenStopped = true
    }

    private let viewModel = MapViewModel()

    private let disposeBag = DisposeBag()

    private let categorySelectedSubject = PublishSubject<KakaoPlaceCategory>()
    private let pinSelectedSubject = PublishSubject<String>()  // 핀 선택 이벤트 (장소 ID)

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupUI()
        setupLayout()
        setupCollectionView()
        bindViewModel()
    }

    // MARK: - Setup
    private func setupNavigationBar() {
        navigationItem.title = "장소"

        // 장소 추가 버튼 (현재는 동작 안 함, 추후 구현)
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: nil
        )
        addButton.tintColor = .black
        navigationItem.rightBarButtonItem = addButton
    }

    private func setupUI() {
        view.backgroundColor = .systemGray6

        [allFilterButton, cafeFilterButton, libraryFilterButton, studyCafeFilterButton].forEach {
            filterStackView.addArrangedSubview($0)
        }

        [mapView, currentLocationButton, filterStackView, placeCollectionView, activityIndicator].forEach {
            view.addSubview($0)
        }
    }

    private func setupCollectionView() {
        placeCollectionView.delegate = self
        mapView.delegate = self
    }

    private func setupLayout() {
        mapView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(12)
            $0.height.equalTo(300)
        }

        currentLocationButton.snp.makeConstraints {
            $0.trailing.equalTo(mapView).inset(12)
            $0.bottom.equalTo(mapView).inset(12)
            $0.width.height.equalTo(44)
        }

        filterStackView.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20) // 정렬 버튼 제거로 trailing 제약 유지
            $0.height.equalTo(40)
        }

        placeCollectionView.snp.makeConstraints {
            $0.top.equalTo(filterStackView.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    // MARK: - Binding
    private func bindViewModel() {
        let input = MapViewModel.Input(
            viewDidLoad: Observable.just(()),

            categorySelected: categorySelectedSubject.asObservable(),

            currentLocationTapped: currentLocationButton.rx.tap.asObservable(),

            // 컬렉션뷰 셀 선택
            placeSelected: placeCollectionView.rx.itemSelected.asObservable(),

            // 핀 선택 (지도 마커 클릭)
            pinSelected: pinSelectedSubject.asObservable()
        )

        let output = viewModel.transform(input)

        // 장소 목록을 컬렉션뷰 바인딩
        output.places
            .drive(placeCollectionView.rx.items(
                cellIdentifier: MapPlaceCell.reuseIdentifier,
                cellType: MapPlaceCell.self
            )) { index, place, cell in
                cell.configure(
                    name: place.placeName,
                    category: place.simpleCategory,
                    rating: 0,
                    distance: place.formattedDistance,
                    address: place.addressName,
                    description: place.roadAddressName
                )
            }
            .disposed(by: disposeBag)

        // 현재 위치로 지도 중심 이동
        output.currentLocation
            .drive(with: self) { owner, location in
                let coordinate = location.coordinate
                let region = MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1000,
                    longitudinalMeters: 1000
                )
                self.mapView.setRegion(region, animated: true)
                
                print("지도 중심 이동: \(coordinate.latitude), \(coordinate.longitude)")
            }
            .disposed(by: disposeBag)

        // 로딩 상태에 따라 인디케이터 표시/숨김
        output.isLoading
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        // 에러 메시지 표시
        output.errorMessage
            .drive(with: self) { owner, message in
                let alert = UIAlertController(
                    title: "오류",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self.present(alert, animated: true)
                
                print("에러: \(message)")
            }
            .disposed(by: disposeBag)

        // 선택된 카테고리에 따라 필터 버튼 UI 업데이트
        output.selectedCategory
            .drive(with: self) { owner, category in
                
                [owner.allFilterButton, owner.cafeFilterButton,
                 owner.libraryFilterButton, owner.studyCafeFilterButton].forEach { button in
                    button.backgroundColor = .white
                    button.setTitleColor(.darkGray, for: .normal)
                    button.layer.borderWidth = 1
                    button.layer.borderColor = UIColor.lightGray.cgColor
                }
                
                // 선택된 버튼만 강조 스타일 적용
                let selectedButton: UIButton
                switch category {
                case .all:
                    selectedButton = self.allFilterButton
                case .cafe:
                    selectedButton = self.cafeFilterButton
                case .library:
                    selectedButton = self.libraryFilterButton
                case .studyCafe:
                    selectedButton = self.studyCafeFilterButton
                }
                
                // 선택된 버튼 스타일 변경
                selectedButton.backgroundColor = .systemTeal
                selectedButton.setTitleColor(.white, for: .normal)
                selectedButton.layer.borderWidth = 0
                
            }
            .disposed(by: disposeBag)

        // 장소 목록으로 지도 마커 업데이트
        output.places
            .drive(with: self) { owner, places in
                // 기존 마커 모두 제거
                owner.mapView.removeAnnotations(owner.mapView.annotations)
                
                // 새로운 장소들을 마커로 추가
                places.forEach { place in
                    guard let lat = place.latitude, let lon = place.longitude else {
                        return
                    }

                    // 커스텀 Annotation 생성 (placeUrl 포함)
                    let annotation = PlaceAnnotation(
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        title: place.placeName,
                        subtitle: place.simpleCategory,
                        placeUrl: place.placeUrl,
                        placeId: place.id
                    )

                    // 지도에 마커 추가
                    owner.mapView.addAnnotation(annotation)
                }
                
                print("지도에 \(places.count)개 마커 추가")
            }
            .disposed(by: disposeBag)

        // 선택된 장소 상세 화면 이동 (추후 구현)
        output.selectedPlace
            .drive(with: self) { owner, place in
                print("선택된 장소: \(place.placeName)")
                // TODO: 상세 화면으로 이동
            }
            .disposed(by: disposeBag)

        // MARK: 필터 버튼 탭 이벤트 바인딩

        // 전체 버튼 탭
        allFilterButton.rx.tap
            .asDriver()
            .drive(with: self) { owenr, _ in
                owenr.categorySelectedSubject.onNext(.all)
            }
            .disposed(by: disposeBag)

        // 카페 버튼 탭
        cafeFilterButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.categorySelectedSubject.onNext(.cafe)
            }
            .disposed(by: disposeBag)

        // 도서관 버튼 탭
        libraryFilterButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.categorySelectedSubject.onNext(.library)
            }
            .disposed(by: disposeBag)


        // 스터디카페 버튼 탭
        studyCafeFilterButton.rx.tap
            .asDriver()
            .drive(with: self) { owner, _ in
                owner.categorySelectedSubject.onNext(.studyCafe)
            }
            .disposed(by: disposeBag)


        // MARK: 초기 카테고리 선택

        //  초기 로드 시 "전체" 카테고리 자동 선택
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.categorySelectedSubject.onNext(.all)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

// 컬렉션뷰 레이아웃 델리게이트
extension MapViewController: UICollectionViewDelegateFlowLayout {
    /// 셀 크기 지정 (가로에 무조건 1개씩만 표시)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // 화면 전체 너비 사용
        let screenWidth = UIScreen.main.bounds.width

        let cellWidth = screenWidth - 24

        return CGSize(width: cellWidth, height: 140)
    }
}

// MARK: - MKMapViewDelegate

// 지도 Annotation(마커) 클릭 이벤트 처리
extension MapViewController: MKMapViewDelegate {

    // Annotation이 선택되었을 때 호출 (마커 클릭)
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // 사용자 현재 위치 마커는 무시
        guard let annotation = view.annotation,
              !(annotation is MKUserLocation) else {
            return
        }

        // 커스텀 PlaceAnnotation인지 확인
        guard let placeAnnotation = annotation as? PlaceAnnotation else {
            print("PlaceAnnotation이 아닌 마커 클릭")
            return
        }

        //  핀 선택 이벤트 방출 (컬렉션뷰 필터링용)
        pinSelectedSubject.onNext(placeAnnotation.placeId)

        // placeUrl을 URL로 변환
        guard let url = URL(string: placeAnnotation.placeUrl) else {
            print("유효하지 않은 URL: \(placeAnnotation.placeUrl)")
            view.makeToast("링크를 열 수 없습니다")
            return
        }

        // SFSafariViewController로 카카오맵 페이지 열기
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .pageSheet

        // iOS 15+에서 sheet 높이 조정
        if let sheet = safariVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]  // 중간/전체 높이 선택 가능
            sheet.prefersGrabberVisible = true     // 상단 핸들 표시
        }

        present(safariVC, animated: true)

        print("핀 클릭: \(placeAnnotation.title ?? ""), ID: \(placeAnnotation.placeId)")
    }

    // Annotation View 커스터마이징 (선택사항 - 기본 핀 모양 사용)
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 사용자 위치는 기본 스타일 사용
        guard !(annotation is MKUserLocation) else {
            return nil
        }

        let identifier = "PlacePin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true  // 말풍선 표시
        } else {
            annotationView?.annotation = annotation
        }

        // 마커 색상 설정 (카테고리별로 다르게 할 수도 있음)
        annotationView?.markerTintColor = .systemTeal
        annotationView?.glyphImage = UIImage(systemName: "book.fill")  // 책 아이콘

        return annotationView
    }
}
