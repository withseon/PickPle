//
//  TargetType.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

enum RequestParams {
    case query(_ param: RequestableType?)
    case body(_ param: RequestableType?)
}

protocol TargetType: URLRequestConvertible {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: RequestParams? { get }
    var headers: HTTPHeaders? { get }
}

extension TargetType {
    func asURLRequest() throws -> URLRequest {
        let url = try baseURL.asURL()
        var urlRequest = try URLRequest(url: url.appendingPathComponent(path), method: method)
        
        if let headers = headers {
            headers.forEach { header in
                urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
            }
        }

        switch parameters {
        case .query(let request):
            let params = request?.toParameter ?? [:]
            let queryParams = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            var components = URLComponents(string: url.appendingPathComponent(path).absoluteString)
            components?.queryItems = queryParams
            urlRequest.url = components?.url
        case .body(let request):
            let params = request?.toParameter ?? [:]
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
        case .none:
            break
        }
        return urlRequest
    }
}
