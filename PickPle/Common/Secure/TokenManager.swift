//
//  TokenManager.swift
//  PickPle
//
//  Created by 정인선 on 8/29/25.
//

import Foundation

// MARK: - Token Manager Actor
actor TokenManager {
    static let shared = TokenManager()

    // 메모리 캐시 (Actor-isolated로 자동 동기화)
    private var tokenCache: [String: String] = [:]

    private init() {
        print("[TokenManager] 초기화 완료 (Actor 기반)")
    }

    // MARK: - Public Method

    /// 토큰 저장
    func save(_ token: String, forKey key: String) async throws {
        print("[TokenManager] 토큰 저장 시작 - key: \(key)")

        // 1. Keychain에 저장 (실패 시 예외 발생)
        try await saveToKeychain(token, forKey: key)

        // 2. Keychain 저장 성공 시에만 메모리 캐시에 저장
        tokenCache[key] = token

        print("[TokenManager] 토큰 저장 완료 - key: \(key)")
    }

    /// 토큰 조회
    func retrieve(forKey key: String) async throws -> String {
        print("[TokenManager] 토큰 조회 시작 - key: \(key)")

        // 1. 메모리 캐시 체크
        if let cached = tokenCache[key] {
            print("[TokenManager] 메모리 캐시 히트 - key: \(key)")
            return cached
        }

        // 2. Keychain에서 조회
        print("[TokenManager] 메모리 캐시 미스, Keychain 조회 - key: \(key)")
        let token = try await loadFromKeychain(forKey: key)

        // 3. 메모리 캐시에 저장
        tokenCache[key] = token
        
        print("[TokenManager] 토큰 조회 완료 - key: \(key)")
        return token
    }

    /// 토큰 삭제
    func delete(forKey key: String) async throws {
        print("[TokenManager] 토큰 삭제 시작 - key: \(key)")

        // 1. 메모리 캐시에서 먼저 삭제 (Keychain 삭제 실패해도 캐시는 무효화)
        tokenCache.removeValue(forKey: key)

        // 2. Keychain에서 삭제 (실패 시 예외 발생하지만 캐시는 이미 제거됨)
        try await deleteFromKeychain(forKey: key)

        print("[TokenManager] 토큰 삭제 완료 - key: \(key)")
    }

    /// 메모리 캐시 초기화 (로그아웃 시 사용)
    func clearCache() {
        let count = tokenCache.count
        tokenCache.removeAll()
        print("[TokenManager] 메모리 캐시 초기화 완료 - 삭제된 토큰 수: \(count)")
    }

    /// 토큰 존재 여부 확인
    func exists(forKey key: String) async -> Bool {
        // 메모리 캐시 확인
        if tokenCache[key] != nil {
            return true
        }

        // Keychain 확인
        do {
            _ = try await loadFromKeychain(forKey: key)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private Keychain Operations

    /// Keychain에 토큰 저장
    /// 기존 항목이 있으면 삭제 후 새로 추가
    private func saveToKeychain(_ token: String, forKey key: String) async throws {
        guard let data = token.data(using: .utf8) else {
            print("❌ [TokenManager] Keychain 저장 실패 - encodingFailed")
            throw TokenError.encodingFailed
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked // 디바이스 잠금 시 접근 불가
        ]

        // 기존 항목 삭제 (중복 방지)
        SecItemDelete(query as CFDictionary)

        // 새 항목 추가
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("❌ [TokenManager] Keychain 저장 실패 - \(TokenError(status: status).localizedDescription)")
            throw TokenError(status: status)
        }
    }

    /// Keychain에서 토큰 조회
    private func loadFromKeychain(forKey key: String) async throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            let error = TokenError(status: status)
            print("❌ [TokenManager] Keychain 조회 실패 - key: \(key), \(error.localizedDescription)")
            throw error
        }

        guard let data = item as? Data else {
            print("❌ [TokenManager] Keychain 조회 실패 - key: \(key), decodingFailed")
            throw TokenError.decodingFailed
        }

        guard let token = String(data: data, encoding: .utf8) else {
            print("❌ [TokenManager] Keychain 조회 실패 - key: \(key), decodingFailed")
            throw TokenError.decodingFailed
        }

        return token
    }

    /// Keychain에서 토큰 삭제
    /// 항목이 없어도 에러를 발생시키지 않음 (errSecItemNotFound 허용)
    private func deleteFromKeychain(forKey key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            let error = TokenError(status: status)
            print("❌ [TokenManager] Keychain 삭제 실패 - key: \(key), \(error.localizedDescription)")
            throw error
        }
    }
}
