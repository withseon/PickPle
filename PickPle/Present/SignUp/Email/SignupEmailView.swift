//
//  SignupEmailView.swift
//  PickPle
//
//  Created by 정인선 on 5/11/25.
//

import SwiftUI

struct SignupEmailView: View {
    @StateObject var viewModel: SignUpEmailViewModel
    @State var email = ""
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 100)
            VStack(spacing: 20) {
                HStack {
                    Text("로그인에 사용할\n이메일을 입력해주세요.")
                        .font(.pretendard(.title))
                    Spacer()
                }
                VStack(alignment: .leading) {
                    Text("이메일(아이디)")
                        .font(.pretendard(.body1))
                    EmailTextField(
                        "이메일을 입력해주세요",
                        text: $email,
                        strokeColor: viewModel.output.emailErrorMessage.isEmpty ? .gray30 : .errorRed, 
                        errorMessage: viewModel.output.emailErrorMessage
                    )
                    .onChange(of: email) { newValue in
                        viewModel.input.email = newValue
                        viewModel.action(.validateEmail)
                    }
                }
            }
            Spacer()
            PrimaryButton(
                "다음",
                backgroundColor: .gray100,
                foregroundColor: .gray0
            ) {
                
            }
            .disabled(viewModel.output.nextButtonDisable)
        }
        .padding(20)
    }
}

#Preview {
    SignupEmailView(viewModel: SignUpEmailViewModel())
}
