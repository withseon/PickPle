//
//  SetLocationView.swift
//  PickPle
//
//  Created by 정인선 on 5/21/25.
//

import SwiftUI

struct InitialLocationSettingView: View {
    @EnvironmentObject private var locationCoordinator: LocationCoordinator
    @StateObject private var locationManager = LocationManager()

    var onLocationSelected: (() -> Void)?
    
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
                locationManager.requestLocationPermission { isAuthorized in
                    if isAuthorized {
                        locationCoordinator.presentSheet(LocationSheetRoute.map({
                            onLocationSelected?()
                        }))
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .alert("위치 기반 서비스를 사용하려면 위치 권한이 필요합니다.", isPresented: $locationManager.showAlert) {
            Button("설정으로 이동") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("설정에서 위치 권한을 허용해주세요.")
        }
        .onChange(of: locationManager.authorizationStatus) { newValue in
            if newValue == .authorizedWhenInUse || newValue == .authorizedAlways {
                locationManager.showAlert = false
            }
        }
    }
}
