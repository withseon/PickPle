//
//  ContentView.swift
//  PickPle
//
//  Created by 정인선 on 5/21/25.
//

import SwiftUI
import NMapsMap

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    @State var isChanging = false
    @State private var isMapReady = false
    @State private var pendingLocationUpdate = false
    @State private var hasInitializedMap = false

    let onLocationSelected: (() -> Void)?
    
    var body: some View {
        VStack {
            ZStack {
                NaverMapView(
                    locationManager: locationManager,
                    isChanging: $isChanging,
                    isMapReady: $isMapReady,
                    pendingLocationUpdate: $pendingLocationUpdate,
                    hasInitializedMap: $hasInitializedMap
                )
                .edgesIgnoringSafeArea(.all)
                
                // 지도 로딩 중일 때 표시할 인디케이터
                if !isMapReady {
                    ZStack {
                        Color.black.opacity(0.1)
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                }
                
                Group {
                    MapBalloon()
                        .frame(width: 30, height: 55)
                        .foregroundStyle(isChanging ? .brightForsythia.opacity(0.7) : .brightForsythia)
                    Circle()
                        .fill(isChanging ? .white.opacity(0.7) : .white)
                        .frame(width: 12)
                }
                .offset(y: isChanging ? -20 : -15)
                .opacity(isMapReady ? 1 : 0)
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    locationManager.moveMapToCurrentLocation()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 40)
                        Image(systemName: "location.fill")
                            .foregroundStyle(.black)
                            .fontWeight(.bold)
                    }
                }
                .padding([.bottom, .trailing])
                .opacity(isMapReady ? 1 : 0)
            }
            
            VStack(alignment: .leading, spacing: 30) {
                Group {
                    if locationManager.place.isEmpty && isMapReady {
                        Text("위치 정보를 가져오는 중...")
                            .font(.pretendard(.body1))
                            .foregroundStyle(.gray)
                    } else if !locationManager.place.isEmpty {
                        Text(locationManager.place)
                            .font(.pretendard(.body1))
                    } else {
                        Text("")
                            .font(.pretendard(.body1))
                    }
                }
                .frame(minHeight: 20)
                
                PrimaryButton("이 위치로 설정하기") {
                    locationManager.didSelectedLocation()
                    onLocationSelected?()
                    dismiss()
                }
                .disabled(isChanging || locationManager.place.isEmpty)
            }
            .padding()
        }
        .onAppear {
            // UserDefaults에 위치가 없을 때만 현재 위치 요청
            if UserDefaultsManager.selectedLocation == nil {
                locationManager.startLocationForMap()
                pendingLocationUpdate = true
            }
        }
        .onDisappear {
            locationManager.stopLocationUpdates()
        }
    }
}

private struct MapBalloon: Shape {
    var startAngle: Angle = .degrees(180)
    var endAngle: Angle = .degrees(0)

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.midY),
                      control1: CGPoint(x: rect.midX, y: rect.maxY),
                      control2: CGPoint(x: rect.minX, y: rect.midY + rect.height / 5))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2,
                    startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                      control1: CGPoint(x: rect.maxX, y: rect.midY + rect.height / 5),
                      control2: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

struct NaverMapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    @Binding var isChanging: Bool
    @Binding var isMapReady: Bool
    @Binding var pendingLocationUpdate: Bool
    @Binding var hasInitializedMap: Bool
    
    func makeUIView(context: Context) -> NMFNaverMapView {
        let mapView = NMFNaverMapView()
        mapView.mapView.positionMode = .disabled
        mapView.mapView.zoomLevel = 17
        mapView.showZoomControls = false
        
        mapView.mapView.touchDelegate = context.coordinator
        mapView.mapView.addCameraDelegate(delegate: context.coordinator)
        
        // 지도 초기화 완료 후 위치 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            setupInitialLocation(mapView: mapView)
            isMapReady = true
            hasInitializedMap = true
        }
        
        return mapView
    }
    
    private func setupInitialLocation(mapView: NMFNaverMapView) {
        // 1. 기존에 선택된 위치가 있으면 우선 사용
        if let selectedLocation = UserDefaultsManager.selectedLocation {
            let coord = NMGLatLng(
                lat: selectedLocation.latitude,
                lng: selectedLocation.longitude
            )
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeIn
            mapView.mapView.moveCamera(cameraUpdate)
            
            // 주소 정보도 업데이트
            let location = CLLocation(latitude: selectedLocation.latitude, longitude: selectedLocation.longitude)
            locationManager.convertLocationToAddress(location: location)
            return
        }
        
        // 2. 현재 위치가 있으면 사용
        if let location = locationManager.location {
            let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeIn
            mapView.mapView.moveCamera(cameraUpdate)
            
            locationManager.convertLocationToAddress(location: location)
            pendingLocationUpdate = false
            return
        }
        
        // 3. 위치 정보가 없으면 서울 중심으로 기본 설정
        let defaultCoord = NMGLatLng(lat: 37.5665, lng: 126.9780)
        let cameraUpdate = NMFCameraUpdate(scrollTo: defaultCoord)
        mapView.mapView.moveCamera(cameraUpdate)
    }
    
    func updateUIView(_ mapView: NMFNaverMapView, context: Context) {
        // moveToCurrentLocation 플래그가 true이고 위치가 있으면 현재 위치로 이동
        if locationManager.moveToCurrentLocation, let location = locationManager.location {
            let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeIn
            mapView.mapView.moveCamera(cameraUpdate)
        }
        
        // 수정: UserDefaults에 위치가 없고, 초기화가 완료된 후에만 현재 위치로 이동
        if pendingLocationUpdate,
           let location = locationManager.location,
           isMapReady,
           hasInitializedMap,
           UserDefaultsManager.selectedLocation == nil { // 이 조건 추가!
            
            let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeIn
            mapView.mapView.moveCamera(cameraUpdate)
            
            DispatchQueue.main.async {
                pendingLocationUpdate = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(locationManager: locationManager, parent: self, isChanging: $isChanging, pendingLocationUpdate: $pendingLocationUpdate)
    }
    
    class Coordinator: NSObject, NMFMapViewTouchDelegate, NMFMapViewCameraDelegate {
        @ObservedObject var locationManager: LocationManager
        @Binding var isChanging: Bool
        @Binding var pendingLocationUpdate: Bool
        
        var parent: NaverMapView
        
        init(locationManager: LocationManager, parent: NaverMapView, isChanging: Binding<Bool>, pendingLocationUpdate: Binding<Bool>) {
            self.locationManager = locationManager
            self.parent = parent
            self._isChanging = isChanging
            self._pendingLocationUpdate = pendingLocationUpdate
        }
        
        func mapView(_ mapView: NMFMapView, cameraWillChangeByReason reason: Int, animated: Bool) {
            DispatchQueue.main.async {
                self.isChanging = true
            }
        }
        
        func mapViewCameraIdle(_ mapView: NMFMapView) {
            let location = CLLocation(latitude: mapView.latitude, longitude: mapView.longitude)
            locationManager.convertLocationToAddress(location: location)
            
            DispatchQueue.main.async {
                self.isChanging = false
            }
        }
    }
}
