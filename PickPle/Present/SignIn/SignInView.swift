//
//  SignInView.swift
//  PickPle
//
//  Created by 정인선 on 5/10/25.
//

import SwiftUI
import KakaoSDKUser

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
                let token = UserDefaults.standard.string(forKey: "deviceToken")
                print("저장된 디바이스 토큰: \(DeviceToken.value)")
                viewModel.action(.loginButtonTapped)
            }
            HStack {
                Image("kakao.com")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .wrapToButton {
//                        if UserApi.isKakaoTalkLoginAvailable() {
                            // 카카오톡 로그인
                            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                                if let error = error {
                                    print(error)
                                } else {
                                    print("카카오톡 로그인 success")
                                    
                                    // 추가작업
                                    dump(oauthToken)
                                }
                            }
                        
                        UserApi.shared.me() {(user, error) in
                                if let error = error {
                                    print(error)
                                }
                                else {
                                    print("me() success.")
                                    
                                    //do something
                                    let userNickname = user?.kakaoAccount?.profile?.nickname
                                    let userEmail = user?.kakaoAccount?.email
                                    let userProfile = user?.kakaoAccount?.profile?.profileImageUrl
                                    
                                    print("닉네임: \(userNickname)")
                                    print("이메일: \(userEmail)")
                                    print("프로필: \(userProfile)")
                                }
                            }

//                        }
                    }
            }
            NavigationLink("회원가입") {
                SignUpView(viewModel: SignUpViewModel(userRepository: DefaultUserRepository.shared))
            }
//            Text("회원가입")
//                .font(.pretendard(.body3))
//                .foregroundStyle(.gray75)
//                .underline(true)
//                .wrapToButton {
//                    
//                }
            Button("프로필") {
                Task {
                    do {
                        let response = try await NetworkManager.executeFetch(target: UserRouter.myProfile, responseType: MyProfileResponse.self, errorType: UserErrorResponse.self)
                        print("🐶", response)
                    } catch {
                        print("🐱", error)
                    }
                }
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
        .background(Color(.systemBackground))
        .onTapGesture {
            print("taptap")
            focusedField = nil
        }
    }
        
}
