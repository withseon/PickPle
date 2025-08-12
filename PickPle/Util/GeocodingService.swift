//
//  GeocodingService.swift
//  PickPle
//
//  Created by 정인선 on 6/2/25.
//

import Foundation
import CoreLocation

final class GeocodingService {
    static let shared = GeocodingService()

    private let geocoder = CLGeocoder()
    private var cache: [String: String] = [:] // 위경도 → 주소 캐싱

    private init() {}

    /// 위경도를 주소로 변환 (completion handler 방식)
    func convertToAddress(
        latitude: Double,
        longitude: Double,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let cacheKey = "\(latitude),\(longitude)"

        // 캐시 확인
        if let cachedAddress = cache[cacheKey] {
            completion(.success(cachedAddress))
            return
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let placemark = placemarks?.first else {
                completion(.failure(GeocodingError.noPlacemark))
                return
            }

            let address = self?.formatAddress(from: placemark) ?? "주소를 가져올 수 없습니다"

            // 캐시 저장
            self?.cache[cacheKey] = address

            completion(.success(address))
        }
    }

    /// 위경도를 주소로 변환 (async/await 방식)
    func convertToAddress(latitude: Double, longitude: Double) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            convertToAddress(latitude: latitude, longitude: longitude) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func formatAddress(from placemark: CLPlacemark) -> String {
        let locality = placemark.locality ?? ""           // 시/군 (예: "서울특별시")
        let subLocality = placemark.subLocality ?? ""     // 구 (예: "강남구")
        let name = placemark.name?.replacingOccurrences(of: subLocality, with: "") ?? "" // 상세 주소

        // "서울특별시 강남구 역삼동" 형태로 반환 (기존 LocationManager와 동일)
        return "\(locality) \(subLocality) \(name)".trimmingCharacters(in: .whitespaces)
    }

    enum GeocodingError: Error {
        case noPlacemark

        var localizedDescription: String {
            switch self {
            case .noPlacemark:
                return "주소를 가져올 수 없습니다"
            }
        }
    }
}
