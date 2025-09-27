//
//  ViewDesignProtocol.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import UIKit

protocol DesignProtocol: AnyObject {
    func configureHierarchy()
    func configureLayout()
    func configureView()
}

protocol DesiginProtocolBind: DesignProtocol {
    func bind()
}
