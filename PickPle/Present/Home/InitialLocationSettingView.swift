//
//  SetLocationView.swift
//  PickPle
//
//  Created by 정인선 on 5/21/25.
//

import SwiftUI

struct InitialLocationSettingView: View {
    @StateObject var locationManager = LocationManager()
    @State private var showMapSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("서비스 이용을 위해\n현재 위치를 설정해주세요.")
                        .font(.pretendard(.title))
                    Spacer()
                }
                Text("근처에 있는 가게를 확인할 수 있어요.")
                    .font(.pretendard(.body1))
            }
            PrimaryButton(
                "현재 위치 설정하기",
                backgroundColor: .gray100,
                foregroundColor: .gray0
            ) {
                initializeLocationAndShowMap()
            }
            Spacer()
        }
        .padding(20)
        .sheet(isPresented: $showMapSheet) {
            MapView(locationManager: locationManager)
        }
        .alert("위치 기반 서비스를 사용하려면 위치 권한이 필요합니다.", isPresented: $locationManager.showAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) {}
        }
    }
    
    private func initializeLocationAndShowMap() {
        locationManager.initialLocationManager()
        
        Task {
            if locationManager.authorizationStatus == .authorizedWhenInUse ||
                locationManager.authorizationStatus == .authorizedAlways {
                
                // 위치 정보가 없으면 가져올 때까지 기다림 (최대 2초)
                var attempts = 0
                while locationManager.location == nil && attempts < 20 {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    attempts += 1
                }
                
                await MainActor.run {
                    if locationManager.location != nil {
                        showMapSheet = true
                    } else {
                        print("위치 정보를 가져오지 못했습니다.")
                    }
                }
            }
        }
    }
}


