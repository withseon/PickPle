//
//  SignInView.swift
//  PickPle
//
//  Created by 정인선 on 5/10/25.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var coordinator: AuthCoordinator
    @StateObject var viewModel: SignInViewModel
    @State var email: String = ""
    @State var password: String = ""
    
    @FocusState private var focusedField: FieldType?
    
    enum FieldType {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            // 로고
            Image(Resource.appLogo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140)
                .padding(.bottom, 20)
            
            VStack(spacing: 24) {
                // 입력 필드 부분
                VStack {
                    EmailTextField(
                        "이메일",
                        text: $email,
                        strokeColor: viewModel.output.emailErrorMessage.isEmpty ?
                        (focusedField == .email ? .blackSprout : .gray30) : .blackSprout,
                        errorMessage: viewModel.output.emailErrorMessage
                    )
                    .focused($focusedField, equals: .email)
                    .onChange(of: email) { newValue in
                        viewModel.action(.validateEmail(newValue))
                    }
                    
                    SecureClearableTextField(
                        "비밀번호",
                        text: $password,
                        strokeColor: viewModel.output.passwordErrorMessage.isEmpty ?
                        (focusedField == .password ? .blackSprout : .gray30) : .blackSprout,
                        errorMessage: viewModel.output.passwordErrorMessage
                    )
                    .focused($focusedField, equals: .password)
                    .onChange(of: password) { newValue in
                        viewModel.action(.validatePassword(newValue))
                    }
                }
                
                // 로그인 버튼
                PrimaryButton("로그인") {
                    viewModel.action(.loginButtonTapped)
                }
            }
            
            VStack(spacing: 24) {
                HStack(spacing: 20) {
                    Rectangle()
                        .frame(width: 80, height: 1)
                        .foregroundStyle(.gray30)
                    Text("또는")
                        .font(.pretendard(.body2))
                        .foregroundStyle(.gray75)
                    Rectangle()
                        .frame(width: 80, height: 1)
                        .foregroundStyle(.gray30)
                }
                
                HStack(spacing: 16) {
                    Image("kakao.login")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .wrapToButton {
                            viewModel.action(.kakaoLoginButtonTapped)
                        }
                    
                    Image("apple.login")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .wrapToButton {
                            // TODO: 애플 로그인
                            print("애플 로그인 버튼 클릭")
                        }
                }
            }
            
            NavigationLink(value: AuthRoute.signup) {
                Text("회원가입")
                    .font(.pretendard(.body3))
                    .foregroundStyle(.gray75)
                    .underline(true)
            }
            
            Spacer()
        }
        .padding(20)
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
        .onReceive(viewModel.output.pushMainTrigger) { _ in
            coordinator.succeedLogin()
        }
        .background(Color(.systemBackground))
        .onTapGesture {
            focusedField = nil
        }
    }
        
}
