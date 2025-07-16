//
//  OrderRouter.swift
//  PickPle
//
//  Created by 정인선 on 8/3/25.
//

import Foundation
import Alamofire

enum OrderRouter {
    case create(_ request: OrderCreateRequest)
    case orderList
    case StatusUpdate(orderCode: String, request: OrderStatusUpdateRequest)
}

extension OrderRouter: TargetType {
    var baseURL: String {
        switch self {
        default:
            return APIURL.PICKUP
        }
    }
    
    var path: String {
        switch self {
        case .create, .orderList:
            return "/v1/orders"
        case .StatusUpdate(let orderCode, _):
            return "/v1/orders/\(orderCode)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .create:
            return .post
        case .orderList:
            return .get
        case .StatusUpdate:
            return .put
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .create(let request):
            return .body(request)
        case .orderList:
            return nil
        case .StatusUpdate(_, let request):
            return .body(request)
        }
    }
    
    var headers: HTTPHeaders? {
        switch self {
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
