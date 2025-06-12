//
//  FormatHelper.swift
//  PickPle
//
//  Created by 정인선 on 5/24/25.
//

import Foundation
import CoreLocation

enum FormatHelper {
    static func closeTime(_ text: String) -> String {
        let close = text.split(separator: ":").map { Int($0) }
        guard let inputHour = close[0],
              let inputMinute = close[1] else { return "-" }
        
        let period = inputHour == 24 || inputHour < 12 ? "AM" : "PM"
        var hour = "0"
        let minute = inputMinute == 0 ? "" : ":\(inputMinute)"
        
        switch inputHour {
        case 24:
            hour = "0"
        case 12..<24:
            hour = "\(inputHour - 12)"
        default:
            hour = "\(inputHour)"
        }
        
        return "\(hour)\(minute)\(period)"
    }
    
    static func getDistance(latitude: Float, longitude: Float) -> String {
        guard let currentLocation = UserDefaultsManager.selectedLocation else { return "-" }
        
        let startLocation = CLLocation(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude
        )
        let endLocation = CLLocation(
            latitude: Double(latitude),
            longitude: Double(longitude)
        )
        
        let distanceInMeters = startLocation.distance(from: endLocation)
        return formatDistance(distanceInMeters)
    }

    static func formatDistance(_ meters: Double) -> String {
        let kilometers = meters / 1000
        let roundedKilometers = ceil(kilometers * 10) / 10
        return String(format: "%.1fkm", roundedKilometers)
    }}
