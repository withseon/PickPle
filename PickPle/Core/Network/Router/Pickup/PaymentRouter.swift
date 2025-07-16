//
//  PaymentRouter.swift
//  PickPle
//
//  Created by 정인선 on 8/9/25.
//

import Foundation
import Alamofire

enum PaymentRouter {
    case validation(_ request: ReceiptOrderRequest)
    case check(_ orderCode: String)
}

extension PaymentRouter: TargetType {
    var baseURL: String {
        switch self {
        default:
            return APIURL.PICKUP
        }
    }
    
    var path: String {
        switch self {
        case .validation:
            return "/v1/payments/validation"
        case .check(let orderCode):
            return "/v1/payments/\(orderCode)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .validation:
            return .post
        case .check:
            return .get
        }
    }
    
    var parameters: RequestParams? {
        switch self {
        case .validation(let request):
            return .body(request)
        case .check:
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
