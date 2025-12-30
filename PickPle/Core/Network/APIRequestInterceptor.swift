//
//  APIRequestInterceptor.swift
//  PickPle
//
//  Created by 정인선 on 5/13/25.
//

import Foundation
import Alamofire

// MARK: - Actor Core (내부 로직)

actor APIRequestInterceptorCore {
    /// 토큰 갱신 중복 방지를 위한 플래그
    private var isRefreshing = false

    /// 진행 중인 토큰 갱신 작업
    /// - 여러 요청이 동시에 419 에러를 받았을 때, 첫 번째 요청의 갱신 작업을 공유
    /// - 나머지 요청들은 새로운 갱신을 시도하지 않고 이 Task의 결과를 대기
    private var refreshTask: Task<RetryResult, Never>?

    /// URLRequest에 인증 헤더를 추가하는 메서드
    func adapt(_ urlRequest: URLRequest) async -> Result<URLRequest, Error> {
        guard let url = urlRequest.url?.absoluteString else {
            return .success(urlRequest)
        }
        
        if url.hasPrefix(APIURL.PICKUP) {
            var urlRequest = urlRequest
            urlRequest.setValue(APIKEY.PICKUP, forHTTPHeaderField: "SesacKey")
            
            // 로그인/회원가입 요청은 토큰 없이 진행
            let authNotRequiredEndpoints = [
                "/login/kakao",
                "/login/email",
                "/join/email",
                "/users/validation/email"
            ]

            let requiresAuth = !authNotRequiredEndpoints.contains { url.contains($0) }

            if !requiresAuth {
                return .success(urlRequest)
            }

            // 토큰 조회 및 헤더 추가
            do {
                let token = try await TokenManager.shared.retrieve(forKey: SecureKey.ACCESS_TOKEN)
                urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
                return .success(urlRequest)
            } catch {
                // 인증이 필요한데 토큰이 없음 = 즉시 실패
                // 불필요한 네트워크 요청 방지
                print("❌ [APIRequestInterceptorCore] 토큰 조회 실패 - 인증 에러 반환")
                return .failure(NetworkError.expired)
            }
        }

        return .success(urlRequest)
    }
    
    /// 요청 실패 시 재시도 여부를 결정하는 메서드
    func retry(_ request: Request, dueTo error: Error) async -> RetryResult {
        // 리프레시 토큰 만료 (418) - 재시도 불가
        guard let response = request.response, response.statusCode != 418 else {
            print("❌ [APIRequestInterceptorCore] 리프레시 토큰 만료 (418)")
            return .doNotRetryWithError(NetworkError.expired)
        }

        // 액세스 토큰 만료 (419)가 아닌 경우 - 재시도 불가
        guard let response = request.response, response.statusCode == 419 else {
            print("❌ [APIRequestInterceptorCore] 액세스 토큰 만료 (419)")
            return .doNotRetryWithError(error)
        }
        
        // 여러 요청이 동시에 419 에러를 받았을 때, 첫 번째 요청만 토큰을 갱신하고
        // 나머지 요청들은 같은 Task의 결과를 공유하여 중복 API 호출 방지

        // 이미 진행 중인 갱신 작업이 있으면 그 결과를 기다림
        if let existingTask = refreshTask {
            print("⏳ [APIRequestInterceptorCore] 토큰 갱신 대기 중 - 기존 작업 재사용")
            return await existingTask.value
        }

        // 새로운 갱신 작업 시작 (첫 번째 요청만 여기 진입)
        let task = Task<RetryResult, Never> {
            await performTokenRefresh()
        }
        refreshTask = task  // Actor 프로퍼티에 저장 (다른 요청들이 볼 수 있음)

        let result = await task.value  // 갱신 완료까지 대기 (suspension point)
        refreshTask = nil  // 작업 완료 후 초기화

        return result
    }
    
    /// 실제 토큰 갱신을 수행하는 메서드
    private func performTokenRefresh() async -> RetryResult {
        do {
            // 1. 기존 토큰 조회
            let accessToken = try await TokenManager.shared.retrieve(forKey: SecureKey.ACCESS_TOKEN)
            let refreshToken = try await TokenManager.shared.retrieve(forKey: SecureKey.REFRESH_TOKEN)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            // 2. 토큰 갱신 API 호출
            let request = AF.request(AuthRouter.refresh(accessToken, refreshToken))
                .validate(statusCode: 200...299)
                .serializingDecodable(RefreshResponse.self, decoder: decoder)

            let value = try await request.value

            // 3. 새 토큰 저장 (병렬 처리)
            // withThrowingTaskGroup을 사용하여 동시에 저장
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await TokenManager.shared.save(value.accessToken, forKey: SecureKey.ACCESS_TOKEN)
                }
                group.addTask {
                    try await TokenManager.shared.save(value.refreshToken, forKey: SecureKey.REFRESH_TOKEN)
                }
                try await group.waitForAll()
            }

            print("✅ [APIRequestInterceptorCore] 토큰 갱신 및 저장 성공")
            return .retry  // 갱신 성공 → 원래 요청 재시도
        } catch {
            print("❌ [APIRequestInterceptorCore] 토큰 갱신 실패: \(error)")
            return .doNotRetryWithError(NetworkError.expired)  // 갱신 실패 → 로그아웃 처리
        }
    }
}

// MARK: - Wrapper (Alamofire 호환)
/// Alamofire의 RequestInterceptor 프로토콜 준수를 위한 Wrapper 클래스
/// - Actor는 Alamofire의 completion 기반 API와 직접 호환되지 않으므로 중간 레이어 필요
final class APIRequestInterceptor: RequestInterceptor, @unchecked Sendable {
    /// Actor Core 인스턴스
    private let core = APIRequestInterceptorCore()

    /// Alamofire의 RequestAdapter 프로토콜 메서드
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        // Task로 감싸서 async/await를 completion으로 변환
        Task {
            let result = await core.adapt(urlRequest)
            completion(result)  // Alamofire에게 결과 전달
        }
    }

    /// Alamofire의 RequestRetrier 프로토콜 메서드
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        // Task로 감싸서 async/await를 completion으로 변환
        Task {
            let result = await core.retry(request, dueTo: error)
            completion(result)  // Alamofire에게 결과 전달
        }
    }
}
