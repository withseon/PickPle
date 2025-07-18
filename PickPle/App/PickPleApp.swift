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
    @StateObject private var appCoordinator = AppCoordinator()
    @State private var isActive = false
    
    init() {
        let nativeAppKey = Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String ?? ""
        KakaoSDK.initSDK(appKey: nativeAppKey)
    }
    
    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: appCoordinator)
                .onOpenURL(perform: { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                })
                .onAppear {
                    delegate.appCoordinator = appCoordinator
                }
        }
    }
}
