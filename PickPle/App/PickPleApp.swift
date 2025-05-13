//
//  PickPleApp.swift
//  PickPle
//
//  Created by 정인선 on 5/9/25.
//

import SwiftUI

@main
struct PickPleApp: App {
    @State private var isActive = false
    
    var body: some Scene {
        WindowGroup {
            if isActive {
                MainTabView()
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
