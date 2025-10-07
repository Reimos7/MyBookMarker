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

final class MapViewController: UIViewController {

    private let mapView = MKMapView().then {
        $0.showsUserLocation = true
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

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

    private let filterStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.distribution = .fillProportionally
    }

    private let allFilterButton = UIButton().then {
        $0.setTitle("전체", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.setTitleColor(.white, for: .normal)
        $0.backgroundColor = UIColor.systemTeal
        $0.layer.cornerRadius = 20
        $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }

    private let cafeFilterButton = UIButton().then {
        $0.setTitle("카페", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.setTitleColor(.darkGray, for: .normal)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }

    private let libraryFilterButton = UIButton().then {
        $0.setTitle("도서관", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.setTitleColor(.darkGray, for: .normal)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }

    private let studyCafeFilterButton = UIButton().then {
        $0.setTitle("스터디카페", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.setTitleColor(.darkGray, for: .normal)
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.lightGray.cgColor
        $0.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    }

    private lazy var placeCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGray6
        collectionView.register(MapPlaceCell.self, forCellWithReuseIdentifier: MapPlaceCell.reuseIdentifier)
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    // MARK: - Properties

    private let disposeBag = DisposeBag()

    private let dummyPlaces: [(name: String, category: String, rating: Double, distance: String, address: String, description: String, imageName: String)] = [
        ("스타벅스 강남점", "카페", 4.5, "0.2km", "서울시 강남구 테헤란로 123", "조용하고 독서하기 좋은 분위기", "cafe1"),
        ("국립중앙도서관", "도서관", 4.8, "1.5km", "서울시 서초구 반포대로 201", "넓은 열람실과 다양한 도서 보유", "library1"),
        ("투썸플레이스 역삼점", "카페", 4.3, "0.5km", "서울시 강남구 역삼동 789", "2층 창가 자리 독서하기 좋음", "cafe2"),
        ("스터디움 강남점", "스터디카페", 4.6, "0.8km", "서울시 강남구 강남대로 456", "24시간 운영, 조용한 개인 스터디룸", "study1"),
        ("서울시립도서관", "도서관", 4.7, "2.1km", "서울시 서초구 서초대로 234", "신간 도서 많고 쾌적한 환경", "library2"),
        ("커피빈 테헤란점", "카페", 4.4, "0.3km", "서울시 강남구 테헤란로 567", "넓은 좌석과 콘센트 많음", "cafe3")
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationBar()
        setupUI()
        setupLayout()
        setupMapDummyData()
        setupCollectionView()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.title = "내 주변 독서 공간"

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
        
        [allFilterButton,cafeFilterButton,libraryFilterButton,studyCafeFilterButton].forEach {
            filterStackView.addArrangedSubview($0)
        }

        [mapView, currentLocationButton, filterStackView, placeCollectionView].forEach {
            view.addSubview($0)
        }

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
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
            $0.height.equalTo(40)
        }

        placeCollectionView.snp.makeConstraints {
            $0.top.equalTo(filterStackView.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func setupMapDummyData() {
        // 서울 강남역 근처 좌표
        let seoulCoordinate = CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276)
        let region = MKCoordinateRegion(center: seoulCoordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: false)

        // 더미 핀 추가
        let annotation1 = MKPointAnnotation()
        annotation1.coordinate = CLLocationCoordinate2D(latitude: 37.4985, longitude: 127.0280)
        annotation1.title = "스타벅스 강남점"

        let annotation2 = MKPointAnnotation()
        annotation2.coordinate = CLLocationCoordinate2D(latitude: 37.4970, longitude: 127.0270)
        annotation2.title = "국립중앙도서관"

        mapView.addAnnotations([annotation1, annotation2])
    }

    private func setupCollectionView() {
        Observable.just(dummyPlaces)
            .bind(to: placeCollectionView.rx.items(
                cellIdentifier: MapPlaceCell.reuseIdentifier,
                cellType: MapPlaceCell.self
            )) { index, place, cell in
                cell.configure(
                    name: place.name,
                    category: place.category,
                    rating: place.rating,
                    distance: place.distance,
                    address: place.address,
                    description: place.description
                )
            }
            .disposed(by: disposeBag)

        // 셀 크기 설정
        placeCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MapViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        return CGSize(width: width, height: 140)
    }
}

