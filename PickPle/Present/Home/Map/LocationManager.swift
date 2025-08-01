//
//  LocationManager.swift
//  PickPle
//
//  Created by 정인선 on 5/21/25.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var tempLocation: CLLocation?
    private var tempPlace: String = ""
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var moveToCurrentLocation: Bool = false
    @Published var place: String = ""
    @Published var showAlert = false
    
    // 권한 변경 시 콜백을 위한 클로저
    private var authorizationCallback: ((Bool) -> Void)?
    
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
    }
    
    deinit {
        print("locationManager Deinit")
        stopLocationUpdates()
    }
    
    // 위치 추적 시작 (맵 사용 시에만)
    private func startLocationUpdates() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
    }
    
    // 위치 추적 중지
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    // 위치 권한 요청 (추적은 시작하지 않음)
    func requestLocationPermission(completion: @escaping (Bool) -> Void) {
        // 이미 권한이 허용된 경우
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            completion(true)
            return
        }
        
        // 권한이 거부된 경우
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            showAlert = true
            completion(false)
            return
        }
        
        // 권한이 아직 결정되지 않은 경우 - 콜백 설정 후 권한 요청
        authorizationCallback = completion
        locationManager.requestWhenInUseAuthorization()
    }
    
    // 맵 사용 시에만 위치 추적 시작
    func startLocationForMap() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        startLocationUpdates()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        // 권한 요청에 대한 응답 처리 (추적은 시작하지 않음)
        if let callback = authorizationCallback {
            switch authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                callback(true)
            case .denied, .restricted:
                showAlert = true
                callback(false)
            case .notDetermined:
                return
            @unknown default:
                callback(false)
            }
            authorizationCallback = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        self.location = newLocation
    }
    
    func moveMapToCurrentLocation() {
        if location == nil {
            startLocationUpdates()
        }
        
        moveToCurrentLocation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.moveToCurrentLocation = false
        }
    }
    
    func convertLocationToAddress(location: CLLocation) {
        tempLocation = location

        GeocodingService.shared.convertToAddress(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ) { [weak self] result in
            guard let self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let address):
                    self.place = address
                    // tempPlace는 subLocality + name 형태로 저장
                    let components = address.split(separator: " ")
                    if components.count >= 2 {
                        self.tempPlace = components.dropFirst().joined(separator: " ")
                    } else {
                        self.tempPlace = address
                    }

                case .failure:
                    self.place = "주소를 가져올 수 없습니다"
                }
            }
        }
    }
    
    func didSelectedLocation() {
        if let tempLocation {
            let location = Location(
                latitude: tempLocation.coordinate.latitude,
                longitude: tempLocation.coordinate.longitude,
                address: tempPlace
            )
            UserDefaultsManager.selectedLocation = location
        }
    }
}
