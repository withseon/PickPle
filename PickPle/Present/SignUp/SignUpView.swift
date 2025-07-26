//
//  SignUpView.swift
//  PickPle
//
//  Created by 정인선 on 5/16/25.
//

import SwiftUI

struct SignUpView: View {
    @StateObject var viewModel: SignUpViewModel
    
    var body: some View {
        Group {
            switch viewModel.output.state {
            case .email:
                SignUpEmailView(viewModel: viewModel)
            case .password:
                SignUpPasswordView(viewModel: viewModel)
            case .info:
                SignUpInfoView(viewModel: viewModel)
            }
        }
        .padding(20)
        
    }
}
