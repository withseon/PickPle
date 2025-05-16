//
//  SignInView.swift
//  PickPle
//
//  Created by 정인선 on 5/10/25.
//

import SwiftUI

struct SignInView: View {
    @StateObject var viewModel: SignInViewModel
    @State var email: String = ""
    @State var password: String = ""
    
    @FocusState private var focusedField: FieldType?
    
    enum FieldType {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 100)
            // 로고
            VStack {
                Image(Resource.appLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.deepSprout)
                Text(Resource.appName)
                    .font(.jalnangothic(.title))
                    .foregroundStyle(.deepSprout)
            }
            
            // 입력 필드 부분
            VStack {
                VStack {
                    EmailTextField("이메일", text: $email)
                        .focused($focusedField, equals: .email)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(viewModel.output.emailErrorMessage.isEmpty ? (focusedField == .email ? .blackSprout : .gray30) : .blackSprout, lineWidth: 1)
                        )
                        .onChange(of: email) { newValue in
                            viewModel.input.email = newValue
                            if !viewModel.output.emailErrorMessage.isEmpty {
                                viewModel.action(.validateEmail)
                            }
                        }
                    Text(viewModel.output.emailErrorMessage)
                        .font(.pretendard(.caption1))
                        .foregroundStyle(.blackSprout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                VStack {
                    SecureClearableTextField("비밀번호", text: $password)
                        .focused($focusedField, equals: .password)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(viewModel.output.passwordErrorMessage.isEmpty ? (focusedField == .password ? .blackSprout : .gray30) : .blackSprout, lineWidth: 1)
                        )
                        .onChange(of: password) { newValue in
                            viewModel.input.password = newValue
                            if !viewModel.output.passwordErrorMessage.isEmpty {
                                viewModel.action(.validatePassword)
                            }
                        }
                    Text(viewModel.output.passwordErrorMessage)
                        .font(.pretendard(.caption1))
                        .foregroundStyle(.blackSprout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // 로그인 버튼
            PrimaryButton("로그인") {
                viewModel.action(.loginButtonTapped)
            }
            
            Text("회원가입")
                .font(.pretendard(.body3))
                .foregroundStyle(.gray75)
                .underline(true)
                .wrapToButton {
                    print("회원가입")
                }
            
            Spacer()
        }
        .padding(20)
        .onReceive(viewModel.output.setFocusState) { field in
            switch field {
            case .email:
                focusedField = .email
            case .password:
                focusedField = .password
            case .none:
                focusedField = nil
            }
        }
    }
}

#Preview {
    SignInView(viewModel: SignInViewModel())
}
