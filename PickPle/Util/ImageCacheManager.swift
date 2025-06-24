//
//  ImageCacheManager.swift
//  PickPle
//
//  Created by 정인선 on 6/2/25.
//

import SwiftUI
import Alamofire

// MARK: - ImageLoader
@MainActor
final class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    
    private var currentTask: Task<Void, Never>?
    
    deinit {
        print("ImageLoader Deinit")
    }
    
    func loadImage(from path: String, size: CGSize) async {
        currentTask?.cancel()
        
        isLoading = true
        
        currentTask = Task {
            let loadedImage = await ImageCacheManager.shared.loadImage(from: path, size: size)
            
            if !Task.isCancelled {
                self.image = loadedImage
                self.isLoading = false
            }
        }
        
        await currentTask?.value
    }
}

// MARK: - ImageCacheManager
final class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    
    private let fileManager = FileManager.default
    private let memoryCache = NSCache<NSString, UIImage>()
    private var diskCacheURL: URL?
    private let maxDiskCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private let queue = DispatchQueue(label: "ImageCacheQueue", qos: .utility)
    
    private init() {
        setupDiskCache()
        setupMemoryCache()
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    private func setupMemoryCache() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    private func setupNotificationObservers() {
        // 메모리 경고 시 캐시 정리
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            memoryCache.removeAllObjects()
        }
    }
}

extension ImageCacheManager {
    func loadImage(from path: String, size: CGSize) async -> UIImage? {
        let cacheKey = path.replacingOccurrences(of: "/", with: "")
        
        // 메모리 캐시
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        // 디스크 캐시
        if let diskImage = await loadImageFromDisk(key: cacheKey) {
            // 메모리 캐시에도 저장
            memoryCache.setObject(diskImage, forKey: cacheKey as NSString)
            return diskImage
        }
        
        // 네트워크에서 이미지 다운로드
        return await downloadImage(from: path, cacheKey: cacheKey, size: size)
    }
    
    private func loadImageFromDisk(key: String) async -> UIImage? {
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
    
    private func downloadImage(from path: String, cacheKey: String, size: CGSize) async -> UIImage? {
        let fullURL = APIURL.PICKUP + "/v1\(path)"
        guard let url = URL(string: fullURL) else { return nil }
        
        do {
            let request = API.session.request(url, method: .get)
            let data = try await request.serializingData().value
            guard let image = downsampling(data: data, pointSize: size, scale: UITraitCollection.current.displayScale) else { return nil }
            
            // 메모리 캐시에 저장
            memoryCache.setObject(image, forKey: cacheKey as NSString)
            // 디스크 캐시에 저장
            await saveImageToDisk(data: data, key: cacheKey)
            return image
        } catch {
            print("❌ Image download failed: \(error)")
            return nil
        }
    }
    
    private func saveImageToDisk(data: Data, key: String) async {
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
    
    private func downsampling(data: Data, pointSize: CGSize, scale: CGFloat) -> UIImage? {
            let imageSourceOption = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOption) else {
                print("\(#function) -> imageSource exit")
                return nil
            }
            
            let maxDimensionsInPixels = max(pointSize.width, pointSize.height) * scale
            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimensionsInPixels
            ] as CFDictionary
            
            guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
                print("\(#function) -> downsampledImage exit")
                return nil
            }
            
            return UIImage(cgImage: downsampledImage)
        }
}
