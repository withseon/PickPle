//
//  NetworkManager.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

private enum API {
    static let session: Session = {
        let configuration = URLSessionConfiguration.af.default
        let apiLogger = APIEventLogger()
        return Session(configuration: configuration, eventMonitors: [apiLogger])
    }()
}

enum NetworkManager {
    @discardableResult
    static func executeFetch<T: Decodable, E: ErrorResponseType>(
        target: URLRequestConvertible,
        responseType: T.Type,
        errorType: E.Type
    ) async throws -> T {
        let request = API.session.request(target, interceptor: APIRequestInterceptor())
            .validate(statusCode: 200...299)
            .serializingDecodable(T.self)
        
        do {
            return try await request.value
        } catch {
            if let responseData = await request.response.data {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let errorResult = try decoder.decode(errorType.self, from: responseData)
                throw NetworkError<E>.server(errorResult)
            } else if let error = error as? AFError {
                throw NetworkError<E>.alamofire(error)
            } else {
                throw NetworkError<E>.unknown(error)
            }
        }
    }
}
