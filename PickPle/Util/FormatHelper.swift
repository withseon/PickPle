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
    private let koreanTimeFormatter: DateFormatter

    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        // 한국 시간 변환용 formatter 추가
        koreanTimeFormatter = DateFormatter()
        koreanTimeFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        koreanTimeFormatter.locale = Locale(identifier: "en_US")
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
        
    func getChatTime(from utcString: String) -> String {
        // "9999-05-06T05:13:54.357Z"
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        var date = dateFormatter.date(from: utcString)
        
        guard let date = dateFormatter.date(from: utcString) else {
            return ""
        }
        
        // 한국 시간으로 변환
        koreanTimeFormatter.dateFormat = "hh:mma"
        return koreanTimeFormatter.string(from: date)
    }

    
    /// UTC 문자열에서 날짜 부분만 추출 (yyyy-MM-dd 형식)
    func getDateFromUTC(_ utcString: String) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        guard let date = dateFormatter.date(from: utcString) else {
            return ""
        }

        // 한국 시간으로 변환하여 날짜 추출
        koreanTimeFormatter.dateFormat = "yyyy-MM-dd"
        return koreanTimeFormatter.string(from: date)
    }

    /// 날짜 구분선 포맷팅 (yyyy년 M월 d일)
    func formatDateSeparator(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy년 M월 d일"
        outputFormatter.locale = Locale(identifier: "ko_KR")

        return outputFormatter.string(from: date)
    }

    /// 주문 날짜/시간 포맷팅 (2025년 4월 22일 오후 6:26)
    func formatOrderDateTime(_ utcString: String) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        guard let date = dateFormatter.date(from: utcString) else {
            return ""
        }

        // 한국 시간으로 변환
        koreanTimeFormatter.dateFormat = "yyyy년 M월 d일 a h:mm"
        koreanTimeFormatter.locale = Locale(identifier: "ko_KR")
        return koreanTimeFormatter.string(from: date)
    }

    /// 특정 시간으로부터 30분 이내인지 확인
    func isWithin30Minutes(from utcString: String) -> Bool {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        guard let date = dateFormatter.date(from: utcString) else {
            return false
        }

        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        // 30분 = 1800초
        return timeInterval <= 1800 && timeInterval >= 0
    }

    /// 게시글 날짜 포맷팅 (방금 전, n분 전, n시간 전, MM월 dd일)
    func formatPostDate(_ utcString: String) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        guard let date = dateFormatter.date(from: utcString) else {
            return ""
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

        switch seconds {
        case 0..<60:
            return "방금 전"
        case 60..<3600:
            return "\(minutes)분 전"
        case 3600..<86400:
            return "\(hours)시간 전"
        default:
            // 1일 이상이면 날짜 표시 (MM월 dd일)
            koreanTimeFormatter.dateFormat = "M월 d일"
            koreanTimeFormatter.locale = Locale(identifier: "ko_KR")
            return koreanTimeFormatter.string(from: date)
        }
    }

    /// 댓글 날짜/시간 포맷팅 (방금 전, n분 전, n시간 전, MM월 dd일 HH:mm)
    func formatCommentDateTime(_ utcString: String) -> String {
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        guard let date = dateFormatter.date(from: utcString) else {
            return ""
        }

        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        if timeInterval < 0 {
            return "방금 전"
        }

        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let hours = minutes / 60

        switch seconds {
        case 0..<60:
            return "방금 전"
        case 60..<3600:
            return "\(minutes)분 전"
        case 3600..<86400:
            return "\(hours)시간 전"
        default:
            // 1일 이상이면 날짜와 시간 표시 (MM월 dd일 HH:mm)
            koreanTimeFormatter.dateFormat = "M월 d일 HH:mm"
            koreanTimeFormatter.locale = Locale(identifier: "ko_KR")
            return koreanTimeFormatter.string(from: date)
        }
    }
}
