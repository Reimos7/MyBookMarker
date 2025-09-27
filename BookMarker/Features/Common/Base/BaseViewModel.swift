//
//  BaseViewModel.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import Foundation

protocol BaseViewModel {
    associatedtype Input
    associatedtype Output
    
    func transform(_ input: Input) -> Output
}
