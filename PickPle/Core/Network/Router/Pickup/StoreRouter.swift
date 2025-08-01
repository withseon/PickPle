//
//  StoreRouter.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Foundation
import Alamofire

enum StoreRouter {
    case stores(_ request: StoreSummaryListRequest)
    case popularStores(_ request: PopularStoreRequest)
    case search(_ request: StoreSearchRequest)
    case searchPopular
    case likeStore(_ storeId: String, _ request: StoreLikeRequest)
    case storeDetail(_ storeId: String)
}

extension StoreRouter: TargetType {
    var baseURL: String {
        switch self {
        default:
            return APIURL.PICKUP
        }
    }
    
    var path: String {
        switch self {
        case .stores:
            return "/v1/stores"
        case .popularStores:
            return "/v1/stores/popular-stores"
        case .search:
            return "/v1/stores/search"
        case .searchPopular:
            return "/v1/stores/searches-popular"
        case .likeStore(let storeId, _):
            return "/v1/stores/\(storeId)/like"
        case .storeDetail(let storeId):
            return "/v1/stores/\(storeId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .stores, .popularStores, .search, .searchPopular, .storeDetail:
            return .get
        case .likeStore:
            return .post
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .stores(let request):
            return .query(request)
        case .popularStores(let request):
            return .query(request)
        case .search(let request):
            return .query(request)
        case .likeStore(_, let request):
            return .body(request)
        case .searchPopular, .storeDetail:
            return nil
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
