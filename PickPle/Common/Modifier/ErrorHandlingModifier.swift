//
//  ErrorHandlingModifier.swift
//  PickPle
//
//  Created by Claude on 1/25/25.
//

import SwiftUI

struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject var viewModel: BaseViewModel
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    func body(content: Content) -> some View {
        content
            // 토큰 만료 Alert
            .alert("로그인 만료", isPresented: $viewModel.showTokenExpiredAlert) {
                Button("확인") {
                    appCoordinator.handleTokenExpiration()
                }
            } message: {
                Text("로그인이 만료되어 다시 로그인해주세요.")
            }
            // 일반 네트워크 에러 Alert
            .alert("오류", isPresented: $viewModel.showNetworkErrorAlert) {
                Button("확인") {
                    // Alert 닫기만
                }
            } message: {
                Text(viewModel.errorMessage)
            }
    }
}

extension View {
    func handleErrors(viewModel: BaseViewModel) -> some View {
        modifier(ErrorHandlingModifier(viewModel: viewModel))
    }
}
