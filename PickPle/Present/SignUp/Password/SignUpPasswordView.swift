//
//  SignUpPasswordView.swift
//  PickPle
//
//  Created by 정인선 on 5/12/25.
//

import SwiftUI

struct SignUpPasswordView: View {
    @StateObject var viewModel: SignUpPasswordViewModel
    @State var password = ""
    @State var passwordConfirmation = ""
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 100)
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("로그인에 사용할\n비밀번호를 입력해주세요.")
                            .font(.pretendard(.title))
                        Text("비밀번호는 최소 8자 이상이며,\n영문자, 숫자, 특수문자(@$!%*#?&)를 각각 1개 이상 포함해야 합니다.")
                            .font(.pretendard(.caption1))
                    }
                    Spacer()
                }
                VStack(alignment: .leading) {
                    Text("비밀번호")
                        .font(.pretendard(.body1))
                    SecureClearableTextField("비밀번호를 입력해주세요", text: $password)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray30, lineWidth: 1)
                        )
                        .onChange(of: password) { newValue in
                            viewModel.input.password = newValue
                            viewModel.action(.validatePassword)
                        }
                    Text(viewModel.output.passwordErrorMessage)
                        .font(.pretendard(.caption1))
                        .foregroundStyle(.errorRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading) {
                    Text("비밀번호 확인")
                        .font(.pretendard(.body1))
                    SecureClearableTextField("비밀번호를 입력해주세요", text: $passwordConfirmation)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.gray30, lineWidth: 1)
                        )
                        .onChange(of: passwordConfirmation) { newValue in
                            viewModel.input.passwordConfirmation = newValue
                            viewModel.action(.confirmPassword)
                        }
                    Text(viewModel.output.passwordConfirmErrorMessage)
                        .font(.pretendard(.caption1))
                        .foregroundStyle(.errorRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
    SignUpPasswordView(viewModel: SignUpPasswordViewModel())
}
