//
//  PaymentRepository.swift
//  PickPle
//
//  Created by 정인선 on 8/9/25.
//

import Foundation
import Combine

protocol PaymentRepository {
    func validationReceipt(_ request: ReceiptOrderRequest) -> AnyPublisher<Result<ReceiptOrderResponse, NetworkError>, Never>
    func checkReceipt(_ orderCode: String) -> AnyPublisher<Result<PaymentResponse, NetworkError>, Never>
}

final class DefaultPaymentRepository: PaymentRepository {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func validationReceipt(_ request: ReceiptOrderRequest) -> AnyPublisher<Result<ReceiptOrderResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: PaymentRouter.validation(request),
                        responseType: ReceiptOrderResponse.self,
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
    
    func checkReceipt(_ orderCode: String) -> AnyPublisher<Result<PaymentResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: PaymentRouter.check(orderCode),
                        responseType: PaymentResponse.self,
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
