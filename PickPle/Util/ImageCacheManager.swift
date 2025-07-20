//
//  ImageCacheManager.swift
//  PickPle
//
//  Created by 정인선 on 6/2/25.
//

import SwiftUI
import Alamofire
import UniformTypeIdentifiers

// MARK: - 공통 캐시 인프라 (VideoProcessingManager에서 공유)
protocol CacheManagerProtocol: AnyObject {
    associatedtype CacheKey: AnyObject
    associatedtype CacheValue: AnyObject
    
    var memoryCache: NSCache<CacheKey, CacheValue> { get }
    
    func setupMemoryCache()
    func handleMemoryWarning()
    func clearAllCache()
    func logCaching(_ message: String)
}

extension CacheManagerProtocol {
    func setupMemoryWarning() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    func handleMemoryWarning() {
        memoryCache.removeAllObjects()
        logCaching("메모리 부족 - 캐시 정리")
    }
    
    func clearAllCache() {
        memoryCache.removeAllObjects()
        logCaching("모든 캐시 삭제")
    }
    
    func logCaching(_ message: String) {
        print("📸 \(message)")
    }
}

// MARK: - ImageLoader
//@MainActor
//final class ImageLoader: ObservableObject {
//    @Published var image: UIImage?
//    @Published var isLoading = false
//    
//    private var currentTask: Task<Void, Never>?
//    
//    deinit {
//        print("ImageLoader Deinit")
//    }
//    
//    func loadImage(from path: String, size: CGSize) async {
//        currentTask?.cancel()
//        
//        isLoading = true
//        
//        currentTask = Task {
//            let loadedImage = await ImageCacheManager.shared.loadImage(from: path, size: size)
//            
//            if !Task.isCancelled {
//                self.image = loadedImage
//                self.isLoading = false
//            }
//        }
//        
//        await currentTask?.value
//    }
//}

//@MainActor
//final class SimpleImageLoader: ObservableObject {
//    @Published var image: UIImage?
//    @Published var isLoading = false
//    
//    private var loadTask: Task<Void, Never>?
//    
//    deinit {
//        loadTask?.cancel()
//    }
//    
//    func loadImage(from path: String, size: CGSize) {
//        // 이미 같은 이미지를 로딩 중이라면 중복 방지
//        guard !isLoading else { return }
//        
//        loadTask?.cancel()
//        isLoading = true
//        
//        loadTask = Task {
//            let loadedImage = await ImageCacheManager.shared.loadImage(from: path, size: size)
//            
//            if !Task.isCancelled {
//                self.image = loadedImage
//                self.isLoading = false
//            }
//        }
//    }
//}


// MARK: - ImageCacheManager
final class ImageCacheManager: ObservableObject, CacheManagerProtocol {
    typealias CacheKey = NSString
    typealias CacheValue = UIImage
    
    static let shared = ImageCacheManager()
    
    private let fileManager = FileManager.default
    
    let thumbnailCache = NSCache<NSString, UIImage>()  // 썸네일용 (300x300) - UnifiedMediaCacheManager 접근용 public
    let fullSizeCache = NSCache<NSString, UIImage>()   // 풀사이즈용 (1080x1080) - UnifiedMediaCacheManager 접근용 public
    // GIF 원본 데이터 캐시 (메모리 사용량 고려하여 제한적으로) - UnifiedMediaCacheManager 접근용 public
    let gifDataCache = NSCache<NSString, NSData>()
    
    // CacheManagerProtocol 준수를 위한 메인 캐시 (썸네일 캐시를 대표로 사용)
    var memoryCache: NSCache<NSString, UIImage> {
        return thumbnailCache
    }
    
    private var diskCacheURL: URL?
    private let maxDiskCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let queue = DispatchQueue(label: "ImageCacheQueue", qos: .utility)
    
    // 네트워크 최적화: 동시 다운로드 제한
    private let downloadSemaphore = DispatchSemaphore(value: 3) // 최대 3개 동시 다운로드
    private let downloadQueue = DispatchQueue(label: "ImageDownloadQueue", qos: .utility, attributes: .concurrent)
    
    // 동적 캐시 크기 관리
    private var dynamicThumbnailCacheLimit: Int {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let availableMemory = totalMemory / 8 // 총 메모리의 12.5%를 썸네일용으로
        
        switch availableMemory {
        case ..<50_000_000: return 15 * 1024 * 1024   // 15MB
        case ..<200_000_000: return 30 * 1024 * 1024  // 30MB
        case ..<500_000_000: return 50 * 1024 * 1024  // 50MB
        default: return 80 * 1024 * 1024              // 80MB
        }
    }
    
    private var dynamicFullSizeCacheLimit: Int {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let availableMemory = totalMemory / 8 // 총 메모리의 12.5%를 풀사이즈용으로
        
        switch availableMemory {
        case ..<50_000_000: return 30 * 1024 * 1024   // 30MB
        case ..<200_000_000: return 60 * 1024 * 1024  // 60MB
        case ..<500_000_000: return 100 * 1024 * 1024 // 100MB
        default: return 150 * 1024 * 1024             // 150MB
        }
    }
    
    private init() {
        setupDiskCache()
        setupMemoryCache()
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - CacheManagerProtocol 구현
    func handleMemoryWarning() {
        // 기존의 점진적 정리 로직 활용 (ImageCacheManager 특화)
        performGradualMemoryCleanup()
        logCaching("메모리 부족 - 이미지 캐시 정리")
    }
    
    func clearAllCache() {
        // 모든 메모리 캐시 정리
        thumbnailCache.removeAllObjects()
        fullSizeCache.removeAllObjects()
        gifDataCache.removeAllObjects()
        logCaching("모든 이미지 캐시 삭제")
    }
    
    private func setupDiskCache() {
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("ImageCacheManager: Failed to get cache directory")
            return
        }
        
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache")
        guard let diskURL = diskCacheURL else { return }
        
        do {
            try fileManager.createDirectory(at: diskURL, withIntermediateDirectories: true)
        } catch {
            print("ImageCacheManager: Failed to create disk cache directory - \(error)")
            diskCacheURL = nil
        }
    }
    
    func setupMemoryCache() {
        updateMemoryCacheLimit()
        setupGIFDataCache()
    }
    
    private func setupGIFDataCache() {
        // GIF 데이터 캐시는 제한적으로 설정 (메모리 사용량 고려)
        gifDataCache.countLimit = 5  // 최대 5개 GIF
        gifDataCache.totalCostLimit = 25 * 1024 * 1024  // 25MB
    }
    
    private func updateMemoryCacheLimit() {
        // 썸네일 캐시 설정
        let thumbnailLimit = dynamicThumbnailCacheLimit
        thumbnailCache.countLimit = max(100, thumbnailLimit / (300 * 1024)) // 평균 300KB per thumbnail
        thumbnailCache.totalCostLimit = thumbnailLimit
        
        // 풀사이즈 캐시 설정
        let fullSizeLimit = dynamicFullSizeCacheLimit
        fullSizeCache.countLimit = max(20, fullSizeLimit / (5 * 1024 * 1024)) // 평균 5MB per full image
        fullSizeCache.totalCostLimit = fullSizeLimit
        
        print("📊 썸네일 캐시 크기: \(thumbnailLimit / 1024 / 1024)MB, 풀사이즈 캐시 크기: \(fullSizeLimit / 1024 / 1024)MB")
    }
    
    private func setupNotificationObservers() {
        // 메모리 경고 시 점진적 캐시 정리
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.performGradualMemoryCleanup()
        }
        
        // 백그라운드 진입 시 캐시 크기 조정
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.reduceMemoryCacheForBackground()
        }
        
        // 포그라운드 복귀 시 캐시 크기 복원
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.updateMemoryCacheLimit()
        }
    }
    
    private func performGradualMemoryCleanup() {
        // 풀사이즈 캐시 전체 삭제 (메모리 많이 차지)
        fullSizeCache.removeAllObjects()
        
        // GIF 데이터 캐시 전체 삭제 (메모리 많이 차지)
        gifDataCache.removeAllObjects()
        
        // 썸네일 캐시는 50% 축소
        let currentThumbnailCount = thumbnailCache.countLimit
        let targetThumbnailReduction = thumbnailCache.totalCostLimit / 2
        
        thumbnailCache.countLimit = currentThumbnailCount / 2
        
        // 0.5초 후 썸네일 제한 복원하되 메모리 제한은 줄임
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.thumbnailCache.countLimit = currentThumbnailCount
            self.thumbnailCache.totalCostLimit = targetThumbnailReduction
        }
        
        print("🧹 메모리 경고: 풀사이즈 캐시, GIF 데이터 캐시 전체 삭제, 썸네일 캐시 50% 축소")
    }
    
    private func reduceMemoryCacheForBackground() {
        // 풀사이즈 캐시 전체 삭제 (백그라운드에서는 뷰어 사용 안함)
        fullSizeCache.removeAllObjects()
        
        // GIF 데이터 캐시 전체 삭제 (백그라운드에서는 애니메이션 불필요)
        gifDataCache.removeAllObjects()
        
        // 썸네일 캐시는 25%로 축소
        let backgroundThumbnailLimit = dynamicThumbnailCacheLimit / 4
        thumbnailCache.totalCostLimit = backgroundThumbnailLimit
        
        print("🌙 백그라운드 모드: 풀사이즈, GIF 데이터 캐시 삭제, 썸네일 캐시 축소 - \(backgroundThumbnailLimit / 1024 / 1024)MB")
    }
}

extension ImageCacheManager {
    
    private class ImageMetadata: NSObject {
        let detectedFormat: UnifiedMediaCacheManager.DetectedMediaFormat
        let isAnimatedGIF: Bool
        
        init(detectedFormat: UnifiedMediaCacheManager.DetectedMediaFormat, isAnimatedGIF: Bool) {
            self.detectedFormat = detectedFormat
            self.isAnimatedGIF = isAnimatedGIF
        }
    }
    
    // 2단계 캐싱 시스템 - 새로운 메인 로드 메서드 (Data + 포맷 정보 반환) - 사용되지 않음
    func loadImageWithData(from path: String, size: CGSize, isFullSize: Bool = false) async -> UnifiedMediaCacheManager.ImageLoadResult? {
        let cacheKey = generateCacheKey(from: path, isFullSize: isFullSize)
        let targetCache = isFullSize ? fullSizeCache : thumbnailCache
        let targetSize = isFullSize ? CGSize(width: 1080, height: 1080) : CGSize(width: 300, height: 300)
        let cacheType = isFullSize ? "풀사이즈" : "썸네일"
        
        // ✅ 1단계: GIF 캐시 확인 먼저 - 캐시 위치 자체가 GIF 타입을 의미
        let gifCacheKey = generateGIFDataCacheKey(from: path)
        if let cachedGIFData = gifDataCache.object(forKey: gifCacheKey as NSString) as Data? {
            print("⚡ [ImageCache] GIF 데이터 캐시 히트 → 확실한 애니메이션 GIF: \(path)")
            
            // GIF 캐시에 있다면 확실히 애니메이션 GIF (캐시 위치가 타입을 보장)
            let animatedImage = createAnimatedImageFromData(cachedGIFData) ?? UIImage(data: cachedGIFData) ?? UIImage()
            
            return UnifiedMediaCacheManager.ImageLoadResult(
                image: animatedImage,
                originalData: cachedGIFData,
                detectedFormat: .gif,
                isAnimatedGIF: true
            )
        }
        
        // ✅ 2단계: 일반 이미지 캐시 확인 - 캐시 위치 자체가 정적 이미지임을 의미
        if let cachedImage = targetCache.object(forKey: cacheKey as NSString) {
            print("⚡ [ImageCache] \(cacheType) 일반 이미지 캐시 히트 → 확실한 정적 이미지: \(path)")
            
            return UnifiedMediaCacheManager.ImageLoadResult(
                image: cachedImage,
                originalData: Data(), // 일반 이미지 캐시에서는 원본 데이터 불필요
                detectedFormat: .unknown, // 정적 이미지이므로 정확한 포맷은 중요하지 않음
                isAnimatedGIF: false // 일반 이미지 캐시에 있으므로 확실히 애니메이션 아님
            )
        }
        
        // ✅ 3단계: 디스크 캐시 확인 - GIF 디스크 캐시 먼저 확인
        let gifDiskKey = generateGIFDataCacheKey(from: path)
        if let gifDiskData = await loadDataFromDisk(key: gifDiskKey) {
            print("💿 [ImageCache] GIF 디스크 캐시 히트 → 확실한 애니메이션 GIF: \(path)")
            
            let animatedImage = createAnimatedImageFromData(gifDiskData) ?? UIImage(data: gifDiskData) ?? UIImage()
            
            // GIF 메모리 캐시에도 저장
            if gifDiskData.count <= 10 * 1024 * 1024 { // 10MB 이하만 메모리 캐시
                gifDataCache.setObject(gifDiskData as NSData, forKey: gifDiskKey as NSString, cost: gifDiskData.count)
            }
            
            return UnifiedMediaCacheManager.ImageLoadResult(
                image: animatedImage,
                originalData: gifDiskData,
                detectedFormat: .gif,
                isAnimatedGIF: true
            )
        }
        
        // ✅ 4단계: 일반 이미지 디스크 캐시 확인
        if let diskData = await loadDataFromDisk(key: cacheKey) {
            print("💿 [ImageCache] \(cacheType) 일반 이미지 디스크 캐시 히트: \(path)")
            
            // 일반 이미지 다운샘플링
            let finalImage = ImageProcessingManager.shared.downsampleForDisplay(
                data: diskData,
                pointSize: targetSize,
                scale: UIScreen.main.scale
            ) ?? UIImage()
            
            // 일반 이미지 메모리 캐시에 저장
            targetCache.setObject(finalImage, forKey: cacheKey as NSString, cost: estimateImageCost(finalImage))
            
            return UnifiedMediaCacheManager.ImageLoadResult(
                image: finalImage,
                originalData: diskData,
                detectedFormat: UnifiedMediaCacheManager.DetectedMediaFormat.detect(from: diskData),
                isAnimatedGIF: false // 일반 이미지 디스크 캐시에 있으므로 확실히 애니메이션 아님
            )
        }
        
        // ✅ 5단계: 네트워크 다운로드 (모든 캐시 미스)
        print("📸 [ImageCache] \(cacheType) 이미지 다운로드 시작 (메모리/디스크 캐시 미스): \(path)")
        
        return await withCheckedContinuation { continuation in
            let fullURL = APIURL.PICKUP + "/v1\(path)"
            guard let url = URL(string: fullURL) else { 
                print("❌ [ImageCache] 잘못된 URL: \(fullURL)")
                continuation.resume(returning: nil)
                return
            }
            
            print("📸 [ImageCache] API.session으로 \(cacheType) 이미지 요청: \(fullURL)")
            API.session.request(url, method: .get)
                .responseData { [weak self] response in
                    guard let self else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    switch response.result {
                    case .success(let data):
                        print("✅ [ImageCache] \(cacheType) 이미지 다운로드 성공: \(data.count / 1024)KB")
                        
                        // 🔍 실제 파일 포맷 감지
                        let detectedFormat = UnifiedMediaCacheManager.DetectedMediaFormat.detect(from: data)
                        let isAnimated = detectedFormat == .gif && self.checkIfAnimatedGIF(data: data)
                        
                        print("🔍 [ImageCache] 감지된 실제 포맷: \(detectedFormat) (경로: \(path))")
                        print("🎬 [ImageCache] 애니메이션 GIF 여부: \(isAnimated)")
                        
                        let finalImage: UIImage
                        if isAnimated {
                            // 🎬 GIF 애니메이션 이미지 생성
                            finalImage = self.createAnimatedImageFromData(data) ?? UIImage(data: data) ?? UIImage()
                            print("🎬 [ImageCache] GIF 애니메이션 이미지 생성 완료")
                            
                            // ✅ GIF는 gifDataCache에만 원본 데이터 저장 (캐시 분리로 타입 구분)
                            let gifCacheKey = self.generateGIFDataCacheKey(from: path)
                            if data.count <= 10 * 1024 * 1024 { // 10MB 이하만 메모리 캐시
                                self.gifDataCache.setObject(data as NSData, forKey: gifCacheKey as NSString, cost: data.count)
                                print("💾 [ImageCache] GIF 데이터를 gifDataCache에 저장 → \(gifCacheKey)")
                            }
                            // ✅ GIF는 일반 이미지 캐시에는 저장하지 않음 (캐시 위치로 타입 구분)
                        } else {
                            // 📏 일반 이미지 다운샘플링
                            finalImage = ImageProcessingManager.shared.downsampleForDisplay(
                                data: data,
                                pointSize: targetSize,
                                scale: UIScreen.main.scale
                            ) ?? UIImage()
                            print("📏 [ImageCache] \(cacheType) 다운샘플링 완료: \(finalImage.size)")
                            
                            // ✅ 일반 이미지는 이미지 캐시에만 저장 (캐시 분리로 타입 구분)
                            targetCache.setObject(finalImage, forKey: cacheKey as NSString, cost: self.estimateImageCost(finalImage))
                            print("💾 [ImageCache] 일반 이미지를 \(cacheType) 캐시에 저장 → \(cacheKey)")
                        }
                        
                        // ✅ 디스크 캐시에도 타입별로 분리 저장
                        Task {
                            if isAnimated {
                                // GIF는 GIF 디스크 키로 저장
                                let gifCacheKey = self.generateGIFDataCacheKey(from: path)
                                await self.saveImageToDisk(data: data, key: gifCacheKey)
                                print("💿 [ImageCache] GIF 데이터를 디스크에 저장 → \(gifCacheKey)")
                            } else {
                                // 일반 이미지는 일반 디스크 키로 저장
                                await self.saveImageToDisk(data: data, key: cacheKey)
                                print("💿 [ImageCache] 일반 이미지를 디스크에 저장 → \(cacheKey)")
                            }
                        }
                        
                        let result = UnifiedMediaCacheManager.ImageLoadResult(
                            image: finalImage,
                            originalData: data,
                            detectedFormat: detectedFormat,
                            isAnimatedGIF: isAnimated
                        )
                        
                        continuation.resume(returning: result)
                        
                    case .failure(let error):
                        print("❌ [ImageCache] \(cacheType) 이미지 다운로드 실패: \(error)")
                        continuation.resume(returning: nil)
                    }
                }
        }
    }
    
    // MARK: - 데이터 기반 이미지 처리 (UnifiedMediaCacheManager 전용)
    func processImageFromData(data: Data, url: String, size: CGSize, isFullSize: Bool, detectedFormat: UnifiedMediaCacheManager.DetectedMediaFormat) async -> UnifiedMediaCacheManager.ImageLoadResult? {
        let targetSize = isFullSize ? CGSize(width: 1080, height: 1080) : CGSize(width: 300, height: 300)
        let cacheType = isFullSize ? "풀사이즈" : "썸네일"
        
        print("📸 [ImageCache] 데이터 기반 이미지 처리 시작: \(cacheType) (\(data.count / 1024)KB)")
        
        // GIF 애니메이션 확인
        let isAnimatedGIF = detectedFormat == .gif && checkIfAnimatedGIF(data: data)
        
        let finalImage: UIImage
        if isAnimatedGIF {
            // GIF 애니메이션 처리
            finalImage = createAnimatedImageFromData(data) ?? UIImage(data: data) ?? UIImage()
            
            // GIF 데이터 캐시에 저장
            let gifCacheKey = generateGIFDataCacheKey(from: url)
            gifDataCache.setObject(data as NSData, forKey: gifCacheKey as NSString, cost: data.count)
            
            // 디스크에도 저장 (백그라운드)
            Task.detached(priority: .utility) { [weak self] in
                await self?.saveImageToDisk(data: data, key: gifCacheKey)
            }
            
            print("🎬 [ImageCache] GIF 애니메이션 처리 및 캐시 저장 완료")
        } else {
            // 일반 이미지 다운샘플링
            finalImage = ImageProcessingManager.shared.downsampleForDisplay(
                data: data,
                pointSize: targetSize,
                scale: UIScreen.main.scale
            ) ?? UIImage(data: data) ?? UIImage()
            
            // 이미지 캐시에 저장
            let cacheKey = generateCacheKey(from: url, isFullSize: isFullSize)
            let targetCache = isFullSize ? fullSizeCache : thumbnailCache
            let imageCost = estimateImageCost(finalImage)
            
            targetCache.setObject(finalImage, forKey: cacheKey as NSString, cost: imageCost)
            
            // 디스크에도 저장 (백그라운드)
            if let imageData = finalImage.jpegData(compressionQuality: 0.8) {
                Task.detached(priority: .utility) { [weak self] in
                    await self?.saveImageToDisk(data: imageData, key: cacheKey)
                }
            }
            
            print("📸 [ImageCache] \(cacheType) 이미지 다운샘플링 및 캐시 저장 완료")
        }
        
        return UnifiedMediaCacheManager.ImageLoadResult(
            image: finalImage,
            originalData: data,
            detectedFormat: detectedFormat,
            isAnimatedGIF: isAnimatedGIF
        )
    }

    // 기존 호환성을 위한 메서드 (새로운 메서드로 위임)
    func loadImage(from path: String, size: CGSize, isFullSize: Bool = false) async -> UIImage? {
        let result = await loadImageWithData(from: path, size: size, isFullSize: isFullSize)
        return result?.image
    }
    
    // GIF 애니메이션 여부 확인
    private func checkIfAnimatedGIF(data: Data) -> Bool {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return false
        }
        let frameCount = CGImageSourceGetCount(imageSource)
        return frameCount > 1
    }
    
    // 데이터로부터 애니메이션 GIF 생성 (CachedImageView의 로직 재사용) - UnifiedMediaCacheManager 접근용 public
    func createAnimatedImageFromData(_ data: Data) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(imageSource)
        guard frameCount > 1 else {
            return UIImage(data: data)
        }
        
        var images: [UIImage] = []
        var totalDuration: Double = 0
        
        for i in 0..<frameCount {
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else {
                continue
            }
            
            let uiImage = UIImage(cgImage: cgImage)
            images.append(uiImage)
            
            let frameProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as? [String: Any]
            let gifProperties = frameProperties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
            let frameDuration = gifProperties?[kCGImagePropertyGIFDelayTime as String] as? Double ?? 0.1
            totalDuration += frameDuration
        }
        
        return UIImage.animatedImage(with: images, duration: totalDuration)
    }
    
    // 호환성을 위한 기존 메서드 (썸네일 기본값)
    func loadImage(from path: String, size: CGSize) async -> UIImage? {
        return await loadImage(from: path, size: size, isFullSize: false)
    }
    
    // MARK: - GIF 원본 데이터 로드 (애니메이션 지원)
    func loadGIFData(from path: String, maxSizeKB: Int = 5120) async -> Data? {
        let cacheKey = generateGIFDataCacheKey(from: path)
        
        // 1단계: 메모리 캐시 확인
        if let cachedData = gifDataCache.object(forKey: cacheKey as NSString) as Data? {
            print("⚡ [ImageCache] GIF 데이터 메모리 캐시 히트: \(path)")
            return cachedData
        }
        
        // 2단계: 디스크 캐시 확인
        if let diskData = await loadDataFromDisk(key: cacheKey) {
            print("💿 [ImageCache] GIF 데이터 디스크 캐시 히트: \(path)")
            // 디스크에서 로드한 데이터를 메모리 캐시에도 저장
            if diskData.count <= 10 * 1024 * 1024 { // 10MB 이하만 메모리 캐시
                gifDataCache.setObject(diskData as NSData, forKey: cacheKey as NSString, cost: diskData.count)
            }
            return diskData
        }
        
        print("🎬 [ImageCache] GIF 원본 데이터 다운로드 시작 (메모리/디스크 캐시 미스): \(path)")
        
        return await withCheckedContinuation { continuation in
            let fullURL = APIURL.PICKUP + "/v1\(path)"
            guard let url = URL(string: fullURL) else { 
                print("❌ [ImageCache] 잘못된 GIF URL: \(fullURL)")
                continuation.resume(returning: nil)
                return
            }
            
            print("🎬 [ImageCache] API.session으로 GIF 데이터 요청: \(fullURL)")
            API.session.request(url, method: .get)
                .responseData { [weak self] response in
                    guard let self else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    switch response.result {
                    case .success(let data):
                        print("✅ [ImageCache] GIF 데이터 다운로드 성공: \(data.count / 1024)KB")
                        
                        // 🔍 실제 파일 포맷 감지 및 로그
                        let detectedFormat = UnifiedMediaCacheManager.DetectedMediaFormat.detect(from: data)
                        print("🔍 [ImageCache] GIF 요청 시 감지된 실제 포맷: \(detectedFormat) (경로: \(path))")
                        
                        // HTTP 헤더 정보도 로그
                        if let httpResponse = response.response {
                            print("🌐 [ImageCache] GIF HTTP Content-Type: \(httpResponse.mimeType ?? "없음")")
                            print("🌐 [ImageCache] GIF HTTP Content-Length: \(httpResponse.expectedContentLength)")
                        }
                        
                        // 바이너리 시그니처 상세 로그
                        if data.count >= 8 {
                            let headerBytes = data.prefix(8).map { String(format: "%02X", $0) }.joined(separator: " ")
                            print("🔍 [ImageCache] 파일 헤더 바이트: \(headerBytes)")
                        }
                        
                        // 크기 제한 확인
                        let maxBytes = maxSizeKB * 1024
                        let finalData: Data
                        
                        if data.count > maxBytes {
                            print("⚠️ [ImageCache] GIF 크기 초과 (\(data.count / 1024)KB > \(maxSizeKB)KB), 프레임 감소 시도")
                            // GIF 프레임 감소로 용량 줄이기
                            if let compressedData = self.compressGIFByReducingFrames(data: data, targetSizeKB: maxSizeKB) {
                                finalData = compressedData
                                print("✅ [ImageCache] GIF 프레임 감소 완료: \(finalData.count / 1024)KB")
                            } else {
                                print("❌ [ImageCache] GIF 압축 실패, 원본 사용")
                                finalData = data
                            }
                        } else {
                            finalData = data
                        }
                        
                        // 메모리 캐시에 저장 (용량 체크)
                        if finalData.count <= 10 * 1024 * 1024 { // 10MB 이하만 메모리 캐시
                            self.gifDataCache.setObject(finalData as NSData, forKey: cacheKey as NSString, cost: finalData.count)
                            print("💾 [ImageCache] GIF 데이터 메모리 캐시에 저장: \(cacheKey)")
                        }
                        
                        // 디스크 캐시에도 저장
                        Task {
                            await self.saveImageToDisk(data: finalData, key: cacheKey)
                            print("💿 [ImageCache] GIF 데이터 디스크 캐시에 저장: \(cacheKey)")
                        }
                        
                        continuation.resume(returning: finalData)
                        
                    case .failure(let error):
                        print("❌ [ImageCache] GIF 데이터 다운로드 실패: \(error)")
                        continuation.resume(returning: nil)
                    }
                }
        }
    }
    
    // GIF 데이터 캐시 키 생성 - UnifiedMediaCacheManager 접근용 public
    func generateGIFDataCacheKey(from path: String) -> String {
        return path.replacingOccurrences(of: "/", with: "_") + "_gif_data"
    }
    
    // 캐시된 GIF 데이터 동기적 접근 (네트워크 없는 판별용)
    func getCachedGIFData(forKey key: String) -> Data? {
        return gifDataCache.object(forKey: key as NSString) as Data?
    }
    
    // GIF 프레임 수 감소로 용량 줄이기
    private func compressGIFByReducingFrames(data: Data, targetSizeKB: Int) -> Data? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(imageSource)
        guard frameCount > 2 else { return data } // 프레임이 2개 이하면 그대로
        
        let targetBytes = targetSizeKB * 1024
        let compressionRatio = Double(targetBytes) / Double(data.count)
        
        // 유지할 프레임 비율 계산 (최소 50% 유지)
        let keepRatio = max(0.5, min(1.0, compressionRatio * 1.2))
        let framesToKeep = max(2, Int(Double(frameCount) * keepRatio))
        let frameSkip = max(1, frameCount / framesToKeep)
        
        print("🎬 [GIF압축] 원본 프레임: \(frameCount)개 → 유지 프레임: \(framesToKeep)개 (간격: \(frameSkip))")
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.gif.identifier as CFString,
            framesToKeep,
            nil
        ) else {
            return nil
        }
        
        // GIF 전체 속성 설정
        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0  // 무한 반복
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)
        
        // 선택된 프레임들만 추가
        var addedFrames = 0
        for i in stride(from: 0, to: frameCount, by: frameSkip) {
            guard addedFrames < framesToKeep,
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else {
                continue
            }
            
            // 프레임 메타데이터 유지
            let frameProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as? [String: Any]
            let gifFrameProperties = frameProperties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
            let delayTime = gifFrameProperties?[kCGImagePropertyGIFDelayTime as String] as? Double ?? 0.1
            
            // 딜레이 시간 조정 (프레임을 건너뛰었으므로)
            let adjustedDelay = delayTime * Double(frameSkip)
            
            let frameDict: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFDelayTime as String: adjustedDelay
                ]
            ]
            
            CGImageDestinationAddImage(destination, cgImage, frameDict as CFDictionary)
            addedFrames += 1
        }
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        let compressedSize = mutableData.length
        print("🎬 [GIF압축] 완료: \(data.count / 1024)KB → \(compressedSize / 1024)KB (\(Int((1.0 - Double(compressedSize) / Double(data.count)) * 100))% 절약)")
        
        return mutableData as Data
    }
    
    // 2단계 캐싱용 캐시 키 생성 - UnifiedMediaCacheManager 접근용 public
    func generateCacheKey(from path: String, isFullSize: Bool) -> String {
        let baseName = path.replacingOccurrences(of: "/", with: "_")
        return isFullSize ? "\(baseName)_full_1080x1080" : "\(baseName)_thumb_300x300"
    }
    
    // 호환성을 위한 기존 메서드
    private func generateCacheKey(from path: String) -> String {
        return generateCacheKey(from: path, isFullSize: false)
    }
    
    private func estimateImageCost(_ image: UIImage) -> Int {
        let pixelCount = Int(image.size.width * image.size.height)
        return pixelCount * 4 // RGBA 기준 4바이트 per pixel
    }
    
    // 2단계 캐싱 - 업로드된 이미지 캐싱
    func cacheUploadedImage(image: UIImage, forKey serverPath: String, originalData: Data) {
        // 썸네일 캐시 (기존 방식 - 300x300 이미지)
        let thumbnailKey = generateCacheKey(from: serverPath, isFullSize: false)
        thumbnailCache.setObject(image, forKey: thumbnailKey as NSString, cost: estimateImageCost(image))
        
        // 풀사이즈 캐시 (원본 데이터에서 1080x1080 다운샘플링)
        if let fullSizeImage = ImageProcessingManager.shared.downsampleForDisplay(
            data: originalData,
            pointSize: CGSize(width: 1080, height: 1080),
            scale: UIScreen.main.scale
        ) {
            let fullSizeKey = generateCacheKey(from: serverPath, isFullSize: true)
            fullSizeCache.setObject(fullSizeImage, forKey: fullSizeKey as NSString, cost: estimateImageCost(fullSizeImage))
            print("📊 풀사이즈 캐시 생성 완료: \(fullSizeKey)")
        }
        
        // 디스크 캐시에도 비동기로 저장
        Task {
            await saveImageToDisk(data: originalData, key: thumbnailKey)
        }
        
        print("📊 업로드 이미지 2단계 캐시 저장 완료: \(thumbnailKey)")
    }

    
    func loadImageFromDisk(key: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self,
                      let fileURL = diskCacheURL?.appendingPathComponent(key) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                if FileManager.default.fileExists(atPath: fileURL.path),
                   let data = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: data) {
                    
                    // 파일 접근 시간 갱신 (LRU를 위해)
                    try? FileManager.default.setAttributes(
                        [.modificationDate: Date()],
                        ofItemAtPath: fileURL.path
                    )
                    
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func loadDataFromDisk(key: String) async -> Data? {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self,
                      let fileURL = diskCacheURL?.appendingPathComponent(key) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                if FileManager.default.fileExists(atPath: fileURL.path),
                   let data = try? Data(contentsOf: fileURL) {
                    
                    // 파일 접근 시간 갱신 (LRU를 위해)
                    try? FileManager.default.setAttributes(
                        [.modificationDate: Date()],
                        ofItemAtPath: fileURL.path
                    )
                    
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func loadGIFDataFromDisk(key: String) async -> Data? {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self,
                      let fileURL = diskCacheURL?.appendingPathComponent(key) else {
                    continuation.resume(returning: nil)
                    return
                }

                if FileManager.default.fileExists(atPath: fileURL.path),
                   let data = try? Data(contentsOf: fileURL) {

                    // 파일 접근 시간 갱신 (LRU를 위해)
                    try? FileManager.default.setAttributes(
                        [.modificationDate: Date()],
                        ofItemAtPath: fileURL.path
                    )

                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func saveImageToDisk(data: Data, key: String) async {
        await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                guard let self,
                      let fileURL = diskCacheURL?.appendingPathComponent(key) else {
                    continuation.resume()
                    return
                }
                
                do {
                    try data.write(to: fileURL)
                    continuation.resume()
                } catch {
                    print("❌ Failed to save image to disk: \(error)")
                    continuation.resume()
                }
            }
        }
        
        cleanupDiskCacheIfNeeded()
    }
    
    private func cleanupDiskCacheIfNeeded() {
        queue.async { [weak self] in
            guard let self,
                  let diskCacheURL else { return }
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(
                    at: diskCacheURL,
                    includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
                )
                
                // 전체 캐시 크기 계산
                let totalSize = fileURLs.reduce(0) { total, url in
                    let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                    return total + fileSize
                }
                
                // 최대 크기 초과 시 오래된 파일부터 삭제
                if totalSize > self.maxDiskCacheSize {
                    let sortedFiles = fileURLs.sorted { url1, url2 in
                        let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                        let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                        return date1 < date2
                    }
                    
                    var currentSize = totalSize
                    let targetSize = self.maxDiskCacheSize * 3 / 4 // 75%까지 정리
                    
                    for fileURL in sortedFiles {
                        if currentSize <= targetSize { break }
                        
                        let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                        try? FileManager.default.removeItem(at: fileURL)
                        currentSize -= fileSize
                    }
                }
            } catch {
                print("❌ Failed to cleanup disk cache: \(error)")
            }
        }
    }
    
    // MARK: - Specific Cache Cleanup (게시물 삭제용)
    
    /// 특정 파일의 모든 캐시를 삭제 (썸네일 + 풀사이즈 + 디스크)
    func clearSpecificCache(for filePath: String) {
        let thumbnailKey = generateCacheKey(from: filePath, isFullSize: false)
        let fullSizeKey = generateCacheKey(from: filePath, isFullSize: true)
        let gifKey = generateGIFDataCacheKey(from: filePath)
        
        // 1. 메모리 캐시 삭제
        thumbnailCache.removeObject(forKey: thumbnailKey as NSString)
        fullSizeCache.removeObject(forKey: fullSizeKey as NSString)
        gifDataCache.removeObject(forKey: gifKey as NSString)
        
        // 2. 디스크 캐시 삭제 (백그라운드)
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            await removeImageFromDisk(key: thumbnailKey)
            await removeImageFromDisk(key: fullSizeKey)
        }
        
        print("🗑️ [ImageCacheManager] 특정 파일 캐시 삭제 완료: \(filePath)")
    }
    
    private func removeImageFromDisk(key: String) async {
        guard let diskCacheURL = diskCacheURL else { return }
        
        let fileURL = diskCacheURL.appendingPathComponent(key)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("💾 [ImageCacheManager] 디스크 캐시 파일 삭제: \(key)")
            } catch {
                print("❌ [ImageCacheManager] 디스크 캐시 파일 삭제 실패: \(error)")
            }
        }
    }
    
}
