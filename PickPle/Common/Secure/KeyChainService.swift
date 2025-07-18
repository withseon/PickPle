//
//  KeyChainService.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

protocol KeychainService {
    func storeData(_ tokenData: Data, forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void)
    func retrieveData(forKey key: String, completion: @escaping (Result<Data, KeychainError>) -> Void)
    func deleteData(forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void)
    func retrieveData(forKeys keys: TokenKeys, completion: @escaping (Result<(access: Data,refresh: Data), KeychainError>) -> Void)
}

final class DefaultKeychainService: KeychainService {
    private let keychainQueue: DispatchQueue
    
    init() {
        self.keychainQueue = DispatchQueue(label: "com.pickple.keychain", qos: .utility)
        print("🔐 [KeychainService] DefaultKeychainService 초기화 완료")
    }
    
    func storeData(_ tokenData: Data, forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void) {
        print("🔐 [KeychainService] deleteData 시작 - key: \(key)")
        keychainQueue.async {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: tokenData
            ]
            
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            
            if status == errSecSuccess {
                completion(.success(()))
            } else {
                completion(.failure(.parse(status)))
            }
        }
    }
    
    func retrieveData(forKey key: String, completion: @escaping (Result<Data, KeychainError>) -> Void) {
        print("🔐 [KeychainService] retrieveData 시작 - key: \(key)")
        let startTime = CFAbsoluteTimeGetCurrent() // 소요 시간 측정
        
        keychainQueue.async {
            let operationStartTime = CFAbsoluteTimeGetCurrent()
            print("🔐 [KeychainService] DispatchQueue 작업 시작 - 대기시간: \(operationStartTime - startTime)초")
            
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true
            ]
            
            print("🔐 [KeychainService] SecItemCopyMatching 호출 시작")
            var item: CFTypeRef?
            let secCallStartTime = CFAbsoluteTimeGetCurrent() // 소요 시간 측정
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            let secCallElapsedTime = CFAbsoluteTimeGetCurrent() - secCallStartTime // 소요 시간 측정
            
            print("🔐 [KeychainService] SecItemCopyMatching 완료 - 소요시간: \(secCallElapsedTime)초, status: \(status)")
            
            let totalElapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            
            if status == errSecSuccess, let data = item as? Data {
                print("✅ [KeychainService] 키체인 조회 성공 - key: \(key), 데이터 크기: \(data.count)bytes, 총 소요시간: \(totalElapsedTime)초")
                completion(.success(data))
            } else {
                print("❌ [KeychainService] 키체인 조회 실패 - key: \(key), status: \(status), 에러: \(SecCopyErrorMessageString(status, nil) ?? "Unknown" as CFString), 총 소요시간: \(totalElapsedTime)초")
                completion(.failure(.parse(status)))
            }
        }
    }
    
    func retrieveData(forKeys keys: TokenKeys, completion: @escaping (Result<(access: Data, refresh: Data), KeychainError>) -> Void) {
        print("🔐 [KeychainService] retrieveData(forKeys:) 시작")
        keychainQueue.async {
            let accessQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keys.accessToken,
                kSecReturnData as String: true
            ]
            
            let refreshQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keys.refreshToken,
                kSecReturnData as String: true
            ]
            
            var accessItem: CFTypeRef?
            var refreshItem: CFTypeRef?
            let accessStatus = SecItemCopyMatching(accessQuery as CFDictionary, &accessItem)
            let refreshStatus = SecItemCopyMatching(refreshQuery as CFDictionary, &refreshItem)
            
            if accessStatus == errSecSuccess, let accessData = accessItem as? Data,
               refreshStatus == errSecSuccess, let refreshData = refreshItem as? Data {
                completion(.success((accessData, refreshData)))
            } else {
                completion(.failure(.parse(accessStatus)))
            }
        }
    }
    
    func deleteData(forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void) {
        print("🔐 [KeychainService] deleteData(forKey:) 시작 - key: \(key)")
        keychainQueue.async {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]
            let status = SecItemDelete(query as CFDictionary)
            
            if status == errSecSuccess {
                completion(.success(()))
            } else {
                completion(.failure(.parse(status)))
            }
        }
    }
}
