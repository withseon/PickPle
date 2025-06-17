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
    func searchPopular() -> AnyPublisher<Result<SearchPopularResponse, NetworkError>, Never>
    func likeStore(_ storeId: String, _ isPick: Bool) -> AnyPublisher<Result<StoreLikeResponse, NetworkError>, Never>
}

final class DefaultStoreRepository: StoreRepository {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func storeList(_ param: StoreListParam) -> AnyPublisher<Result<StoreSummaryListResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self,
                      let latitude = UserDefaultsManager.selectedLocation?.latitude,
                      let longitude = UserDefaultsManager.selectedLocation?.longitude else { return }
                do {
                    let dto = StoreSummaryListRequest(
                        category: param.category?.title,
                        longitude: Float(longitude),
                        latitude: Float(latitude),
                        next: param.next,
                        limit: param.limit,
                        orderBy: param.orderBy?.rawValue)
                    let storeList = try await networkManager.request(
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
            Task { [weak self] in
                guard let self else { return }
                do {
                    let dto = PopularStoreRequest(category: category?.title)
                    let storeList = try await networkManager.request(
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
    
    func searchPopular() -> AnyPublisher<Result<SearchPopularResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let searchPopular = try await networkManager.request(
                        target: StoreRouter.searchPopular,
                        responseType: SearchPopularResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(searchPopular)))
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
    
    func likeStore(_ storeId: String, _ isPick: Bool) -> AnyPublisher<Result<StoreLikeResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let likeStore = try await networkManager.request(
                        target: StoreRouter.likeStore(storeId, StoreLikeRequest(likeStatus: isPick)),
                        responseType: StoreLikeResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(likeStore)))
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
