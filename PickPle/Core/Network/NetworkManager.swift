//
//  NetworkManager.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

enum API {
    private static var _session: Session?
    
    static var session: Session {
        if let existingSession = _session {
            return existingSession
        } else {
            print("🔧 [API] 새로운 Session 생성")
            let newSession = createSession()
            _session = newSession
            return newSession
        }
    }
    
    private static func createSession() -> Session {
        let configuration = URLSessionConfiguration.af.default
        // 연결 제한을 늘려서 이미지 요청으로 인한 블로킹 방지
        configuration.httpMaximumConnectionsPerHost = 10
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        let apiLogger = APIEventLogger()
        let interceptor = APIRequestInterceptor()
        return Session(configuration: configuration, interceptor: interceptor, eventMonitors: [apiLogger])
    }
    
    /// Session 강제 재시작 (문제 발생 시 사용) - 호출되고 있진 않음
    static func resetSession() {
        print("🔄 [API] Session 재시작")
        _session?.session.invalidateAndCancel()
        _session = nil
        // 다음 접근 시 자동으로 새 세션 생성됨
    }
}

final class NetworkManager {
    @discardableResult
    func request<T: Decodable, E: ErrorResponseType>(
        target: URLRequestConvertible,
        responseType: T.Type,
        errorType: E.Type
    ) async throws -> T {
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
    
    func requestVoid<E: ErrorResponseType>(
        target: URLRequestConvertible,
        errorType: E.Type
    ) async throws -> Void {
        return try await withCheckedThrowingContinuation { continuation in
            API.session.request(target)
                .validate(statusCode: 200...299)
                .response { response in
                    switch response.result {
                    case .success:
                        continuation.resume()
                    case .failure(let error):
                        continuation.resume(throwing: NetworkError.alamofire(error))
                    }
                }
        }
    }
    
    func uploadMultipart<T: Decodable, E: ErrorResponseType>(
        target: URLRequestConvertible,
        fileData: [MultipartFile],
        responseType: T.Type,
        errorType: E.Type
    ) async throws -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("📊 파일 업로드 시작 - 파일 수: \(fileData.count)")
        
        // 파일 크기 로깅
        let totalSize = fileData.reduce(0) { $0 + $1.data.count }
        print("📊 업로드할 총 파일 크기: \(totalSize / 1024)KB")
        
        guard let url = target.urlRequest?.url else {
            throw NetworkError.alamofire(.invalidURL(url: target.urlRequest?.url ?? ""))
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let multipartStartTime = CFAbsoluteTimeGetCurrent()
        
        let request = API.session.upload(
            multipartFormData: { multipartFormData in
                for file in fileData {
                    multipartFormData.append(
                        file.data,
                        withName: "files",
                        fileName: file.fileName,
                        mimeType: file.mimeType
                    )
                }
            },
            to: url,
            method: target.urlRequest?.method ?? .post,
            headers: target.urlRequest?.headers
        )
        .validate(statusCode: 200...299)
        .serializingDecodable(T.self, decoder: decoder)
        
        let multipartTime = CFAbsoluteTimeGetCurrent() - multipartStartTime
        print("📊 Multipart 구성 소요시간: \(multipartTime)초")
        
        do {
            let value = try await request.value
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            print("📊 파일 업로드 완료 - 총 소요시간: \(totalTime)초")
            return value
        } catch {
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            print("📊 파일 업로드 실패 - 소요시간: \(totalTime)초")
            
            throw error
        }
    }
}
