//
//  UnifiedMediaCacheManager.swift
//  PickPle
//
//  Created by Claude on 8/29/25.
//

import SwiftUI
import Foundation
import UIKit

// MARK: - 통합 미디어 관련 타입 정의
extension UnifiedMediaCacheManager {
    
    // MARK: - 통합 이미지 로드 결과
    struct ImageLoadResult {
        let image: UIImage
        let originalData: Data
        let detectedFormat: DetectedMediaFormat
        let isAnimatedGIF: Bool
    }
    
    // MARK: - 통합 미디어 포맷 감지
    enum DetectedMediaFormat {
        case jpeg, png, gif, webp, mp4, mov, avi, mkv, wmv, pdf, unknown
        
        var isImage: Bool {
            switch self {
            case .jpeg, .png, .gif, .webp: return true
            default: return false
            }
        }
        
        var isVideo: Bool {
            switch self {
            case .mp4, .mov, .avi, .mkv, .wmv: return true
            default: return false
            }
        }
        
        static func detect(from data: Data) -> DetectedMediaFormat {
            // ImageCacheManager의 DetectedImageFormat.detect() 로직 재사용 + 동영상 확장
            if data.count < 8 { return .unknown }
            
            let bytes = data.prefix(16) // 더 많은 바이트 확인
            
            // 이미지 포맷 확인 (ImageCacheManager와 동일)
            // JPEG: FF D8 FF
            if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
                return .jpeg
            }
            
            // PNG: 89 50 4E 47 0D 0A 1A 0A
            if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
                return .png
            }
            
            // GIF: "GIF87a" 또는 "GIF89a"
            let gifHeader87a = Data([0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) // "GIF87a"
            let gifHeader89a = Data([0x47, 0x49, 0x46, 0x38, 0x39, 0x61]) // "GIF89a"
            if bytes.prefix(6) == gifHeader87a || bytes.prefix(6) == gifHeader89a {
                return .gif
            }
            
            // WebP: "RIFF" + 4바이트 + "WEBP"
            if bytes.prefix(4) == Data([0x52, 0x49, 0x46, 0x46]) && // "RIFF"
               data.count >= 12 && data[8...11] == Data([0x57, 0x45, 0x42, 0x50]) { // "WEBP"
                return .webp
            }
            
            // 동영상 포맷 확인 (추가)
            // MP4: "ftyp" (File Type Box at offset 4)
            if data.count >= 12 {
                let ftypRange = 4..<8
                if data[ftypRange] == Data([0x66, 0x74, 0x79, 0x70]) { // "ftyp"
                    return .mp4
                }
            }
            
            // MOV/QuickTime: "moov", "mdat", "free" atom
            let movAtoms = ["moov", "mdat", "free"]
            for i in 0..<min(data.count - 4, 64) { // 처음 64바이트에서 검색
                let atomData = data[i..<(i+4)]
                if let atomString = String(data: atomData, encoding: .ascii),
                   movAtoms.contains(atomString) {
                    return .mov
                }
            }
            
            // AVI: "RIFF" + 4바이트 + "AVI "
            if bytes.prefix(4) == Data([0x52, 0x49, 0x46, 0x46]) && // "RIFF"
               data.count >= 12 && data[8..<12] == Data([0x41, 0x56, 0x49, 0x20]) { // "AVI "
                return .avi
            }
            
            // MKV: EBML 헤더 (1A 45 DF A3)
            if bytes.prefix(4) == Data([0x1A, 0x45, 0xDF, 0xA3]) {
                return .mkv
            }
            
            // WMV: ASF 헤더 (30 26 B2 75)
            if bytes.prefix(4) == Data([0x30, 0x26, 0xB2, 0x75]) {
                return .wmv
            }
            
            // PDF: "%PDF-"
            if bytes.prefix(5) == Data([0x25, 0x50, 0x44, 0x46, 0x2D]) {
                return .pdf
            }
            
            return .unknown
        }
        
        // URL 확장자 기반 포맷 감지 (캐시 히트 시 사용)
        static func detectFromURL(_ url: String) -> DetectedMediaFormat {
            let lowercased = url.lowercased()
            
            // 동영상 확장자 확인
            if lowercased.hasSuffix(".mp4") { return .mp4 }
            if lowercased.hasSuffix(".mov") { return .mov }
            if lowercased.hasSuffix(".avi") { return .avi }
            if lowercased.hasSuffix(".mkv") { return .mkv }
            if lowercased.hasSuffix(".wmv") { return .wmv }
            
            // 이미지 확장자 확인
            if lowercased.hasSuffix(".jpg") || lowercased.hasSuffix(".jpeg") { return .jpeg }
            if lowercased.hasSuffix(".png") { return .png }
            if lowercased.hasSuffix(".gif") { return .gif }
            if lowercased.hasSuffix(".webp") { return .webp }
            
            // PDF 확장자 확인
            if lowercased.hasSuffix(".pdf") { return .pdf }
            
            return .unknown
        }
    }
}

// MARK: - Unified Media Cache Protocol
protocol UnifiedMediaCacheProtocol {
    func getCachedImage(for url: String, size: CGSize, isFullSize: Bool) -> UIImage?
    func loadImage(from url: String, size: CGSize, isFullSize: Bool) async -> UnifiedMediaCacheManager.ImageLoadResult?
    func clearAllCaches()
    func handleMemoryWarning()
}

// MARK: - Unified Media Cache Manager
final class UnifiedMediaCacheManager: ObservableObject, UnifiedMediaCacheProtocol {
    
    static let shared = UnifiedMediaCacheManager()
    
    private let imageCacheManager = ImageCacheManager.shared
    private let videoThumbnailCache = ServerVideoThumbnailCache.shared
    
    // 통계 추적
    private var imageHitCount = 0
    private var videoHitCount = 0
    private var totalRequestCount = 0
    
    private init() {
        setupNotificationObservers()
        print("🎯 [UnifiedMediaCache] 통합 미디어 캐시 매니저 초기화 완료")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface
    
    /// 캐시된 이미지 즉시 반환 (동기) - 통합 캐시 확인
    func getCachedImage(for url: String, size: CGSize, isFullSize: Bool = false) -> UIImage? {
        totalRequestCount += 1
        
        // 1단계: 이미지 캐시 확인
        if let cachedImage = getCachedImageFromImageCache(url: url, size: size, isFullSize: isFullSize) {
            imageHitCount += 1
            logCacheHit("이미지", url: url)
            return cachedImage
        }
        
        // 2단계: 동영상 썸네일 캐시 확인
        if let thumbnailData = getCachedVideoThumbnail(url: url, size: size) {
            videoHitCount += 1
            logCacheHit("동영상 썸네일", url: url)
            return UIImage(data: thumbnailData)
        }
        
        return nil
    }
    
    /// 비동기 이미지 로드 (네트워크 포함) - 서버 파일 시그니처 기반 라우팅
    func loadImage(from url: String, size: CGSize, isFullSize: Bool = false) async -> ImageLoadResult? {
        // 1. 먼저 메모리 캐시 확인
        if let cachedImage = getCachedImage(for: url, size: size, isFullSize: isFullSize) {
            // 캐시 히트된 경우 URL 기반으로 원본 파일 타입 판단
            let isAnimated = isAnimatedImage(cachedImage)
            let detectedFormat = DetectedMediaFormat.detectFromURL(url)

            print("⚡ [UnifiedMediaCache] 메모리 캐시 히트 - URL 기반 포맷: \(detectedFormat) (원본: \(url))")

            return ImageLoadResult(
                image: cachedImage,
                originalData: Data(),
                detectedFormat: detectedFormat,
                isAnimatedGIF: isAnimated
            )
        }

        // 2. 디스크 캐시 확인
        if let diskImage = await loadImageFromDiskCache(url: url, size: size, isFullSize: isFullSize) {
            let isAnimated = isAnimatedImage(diskImage)
            let detectedFormat = DetectedMediaFormat.detectFromURL(url)

            print("💾 [UnifiedMediaCache] 디스크 캐시 히트 - URL 기반 포맷: \(detectedFormat) (원본: \(url))")

            return ImageLoadResult(
                image: diskImage,
                originalData: Data(),
                detectedFormat: detectedFormat,
                isAnimatedGIF: isAnimated
            )
        }

        print("🔄 [UnifiedMediaCache] 캐시 미스 - 서버에서 파일 데이터 다운로드 및 타입 판별: \(url)")

        // 3. 서버에서 파일 다운로드
        guard let data = await downloadFileFromServer(url: url) else {
            return nil
        }

        // 4. 파일 시그니처로 타입 판별 (한 번만)
        let detectedFormat = DetectedMediaFormat.detect(from: data)
        print("🔍 [UnifiedMediaCache] 감지된 포맷: \(detectedFormat)")

        // 5. 각 전용 매니저에 데이터와 함께 위임 (다시 다운로드하지 않음)
        if detectedFormat.isVideo {
            print("🎬 [UnifiedMediaCache] 동영상 포맷 감지 - ServerVideoThumbnailCache에 위임")
            return await processVideoFileWithData(data: data, url: url, size: size)
        } else {
            print("📸 [UnifiedMediaCache] 이미지 포맷 감지 - ImageCacheManager에 위임")
            return await imageCacheManager.processImageFromData(
                data: data,
                url: url,
                size: size,
                isFullSize: isFullSize,
                detectedFormat: detectedFormat
            )
        }
    }
    
    // MARK: - 서버 다운로드 (중앙화)
    private func downloadFileFromServer(url: String) async -> Data? {
        let fullURL = APIURL.PICKUP + "/v1\(url)"
        guard let serverURL = URL(string: fullURL) else {
            print("❌ [UnifiedMediaCache] 잘못된 URL: \(fullURL)")
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            API.session.request(serverURL, method: .get)
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        print("✅ [UnifiedMediaCache] 파일 다운로드 성공: \(data.count / 1024)KB")
                        continuation.resume(returning: data)
                    case .failure(let error):
                        print("❌ [UnifiedMediaCache] 파일 다운로드 실패: \(error)")
                        continuation.resume(returning: nil)
                    }
                }
        }
    }
    
    // MARK: - 동영상 처리 (캐시 우선)
    private func processVideoFileWithData(data: Data, url: String, size: CGSize) async -> ImageLoadResult? {
        print("🎬 [UnifiedMediaCache] ServerVideoThumbnailCache 캐시 확인 및 처리 위임")
        
        // ServerVideoThumbnailCache의 정상적인 캐시 플로우를 사용
        // (메모리 캐시 → 디스크 캐시 → 생성)
        let thumbnailData = await videoThumbnailCache.loadThumbnail(
            from: url,
            size: size
        ) { [weak self] in
            // 캐시 미스 시에만 실제 생성 (데이터를 활용)
            return await self?.videoThumbnailCache.generateThumbnailFromData(
                data: data,
                url: url,
                size: size
            )
        }
        
        guard let thumbnailData = thumbnailData else {
            print("❌ [UnifiedMediaCache] 동영상 썸네일 처리 실패: \(url)")
            return nil
        }
        
        guard let thumbnailImage = UIImage(data: thumbnailData) else {
            print("❌ [UnifiedMediaCache] 썸네일 데이터 → UIImage 변환 실패")
            return nil
        }
        
        print("✅ [UnifiedMediaCache] 동영상 썸네일 처리 완료 (캐시 플로우 활용)")
        
        return ImageLoadResult(
            image: thumbnailImage,
            originalData: thumbnailData,
            detectedFormat: .unknown,
            isAnimatedGIF: false
        )
    }
    
    // MARK: - 디스크 캐시 조회 메서드

    private func loadImageFromDiskCache(url: String, size: CGSize, isFullSize: Bool) async -> UIImage? {
        let cacheKey = imageCacheManager.generateCacheKey(from: url, isFullSize: isFullSize)
        let targetCache = isFullSize ? imageCacheManager.fullSizeCache : imageCacheManager.thumbnailCache

        // 일반 이미지 디스크 캐시 확인
        if let diskImage = await imageCacheManager.loadImageFromDisk(key: cacheKey) {
            // 디스크 캐시 히트 시 메모리 캐시에 재저장 (성능 최적화)
            let imageCost = estimateImageCost(diskImage)
            targetCache.setObject(diskImage, forKey: cacheKey as NSString, cost: imageCost)

            print("💾➡️⚡ [UnifiedMediaCache] 디스크 캐시 히트 → 메모리 캐시 재저장: \(url)")
            return diskImage
        }

        // GIF 데이터 디스크 캐시 확인
        let gifCacheKey = imageCacheManager.generateGIFDataCacheKey(from: url)
        if let gifData = await imageCacheManager.loadGIFDataFromDisk(key: gifCacheKey) {
            // GIF 데이터를 메모리 캐시에 재저장
            imageCacheManager.gifDataCache.setObject(gifData as NSData, forKey: gifCacheKey as NSString, cost: gifData.count)

            print("💾➡️⚡ [UnifiedMediaCache] GIF 디스크 캐시 히트 → 메모리 캐시 재저장: \(url)")
            return imageCacheManager.createAnimatedImageFromData(gifData)
        }

        return nil
    }

    // MARK: - Helper Methods

    private func isAnimatedImage(_ image: UIImage) -> Bool {
        // UIImage의 images 프로퍼티가 있으면 애니메이션 이미지
        return image.images != nil && (image.images?.count ?? 0) > 1
    }

    private func estimateImageCost(_ image: UIImage) -> Int {
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        let bytesPerPixel = 4 // RGBA
        return width * height * bytesPerPixel
    }
    
    // MARK: - Private Cache Access Methods
    
    private func getCachedImageFromImageCache(url: String, size: CGSize, isFullSize: Bool) -> UIImage? {
        let cacheKey = imageCacheManager.generateCacheKey(from: url, isFullSize: isFullSize)
        let targetCache = isFullSize ? imageCacheManager.fullSizeCache : imageCacheManager.thumbnailCache

        // 메모리 캐시 확인 (일반 이미지)
        if let cachedImage = targetCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }

        // 메모리 캐시 확인 (GIF 데이터)
        let gifCacheKey = imageCacheManager.generateGIFDataCacheKey(from: url)
        if let gifData = imageCacheManager.gifDataCache.object(forKey: gifCacheKey as NSString) as Data? {
            return imageCacheManager.createAnimatedImageFromData(gifData)
        }

        return nil
    }
    
    private func getCachedVideoThumbnail(url: String, size: CGSize) -> Data? {
        let cacheKey = generateVideoCacheKey(path: url, size: size)
        return videoThumbnailCache.memoryCache.object(forKey: cacheKey as NSString) as Data?
    }
    
    // MARK: - Async Load Methods
    
    
    
    // MARK: - Cache Management
    
    func clearAllCaches() {
        imageCacheManager.clearAllCache()
        videoThumbnailCache.clearAllCache()
        
        // 통계 리셋
        imageHitCount = 0
        videoHitCount = 0
        totalRequestCount = 0
        
        print("🧹 [UnifiedMediaCache] 모든 캐시 정리 완료")
    }
    
    func handleMemoryWarning() {
        imageCacheManager.handleMemoryWarning()
        videoThumbnailCache.handleMemoryWarning()
        print("⚠️ [UnifiedMediaCache] 메모리 경고 - 모든 캐시 정리")
    }
    
    // MARK: - Statistics & Monitoring
    
    func getCacheStatistics() -> CacheStatistics {
        let imageHitRate = totalRequestCount > 0 ? Double(imageHitCount) / Double(totalRequestCount) : 0.0
        let videoHitRate = totalRequestCount > 0 ? Double(videoHitCount) / Double(totalRequestCount) : 0.0
        
        return CacheStatistics(
            totalRequests: totalRequestCount,
            imageHits: imageHitCount,
            videoHits: videoHitCount,
            imageHitRate: imageHitRate,
            videoHitRate: videoHitRate
        )
    }
    
    struct CacheStatistics {
        let totalRequests: Int
        let imageHits: Int
        let videoHits: Int
        let imageHitRate: Double
        let videoHitRate: Double
        
        var description: String {
            return """
            📊 [UnifiedMediaCache] 통계:
            - 총 요청: \(totalRequests)
            - 이미지 캐시 히트: \(imageHits) (\(String(format: "%.1f", imageHitRate * 100))%)
            - 동영상 캐시 히트: \(videoHits) (\(String(format: "%.1f", videoHitRate * 100))%)
            - 전체 히트율: \(String(format: "%.1f", (Double(imageHits + videoHits) / Double(max(1, totalRequests))) * 100))%
            """
        }
    }
    
    // MARK: - Cache Management Methods
    
    /// 특정 파일들의 캐시를 삭제 (게시물 삭제 시 사용)
    func clearCacheForFiles(_ filePaths: [String]) {
        print("🗑️ [UnifiedMediaCache] 파일 캐시 삭제 시작: \(filePaths.count)개")
        
        for filePath in filePaths {
            // 1. 이미지 캐시 삭제 (썸네일 + 풀사이즈)
            imageCacheManager.clearSpecificCache(for: filePath)
            
            // 2. 동영상 썸네일 캐시 삭제
            videoThumbnailCache.clearSpecificCache(for: filePath)
            
            print("🗑️ [UnifiedMediaCache] 파일 캐시 삭제 완료: \(filePath)")
        }
        
        print("✅ [UnifiedMediaCache] 전체 파일 캐시 삭제 완료")
    }
    
    // MARK: - Helper Methods
    
    private func generateVideoCacheKey(path: String, size: CGSize) -> String {
        // ServerVideoThumbnailCache와 동일한 파일명만 기반 캐시키 생성
        // 동영상 썸네일은 크기에 관계없이 하나의 캐시키 사용
        let fileName = extractFileName(from: path)
        return "vid_\(fileName)"
    }
    
    // URL에서 파일명만 추출
    private func extractFileName(from path: String) -> String {
        guard let url = URL(string: path) else { return path }
        return url.lastPathComponent
    }
    
    private func logCacheHit(_ type: String, url: String) {
        print("⚡ [UnifiedMediaCache] \(type) 캐시 히트: \(url)")
        
        // 일정 간격으로 통계 출력
        if totalRequestCount % 50 == 0 {
            print(getCacheStatistics().description)
        }
    }
    
    // MARK: - Lifecycle Management
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleBackgroundTransition()
        }
    }
    
    private func handleBackgroundTransition() {
        // 백그라운드 전환 시 각 캐시 매니저의 백그라운드 처리 위임
        // ImageCacheManager와 ServerVideoThumbnailCache 각각의 백그라운드 로직 실행
        print("🌙 [UnifiedMediaCache] 백그라운드 전환 - 캐시 최적화")
    }
}

