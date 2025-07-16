//
//  OrderRepository.swift
//  PickPle
//
//  Created by 정인선 on 8/3/25.
//

import Foundation
import Combine

protocol OrderRepository {
    func createOrder(_ request: OrderCreateRequest) -> AnyPublisher<Result<OrderCreateResponse, NetworkError>, Never>
    func checkOrderList() -> AnyPublisher<Result<OrderWithStatusListResponse, NetworkError>, Never>
    func changeOrderStatus(orderCode: String, request: OrderStatusUpdateRequest) async throws -> Void
}

final class DefaultOrderRepository: OrderRepository {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func createOrder(_ request: OrderCreateRequest) -> AnyPublisher<Result<OrderCreateResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: OrderRouter.create(request),
                        responseType: OrderCreateResponse.self,
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
    
    func checkOrderList() -> AnyPublisher<Result<OrderWithStatusListResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: OrderRouter.orderList,
                        responseType: OrderWithStatusListResponse.self,
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
    
    func changeOrderStatus(orderCode: String, request: OrderStatusUpdateRequest) async throws -> Void {
        return try await networkManager.requestVoid(
            target: OrderRouter.StatusUpdate(
                orderCode: orderCode,
                request: request
            ),
            errorType: UserErrorResponse.self
        )
    }
}
