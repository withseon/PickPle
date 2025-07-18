//
//  BaseViewModel.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation
import SwiftUI

class BaseViewModel: ObservableObject {
    @Published var showTokenExpiredAlert = false
    @Published var showNetworkErrorAlert = false
    @Published var errorMessage = ""
    
    init() {
        print(String(describing: self), "Init")
    }
    
    deinit {
        print(String(describing: self), "Deinit")
    }
    
    // MARK: - Error Handling
    func handleError(_ error: AppError) {
        DispatchQueue.main.async { [weak self] in
            switch error {
            case .tokenExpired:
                self?.showTokenExpiredAlert = true
            case .networkError(let message), .serverError(let message), .unknownError(let message):
                self?.errorMessage = message
                self?.showNetworkErrorAlert = true
            }
        }
    }
    
    // NetworkError를 AppError로 변환하여 처리
    func handleNetworkError(_ networkError: NetworkError) {
        let appError = mapToAppError(networkError)
        handleError(appError)
    }
    
    private func mapToAppError(_ networkError: NetworkError) -> AppError {
        switch networkError {
        case .expired:
            return .tokenExpired
        case .server(let error):
            return .serverError(error.message)
        case .alamofire(let afError):
            return .networkError("네트워크 연결을 확인해주세요.")
        case .unknown(let error):
            return .unknownError("알 수 없는 오류가 발생했습니다.")
        }
    }
}
