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
    
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }
    
    deinit {
        print("locationManager Deinit")
        locationManager.stopUpdatingLocation()
    }
    
    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            showAlert = true
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func initialLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        checkLocationAuthorization()
    }
    
    func requestLocationAndExecute(completion: @escaping (Bool) -> Void) {
        initialLocationManager()
        
        Task {
            if authorizationStatus == .authorizedWhenInUse ||
               authorizationStatus == .authorizedAlways {
                
                // 위치 정보가 없으면 가져올 때까지 기다림 (최대 2초)
                var attempts = 0
                while location == nil && attempts < 20 {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    attempts += 1
                }
                
                await MainActor.run {
                    completion(location != nil)
                }
            } else {
                await MainActor.run {
                    completion(false)
                }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        self.location = newLocation
    }
    
    func moveMapToCurrentLocation() {
        if location == nil {
            locationManager.startUpdatingLocation()
        }
        
        moveToCurrentLocation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.moveToCurrentLocation = false
        }
    }
    
    func convertLocationToAddress(location: CLLocation) {
        tempLocation = location
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self else { return }
            
            if error != nil {
                return
            }
            guard let placemark = placemarks?.first else { return }
            let locality = placemark.locality ?? ""
            let subLocality = placemark.subLocality ?? ""
            let name = placemark.name?.replacingOccurrences(of: subLocality, with: "") ?? ""
            place = "\(locality) \(subLocality) \(name)"
            tempPlace = "\(subLocality) \(name)"
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
