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
        print("🦊", #function, target)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        print(111)
        let request = API.session.request(target, interceptor: APIRequestInterceptor())
            .validate(statusCode: 200...299)
            .serializingDecodable(T.self, decoder: decoder)
        print(222)
        
        do {
            print(333)
            let value = try await request.value
            print("🦊 value::", value)
            return value
//            print("🦊 value::", try await request.value)
//            return try await request.value
        } catch {
            if let error = await request.response.error,
               case .requestRetryFailed(let retryError, _) = error,
               let error = retryError as? NetworkError<UserErrorResponse> {
                throw error
            }
            
            if let responseData = await request.response.data {
                print(444)
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let errorResult = try decoder.decode(errorType.self, from: responseData)
                throw NetworkError<E>.server(errorResult)
            } else if let error = error as? AFError {
                print(555)
                throw NetworkError<E>.alamofire(error)
            } else {
                print(666)
                throw NetworkError<E>.unknown(error)
            }
        }
    }
}
