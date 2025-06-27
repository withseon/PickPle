//
//  FormatHelper.swift
//  PickPle
//
//  Created by 정인선 on 5/24/25.
//

import Foundation
import CoreLocation

final class FormatHelper {
    enum DistanceUnit {
        case auto, kilometers
    }
    static let shared = FormatHelper()
    
    private let dateFormatter: DateFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    }
    
    func getTime(_ text: String, isDetail: Bool = false) -> String {
        let close = text.split(separator: ":").map { Int($0) }
        guard let inputHour = close[0],
              let inputMinute = close[1] else { return "-" }
        
        let period = inputHour == 24 || inputHour < 12 ? "AM" : "PM"
        var hour = ""
        var minute = ""
        
        switch inputHour {
        case 24:
            hour = "0"
        case 12..<24:
            hour = "\(inputHour - 12)"
        default:
            hour = "\(inputHour)"
        }
        
        switch inputMinute {
        case 0:
            minute = isDetail ? ":00" : ""
        case ..<10:
            minute = ":0\(inputMinute)"
        default:
            minute = ":\(inputMinute)"
        }
        
        return "\(hour)\(minute)\(period)"
    }
    
    func getDistance(latitude: Float, longitude: Float, unit: DistanceUnit) -> String {
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
        return formatDistance(distanceInMeters, unit: unit)
    }
    
    func formatDistance(_ meters: Double, unit: DistanceUnit) -> String {
        switch unit {
        case .auto:
            if meters < 1000 {
                let roundedMeters = ceil(meters / 10) * 10
                return "\(Int(roundedMeters))M"
            } else {
                let kilometers = meters / 1000
                let roundedKilometers = ceil(kilometers * 10) / 10
                return String(format: "%.1fKM", roundedKilometers).replacingOccurrences(of: ".0", with: "")
            }
        case .kilometers:
            let kilometers = meters / 1000
            let roundedKilometers = ceil(kilometers * 10) / 10
            return String(format: "%.1fkM", roundedKilometers).replacingOccurrences(of: ".0", with: "")
        }
    }
    
    func getTimeAgo(from dateString: String) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return "알 수 없음"
        }
        
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 0 {
            return "방금 전"
        }
        
        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7
        let months = days / 30
        let years = days / 365
        
        switch seconds {
        case 0..<60:
            return "방금 전"
        case 60..<3600:
            return "\(minutes)분 전"
        case 3600..<86400:
            return "\(hours)시간 전"
        case 86400..<604800:
            return "\(days)일 전"
        case 604800..<2592000:
            return "\(weeks)주 전"
        case 2592000..<31536000:
            return "\(months)개월 전"
        default:
            return "\(years)년 전"
        }
    }
}
