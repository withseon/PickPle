//
//  NetworkManager.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Combine
import Alamofire

enum NetworkManager {
    static func executeFetch<T: Decodable, E: Decodable>(
        target: URLRequestConvertible,
        responseType: T.Type,
        errorType: E.Type
    ) -> AnyPublisher<Result<T, NetworkError<E>>, Never> {
        return AF.request(target, interceptor: APIRequestInterceptor())
            .publishData()
            .handleEvents(
                receiveSubscription: { _ in print("구독 시작") },
                receiveOutput: { response in
                    if let statusCode = response.response?.statusCode {
                        print("출력 받음: 상태 코드 \(statusCode)")
                    }
                },
                receiveCompletion: { print("완료: \($0)") },
                receiveCancel: { print("취소됨") },
                receiveRequest: { print("요청: \($0)") }
            )
            .flatMap { response -> AnyPublisher<Result<T, NetworkError>, Never> in
                if let afError = response.error {
                    return Just(.failure(.alamofire(afError)))
                        .eraseToAnyPublisher()
                }
                
                guard let httpResponse = response.response else {
                    return Just(.failure(.alamofire(AFError.responseValidationFailed(reason: .dataFileNil))))
                        .eraseToAnyPublisher()
                }

                guard let data = response.data else {
                    return Just(.failure(.alamofire(AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength))))
                        .eraseToAnyPublisher()
                }
                
                let statusCode = httpResponse.statusCode
                
                guard 200...299 ~= statusCode else {
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let errorResult = try decoder.decode(errorType.self, from: data)
                        return Just(.failure(.server(error: errorResult, statusCode: statusCode)))
                            .eraseToAnyPublisher()
                    } catch {
                        return Just(.failure(.decodingServer(error: error, statusCode: statusCode)))
                            .eraseToAnyPublisher()
                    }
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let decodedData = try decoder.decode(T.self, from: data)
                    return Just(.success(decodedData))
                        .eraseToAnyPublisher()
                } catch let error {
                    return Just(.failure(.decoding(error)))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
}
