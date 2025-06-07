//
//  StoreRepository.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import Combine

protocol StoreRepository {
    func storeList(_ param: StoreListParam) -> AnyPublisher<Result<StoreSummaryListResponse, NetworkError>, Never>
    func popularStore(_ category: StoreCategory?) -> AnyPublisher<Result<PopularStoreListResponse, NetworkError>, Never>
}

final class DefaultStoreRepository: StoreRepository {
    static let shared = DefaultStoreRepository()
    private init() { }
    
    func storeList(_ param: StoreListParam) -> AnyPublisher<Result<StoreSummaryListResponse, NetworkError>, Never> {
        return Future { promise in
            Task {
                do {
                    let dto = StoreSummaryListRequest(
                        category: param.category?.rawValue,
                        longitude: param.longitude,
                        latitude: param.latitude,
                        next: param.next,
                        limit: nil,
                        orderBy: param.orderBy?.rawValue)
                    let storeList = try await NetworkManager.executeFetch(
                        target: StoreRouter.stores(dto),
                        responseType: StoreSummaryListResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(storeList)))
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
    
    func popularStore(_ category: StoreCategory?) -> AnyPublisher<Result<PopularStoreListResponse, NetworkError>, Never> {
        return Future { promise in
            Task {
                do {
                    let dto = PopularStoreRequest(category: category?.rawValue)
                    let storeList = try await NetworkManager.executeFetch(
                        target: StoreRouter.popularStores(dto),
                        responseType: PopularStoreListResponse.self,
                        errorType: UserErrorResponse.self)
                    promise(.success(.success(storeList)))
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
