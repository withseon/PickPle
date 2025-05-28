//
//  PickPleApp.swift
//  PickPle
//
//  Created by 정인선 on 5/9/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct PickPleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var isActive = false
    
    init() {
        let nativeAppKey = Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String ?? ""
        KakaoSDK.initSDK(appKey: nativeAppKey)
    }
    
    var body: some Scene {
        WindowGroup {
            if isActive {
//                MainTabView()
                NavigationStack {
                    SignInView(viewModel: SignInViewModel(userRepository: DefaultUserRepository.shared))
                        .onOpenURL(perform: { url in
                            if AuthApi.isKakaoTalkLoginUrl(url) {
                                _ = AuthController.handleOpenUrl(url: url)
                            }
                        })
                }
            } else {
                SplashView()
                    .onAppear {
                        // 2초 후에 메인 화면으로 전환
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    }
            }
        }
    }
}
