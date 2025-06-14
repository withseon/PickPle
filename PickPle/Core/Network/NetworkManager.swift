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
        let interceptor = APIRequestInterceptor()
        return Session(configuration: configuration, interceptor: interceptor, eventMonitors: [apiLogger])
    }()
}

final class NetworkManager {
    @discardableResult
    func request<T: Decodable, E: ErrorResponseType>(
        target: URLRequestConvertible,
        responseType: T.Type,
        errorType: E.Type
    ) async throws -> T {
        print("🦊", #function, target)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let request = API.session.request(target)
            .validate(statusCode: 200...299)
            .serializingDecodable(T.self, decoder: decoder)
        do {
            let value = try await request.value
            return value
        } catch {
            if let error = await request.response.error {
                if case .requestRetryFailed(let retryError, _) = error {
                    if let networkError = retryError as? NetworkError {
                        print("Network error: \(networkError)")
                        throw networkError
                    }
                }
            }
            
            if let responseData = await request.response.data {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let errorResult = try decoder.decode(errorType.self, from: responseData)
                throw NetworkError.server(errorResult)
            } else if let error = error as? AFError {
                throw NetworkError.alamofire(error)
            } else {
                throw NetworkError.unknown(error)
            }
        }
    }
}
