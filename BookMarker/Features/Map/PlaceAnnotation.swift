//
//  PlaceAnnotation.swift
//  BookMarker
//
//  Created by Reimos on 10/10/25.
//

import MapKit

// 카카오 장소 정보를 담은 커스텀 Annotation
// - placeUrl: 카카오맵 상세 페이지 URL
// - placeId: 카카오 장소 ID
class PlaceAnnotation: NSObject, MKAnnotation {
    // MKAnnotation 프로토콜 필수 프로퍼티
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    // 추가 정보
    let placeUrl: String
    let placeId: String

    init(coordinate: CLLocationCoordinate2D,
         title: String?,
         subtitle: String?,
         placeUrl: String,
         placeId: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.placeUrl = placeUrl
        self.placeId = placeId
        super.init()
    }
}
