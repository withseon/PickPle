//
//  UserDefaultsManager.swift
//  PickPle
//
//  Created by 정인선 on 5/24/25.
//

import Foundation

struct UserDefaultsManager {
    private enum Key: String {
        case userId
        case userProfile
        case selectedLocation
        case hasRunBefore
    }
    
    @UserDefaultStringWrapper(key: Key.userId.rawValue, defaultValue: nil)
    static var userId: String?
    
    @UserDefaultWrapper(key: Key.userProfile.rawValue, defaultValue: nil)
    static var userProfile: UserProfile?
    
    @UserDefaultWrapper(key: Key.selectedLocation.rawValue, defaultValue: nil)
    static var selectedLocation: Location?
    
    @UserDefaultBoolWrapper(key: Key.hasRunBefore.rawValue, defaultValue: false)
    static var hasRunBefore: Bool
    
    // MARK: - App Initialization
    static func resetKeychainIfNeeded() {
        if !hasRunBefore {
            // ✅ 앱이 처음 실행된 경우 (설치 후 최초 실행)
            print("🆕 앱 최초 설치 감지 - 키체인 토큰 삭제 중...")
            clearKeychainTokens()
            hasRunBefore = true
        } else {
            print("✅ 기존 사용자 - 키체인 토큰 유지")
        }
    }
    
    private static func clearKeychainTokens() {
        // 백그라운드에서 비동기로 실행 (앱 초기화를 블록하지 않음)
        Task.detached(priority: .background) {
            do {
                // Access Token 삭제
                try await TokenManager.shared.delete(forKey: SecureKey.ACCESS_TOKEN)
                print("✅ Access Token 삭제 완료")

                // Refresh Token 삭제
                try await TokenManager.shared.delete(forKey: SecureKey.REFRESH_TOKEN)
                print("✅ Refresh Token 삭제 완료")

                print("✅ 키체인 토큰 초기화 완료")
            } catch {
                print("❌ 키체인 토큰 삭제 실패: \(error)")
            }
        }
    }
}

// MARK: - Property Wrappers
@propertyWrapper
struct UserDefaultStringWrapper {
    let key: String
    let defaultValue: String?
    
    init(key: String, defaultValue: String?) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: String? {
        get {
            return UserDefaults.standard.string(forKey: key) ?? defaultValue
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

@propertyWrapper
struct UserDefaultWrapper<T: Codable> {
    let key: String
    let defaultValue: T?
    
    init(key: String, defaultValue: T?) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T? {
        get {
            if let savedData = UserDefaults.standard.object(forKey: key) as? Data {
                let decoder = JSONDecoder()
                if let savedObject = try? decoder.decode(T.self, from: savedData) {
                    return savedObject
                }
            }
            return defaultValue
        }
        set {
            if let newValue {
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(newValue) {
                    UserDefaults.standard.set(encoded, forKey: key)
                }
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

@propertyWrapper
struct UserDefaultBoolWrapper {
    let key: String
    let defaultValue: Bool
    
    init(key: String, defaultValue: Bool) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: Bool {
        get {
            // Bool의 경우 기본값을 확인하는 방법이 다름
            if UserDefaults.standard.object(forKey: key) == nil {
                return defaultValue
            }
            return UserDefaults.standard.bool(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
