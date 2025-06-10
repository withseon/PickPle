//
//  ContentView.swift
//  PickPle
//
//  Created by 정인선 on 5/21/25.
//

import SwiftUI
import NMapsMap

struct MapView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var locationManager: LocationManager
    @State var isChanging = false
    
    let onLocationSelected: (() -> Void)?
    
    var body: some View {
        VStack {
            ZStack {
                NaverMapView(locationManager: locationManager, isChanging: $isChanging)
                    .edgesIgnoringSafeArea(.all)
                Group {
                    MapBalloon()
                        .frame(width: 30, height: 55)
                        .foregroundStyle(isChanging ? .brightForsythia.opacity(0.7) : .brightForsythia)
                    Circle()
                        .fill(isChanging ? .white.opacity(0.7) : .white)
                        .frame(width: 12)
                }
                .offset(y: isChanging ? -20 : -15)
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
            }
            VStack(alignment: .leading, spacing: 30) {
                Text(locationManager.place)
                    .font(.pretendard(.body1))
                PrimaryButton("이 위치로 설정하기") {
                    locationManager.didSelectedLocation()
                    onLocationSelected?()
                    dismiss()
                }
                .disabled(isChanging)
            }
            .padding()
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
    
    func makeUIView(context: Context) -> NMFNaverMapView {
        let mapView = NMFNaverMapView()
        mapView.mapView.positionMode = .disabled
        mapView.mapView.zoomLevel = 17
        mapView.showZoomControls = false
        
        mapView.mapView.touchDelegate = context.coordinator
        mapView.mapView.addCameraDelegate(delegate: context.coordinator)
        
        if let selectedLocation = UserDefaultsManager.selectedLocation {
            let coord = NMGLatLng(
                lat: selectedLocation.latitude,
                lng: selectedLocation.longitude
            )
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeIn
            mapView.mapView.moveCamera(cameraUpdate)
            return mapView
        }
        
        if let location = locationManager.location {
            let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeIn
            mapView.mapView.moveCamera(cameraUpdate)
            return mapView
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: NMFNaverMapView, context: Context) {
        // moveToCurrentLocation 플래그가 true이고 위치가 있으면 현재 위치로 이동
        if locationManager.moveToCurrentLocation, let location = locationManager.location {
            let coord = NMGLatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeIn
            mapView.mapView.moveCamera(cameraUpdate)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(locationManager: locationManager, parent: self, isChanging: $isChanging)
    }
    
    class Coordinator: NSObject, NMFMapViewTouchDelegate, NMFMapViewCameraDelegate {
        @ObservedObject var locationManager: LocationManager
        @Binding var isChanging: Bool
        
        var parent: NaverMapView
        
        init(locationManager: LocationManager, parent: NaverMapView, isChanging: Binding<Bool>) {
            self.locationManager = locationManager
            self.parent = parent
            self._isChanging = isChanging
        }
        
        func mapView(_ mapView: NMFMapView, cameraWillChangeByReason reason: Int, animated: Bool) {
            DispatchQueue.main.async {
                self.isChanging = true
            }
        }
        
        func mapViewCameraIdle(_ mapView: NMFMapView) {
            locationManager.convertLocationToAddress(location: CLLocation(latitude: mapView.latitude, longitude: mapView.longitude))
            isChanging = false
        }
    }
}
