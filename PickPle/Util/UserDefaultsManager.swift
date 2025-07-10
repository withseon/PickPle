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
        case selectedLocation
    }
    
    @UserDefaultStringWrapper(key: Key.userId.rawValue, defaultValue: nil)
    static var userId: String?
    
    @UserDefaultWrapper(key: Key.selectedLocation.rawValue, defaultValue: nil)
    static var selectedLocation: Location?
}

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
