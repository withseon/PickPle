//
//  SecureTokenManager.swift
//  PickPle
//
//  Created by 정인선 on 5/18/25.
//

import Foundation

typealias TokenKeys = (accessToken: String, refreshToken: String)

protocol SecureTokenManagerable {
    func encryptAndStoreToken(token: String, forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void)
    func encryptAndStoreTokens(accessToken: String, refreshToken: String, forKeys keys: TokenKeys, completion: @escaping (Result<Void, KeychainError>) -> Void)
    func retrieveAndDecryptToken(forKey key: String, completion: @escaping (Result<String, KeychainError>) -> Void)
    func retrieveAndDecryptTokens(forKeys keys: TokenKeys, completion: @escaping (Result<TokenKeys, KeychainError>) -> Void)
    func deleteToken(forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void)
}

final class SecureTokenManager: SecureTokenManagerable {
    static let shared = SecureTokenManager(
        secureEnclaveService: DefaultSecureEnclaveService(),
        keychainService: DefaultKeychainService()
    )
    
    private let secureEnclaveService: SecureEnclaveService
    private let keychainService: KeychainService
    
    // ✅ 토큰 메모리 캐시 (앱 실행 중 토큰 중복 조회 방지) - GCD 완전 제거
    private var tokenCache: [String: String] = [:]
    private var isTokenCached: [String: Bool] = [:]
    private let cacheLock = NSLock()
    
    private init(
        secureEnclaveService: SecureEnclaveService,
        keychainService: KeychainService
    ) {
        self.secureEnclaveService = secureEnclaveService
        self.keychainService = keychainService
    }
    
    func encryptAndStoreToken(token: String, forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void) {
        print("🔐 [SecureTokenManager] encryptAndStoreToken 시작 - key: \(key)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // ✅ DispatchQueue.global() 제거하고 직접 실행
        guard let tokenData = token.data(using: .utf8) else {
            print("❌ [SecureTokenManager] 토큰 데이터 변환 실패")
            completion(.failure(.authFailed))
            return
        }
        
        guard let encryptedData = secureEnclaveService.encryptData(tokenData: tokenData, forKey: key) else {
            print("❌ [SecureTokenManager] \(key) 암호화 실패")
            completion(.failure(.authFailed))
            return
        }
        
        print("🔐 [SecureTokenManager] 암호화 완료, 키체인 저장 시작")
        
        // ✅ 키체인에 암호화된 데이터 저장 (deleteData 메서드가 실제로는 저장을 담당)
        keychainService.storeData(encryptedData, forKey: key) { [weak self] result in
            guard let self else { return }
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            print("🔐 [SecureTokenManager] encryptAndStoreToken 완료 - 소요시간: \(elapsedTime)초")
            
            switch result {
            case .success:
                print("✅ [SecureTokenManager] \(key) 저장 성공")
                
                // ✅ 저장 성공 시 메모리 캐시에도 업데이트 - GCD 완전 제거
                self.cacheLock.lock()
                self.tokenCache[key] = token
                self.isTokenCached[key] = true
                self.cacheLock.unlock()
                print("💾 [SecureTokenManager] 새 토큰 메모리 캐시에 저장 완료 - key: \(key)")
                
                completion(.success(()))
            case .failure(let error):
                print("❌ [SecureTokenManager] \(key) 저장 실패: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func retrieveAndDecryptToken(forKey key: String, completion: @escaping (Result<String, KeychainError>) -> Void) {
        print("🔑 [SecureTokenManager] retrieveAndDecryptToken 시작 - key: \(key)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // ✅ 메모리 캐시에서 먼저 확인 - GCD 완전 제거하고 NSLock 사용
        cacheLock.lock()
        if let cachedToken = tokenCache[key] {
            cacheLock.unlock()
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            print("⚡ [SecureTokenManager] 메모리 캐시에서 토큰 반환 - key: \(key), 소요시간: \(elapsedTime)초 (캐시히트)")
            completion(.success(cachedToken))
            return
        }
        cacheLock.unlock()
        
        print("🔍 [SecureTokenManager] 메모리 캐시에 없음, 키체인에서 조회 - key: \(key)")
        
        // ✅ 즉시 키체인 조회 시작 - 모든 타임아웃과 GCD 완전 제거
        print("🔍 [SecureTokenManager] 키체인 조회 즉시 시작")
        keychainService.retrieveData(forKey: key) { [weak self] result in
            guard let self else { return }
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            print("🔑 [SecureTokenManager] 키체인 조회 완료 - 소요시간: \(elapsedTime)초")
            
            switch result {
            case .success(let encryptedData):
                print("🔑 [SecureTokenManager] 키체인에서 암호화된 데이터 조회 성공, 복호화 시작")
                
                // ✅ 복호화 즉시 실행 - 모든 타임아웃과 DispatchQueue 완전 제거
                print("🔐 [SecureTokenManager] 복호화 직접 실행 시작")
                let decryptStartTime = CFAbsoluteTimeGetCurrent()
                
                if let decryptedData = self.secureEnclaveService.decryptData(encryptData: encryptedData, forKey: key) {
                    let decryptElapsedTime = CFAbsoluteTimeGetCurrent() - decryptStartTime
                    print("🔐 [SecureTokenManager] SecureEnclave decryptData 완료 - 소요시간: \(decryptElapsedTime)초")
                    
                    if let token = String(data: decryptedData, encoding: .utf8) {
                        // ✅ 메모리 캐시에 저장 - GCD 완전 제거하고 NSLock 사용
                        self.cacheLock.lock()
                        self.tokenCache[key] = token
                        self.isTokenCached[key] = true
                        self.cacheLock.unlock()
                        print("💾 [SecureTokenManager] 토큰 메모리 캐시에 저장 완료 - key: \(key)")
                        
                        print("✅ [SecureTokenManager] 복호화 성공 - key: \(key), 토큰: \(token.prefix(10))..., 복호화 시간: \(decryptElapsedTime)초")
                        completion(.success(token))
                    } else {
                        print("❌ [SecureTokenManager] 토큰 문자열 변환 실패")
                        completion(.failure(.authFailed))
                    }
                } else {
                    let decryptElapsedTime = CFAbsoluteTimeGetCurrent() - decryptStartTime
                    print("❌ [SecureTokenManager] SecureEnclave 복호화 실패 - 소요시간: \(decryptElapsedTime)초")
                    completion(.failure(.authFailed))
                }
            case .failure(let error):
                print("❌ [SecureTokenManager] \(key) 키체인 조회 실패: \(error)")
                completion(.failure(.authFailed))
            }
        }
    }
    
    func retrieveAndDecryptTokens(forKeys keys: TokenKeys, completion: @escaping (Result<TokenKeys, KeychainError>) -> Void) {
        keychainService.retrieveData(forKeys: keys) { result in
            switch result {
            case .success(let encryptedData):
                // ✅ DispatchQueue.global() 제거하고 직접 실행
                if let decryptedAccessData = self.secureEnclaveService.decryptData(encryptData: encryptedData.access, forKey: keys.accessToken),
                   let decryptedRefreshData = self.secureEnclaveService.decryptData(encryptData: encryptedData.refresh, forKey: keys.refreshToken),
                   let accessToken = String(data: decryptedAccessData, encoding: .utf8),
                   let refreshToken = String(data: decryptedRefreshData, encoding: .utf8) {
                    print("✅ 복호화된 \(keys.accessToken): \(accessToken)")
                    print("✅ 복호화된 \(keys.refreshToken): \(refreshToken)")
                    completion(.success((accessToken, refreshToken)))
                } else {
                    print("❌ \(keys) 복호화 실패")
                    completion(.failure(.authFailed))
                }
            case .failure:
                print("❌ \(keys) 복호화 실패")
                completion(.failure(.authFailed))
            }
        }
    }
    
    func deleteToken(forKey key: String, completion: @escaping (Result<Void, KeychainError>) -> Void) {
        keychainService.deleteData(forKey: key) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                print("✅ \(key) 데이터 삭제 완료")
                
                // ✅ 삭제 성공 시 메모리 캐시에서도 제거 - GCD 완전 제거
                self.cacheLock.lock()
                self.tokenCache.removeValue(forKey: key)
                self.isTokenCached.removeValue(forKey: key)
                self.cacheLock.unlock()
                print("🗑️ [SecureTokenManager] 토큰 메모리 캐시에서 삭제 완료 - key: \(key)")
                
                completion(.success(()))
            case .failure(let error):
                print("❌ \(key) 데이터 삭제 실패: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    /// 토큰 존재 여부 확인 (디버깅용)
    func checkTokenExists(forKey key: String, completion: @escaping (Bool) -> Void) {
        print("🔍 [SecureTokenManager] 토큰 존재 여부 확인 시작 - key: \(key)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // ✅ 메모리 캐시에서 먼저 확인 - GCD 완전 제거
        cacheLock.lock()
        if isTokenCached[key] == true {
            cacheLock.unlock()
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            print("⚡ [SecureTokenManager] 메모리 캐시에서 토큰 존재 확인 - key: \(key), 소요시간: \(elapsedTime)초 (캐시히트)")
            completion(true)
            return
        }
        cacheLock.unlock()
        
        print("🔍 [SecureTokenManager] 메모리 캐시에 없음, 키체인에서 확인 - key: \(key)")
        
        keychainService.retrieveData(forKey: key) { [weak self] result in
            guard let self else { return }
            let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
            
            switch result {
            case .success(let data):
                print("✅ [SecureTokenManager] 토큰 존재 확인됨 - key: \(key), 크기: \(data.count)bytes, 소요시간: \(elapsedTime)초")
                
                // ✅ 존재 정보를 캐시에 저장 - GCD 완전 제거
                self.cacheLock.lock()
                self.isTokenCached[key] = true
                self.cacheLock.unlock()
                
                completion(true)
            case .failure(let error):
                print("❌ [SecureTokenManager] 토큰 없음 또는 조회 실패 - key: \(key), error: \(error), 소요시간: \(elapsedTime)초")
                
                // ✅ 없음 정보를 캐시에 저장 - GCD 완전 제거
                self.cacheLock.lock()
                self.isTokenCached[key] = false
                self.cacheLock.unlock()
                
                completion(false)
            }
        }
    }
    
    /// 액세스 토큰과 리프레시 토큰을 동시에 암호화하여 저장
    func encryptAndStoreTokens(
        accessToken: String,
        refreshToken: String,
        forKeys keys: TokenKeys,
        completion: @escaping (Result<Void, KeychainError>) -> Void
    ) {
        print("🔐 [SecureTokenManager] encryptAndStoreTokens 시작")
        
        // 리프레시 토큰 먼저 저장
        encryptAndStoreToken(token: refreshToken, forKey: keys.refreshToken) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                print("✅ [SecureTokenManager] 리프레시 토큰 저장 성공")
                
                // 리프레시 토큰 저장 성공 시 액세스 토큰 저장
                self.encryptAndStoreToken(token: accessToken, forKey: keys.accessToken) { result in
                    switch result {
                    case .success:
                        print("✅ [SecureTokenManager] 액세스 토큰 저장 성공 - 모든 토큰 저장 완료")
                        completion(.success(()))
                    case .failure(let error):
                        print("❌ [SecureTokenManager] 액세스 토큰 저장 실패: \(error)")
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                print("❌ [SecureTokenManager] 리프레시 토큰 저장 실패: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    /// 메모리 캐시 초기화 (로그아웃 시 사용)
    func clearTokenCache() {
        cacheLock.lock()
        let cacheCount = tokenCache.count
        tokenCache.removeAll()
        isTokenCached.removeAll()
        cacheLock.unlock()
        print("🧹 [SecureTokenManager] 메모리 캐시 초기화 완료 - 삭제된 토큰 수: \(cacheCount)")
    }
}
