//
//  BannerRepository.swift
//  PickPle
//
//  Created by 정인선 on 8/1/25.
//

import Foundation
import Combine

protocol BannerRepository {
    func banner() -> AnyPublisher<Result<BannerListResponse, NetworkError>, Never>
}

final class DefaultBannerRepository: BannerRepository {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func banner() -> AnyPublisher<Result<BannerListResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: BannerRouter.banner,
                        responseType: BannerListResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(response)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
