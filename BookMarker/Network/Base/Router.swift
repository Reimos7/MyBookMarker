//
//  Router.swift
//  BookMarker
//
//  Created by Reimos on 9/26/25.
//

import Foundation
import Alamofire

enum Router {
    
    case bestSeller
    case newBooks
    case author(author: String)
    case keyword(keyword: String)
    case categoryBest(categoryId: BookCategory)
        
    var bookApiType: NetworkBookAPIType {
        switch self {
        case .bestSeller:
            return .bestSeller
        case .newBooks:
            return .newBooks
        case .author:
            return .author
        case .keyword:
            return .keyword
        case .categoryBest:
            return .bestSeller
        }
    }
    
    // baseUrl이랑 같이 사용할 요청 URL
    var endPoint: URL {
        switch self {
        case .bestSeller:
            return URL(string: API.bookBaseUrl + "/ItemList.aspx?ttbkey=\(API.bookAPIKey)" + "&QueryType=Bestseller&MaxResults=10&start=1&SearchTarget=Book&output=JS&Version=20131101")!
        case .newBooks:
            return URL(string: API.bookBaseUrl + "/ItemList.aspx?ttbkey=\(API.bookAPIKey)" + "&QueryType=ItemNewSpecial&MaxResults=10&start=1&SearchTarget=Book&output=JS&Version=20131101")!
        case .author(let author):
            return URL(string: API.bookBaseUrl + "/ItemSearch.aspx?ttbkey=\(API.bookAPIKey)&Query=\(author)" + "&QueryType=Author&MaxResults=10&start=1&SearchTarget=Book&output=JS&Version=20131101")!

        case .keyword(let keyword):
            return URL(string: API.bookBaseUrl + "/ItemSearch.aspx?ttbkey=\(API.bookAPIKey)&Query=\(keyword)" + "&QueryType=Keyword&MaxResults=20&start=1&SearchTarget=Book&output=JS&Version=20131101")!

        case .categoryBest(let categoryId):
            return URL(string: API.bookBaseUrl + "/ItemList.aspx?ttbkey=\(API.bookAPIKey)" + "&QueryType=Bestseller&CategoryId=\(categoryId.rawValue)&MaxResults=10&start=1&SearchTarget=Book&output=JS&Version=20131101")!
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .bestSeller:
            return .get
        case .newBooks:
            return .get
        case .author(let author):
            return .get
        case .keyword(let keyword):
            return .get
        case .categoryBest:
            return .get
        }
    }
    
    var parameter: [String: Any]? {
        switch self {
        case .bestSeller:
            return nil
        case .newBooks:
            return nil
        case .author(let author):
            return ["author": author]
        case .keyword(let keyword):
            return ["keyword": keyword]
        case .categoryBest(let categoryId):
            return nil
        }
    }
    
    
}
