//
//  KeyChainService.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

protocol KeychainService {
    func deleteData(_ tokenData: Data, forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void)
    func retrieveData(forKey key: String, completion: @escaping (Result<Data, KeychainError>) -> Void)
    func deleteData(forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void)
}

final class DefaultKeychainService: KeychainService {
    private let keychainQueue: OperationQueue
    
    init() {
        self.keychainQueue = OperationQueue()
        keychainQueue.maxConcurrentOperationCount = 1
        keychainQueue.qualityOfService = .utility
    }
    
    func deleteData(_ tokenData: Data, forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void) {
        keychainQueue.addOperation {
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
        keychainQueue.addOperation {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecReturnData as String: true
            ]
            
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            
            if status == errSecSuccess, let data = item as? Data {
                completion(.success(data))
            } else {
                completion(.failure(.parse(status)))
            }
        }
    }
    
    func deleteData(forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void) {
        keychainQueue.addOperation {
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
