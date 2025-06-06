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
        case .storeDetail(let storeId):
            return "/v1/stores/\(storeId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .stores, .popularStores, .storeDetail:
            return .get
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .stores(let request):
            return .query(request)
        case .popularStores(let request):
            return .query(request)
        case .storeDetail:
            return nil
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        default:
            return nil
        }
    }
}
