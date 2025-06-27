//
//  PostRepository.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation
import Combine

protocol PostRepository {
    func postList(_ param: PostListParam) -> AnyPublisher<Result<PostSummaryListResponse, NetworkError>, Never>
}

final class DefaultPostRepository: PostRepository {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func postList(_ param: PostListParam) -> AnyPublisher<Result<PostSummaryListResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self,
                      let latitude = UserDefaultsManager.selectedLocation?.latitude,
                      let longitude = UserDefaultsManager.selectedLocation?.longitude else { return }
                do {
                    let dto = PostSummaryRequest(
                        category: param.category?.title,
                        longitude: Float(longitude),
                        latitude: Float(latitude),
                        maxDistance: param.distance,
                        limit: param.limit,
                        next: param.next,
                        orderBy: param.orderBy?.rawValue)
                    let postList = try await networkManager.request(
                        target: PostRouter.posts(dto),
                        responseType: PostSummaryListResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(postList)))
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
