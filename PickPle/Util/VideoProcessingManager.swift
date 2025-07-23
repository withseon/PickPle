//
//  VideoProcessingManager.swift
//  PickPle
//
//  Created by 정인선 on 7/29/25.
//

import Foundation
import AVFoundation
import CoreMedia
import UIKit

// MARK: - Supporting Types
enum VideoComplexity {
    case low     // 정적 화면, 단순한 움직임
    case medium  // 일반적인 동영상
    case high    // 빠른 움직임, 복잡한 장면
}

struct VideoMetadata {
    let duration: Double        // 길이 (초)
    let resolution: CGSize      // 해상도
    let currentBitrate: Double  // 현재 비트레이트
    let fileSize: Int64         // 현재 파일 크기
    let complexity: VideoComplexity // 영상 복잡도
}

struct CompressionSettings {
    let videoBitrate: Double
    let audioBitrate: Double
    let resolution: CGSize
    let frameRate: Double
}

struct CompressionResult {
    let url: URL
    let fileSize: Int64
    let actualBitrate: Double
    let compressionRatio: Float
}

enum ValidationCompressionResult {
    case success(Float)                                    // 목표 달성
    case tooLarge(Float, compressionRatio: Float)         // 재압축 필요
    case tooSmall(Float, qualityLoss: Float)              // 품질 손실 알림
}

enum VideoError: Error {
    case noVideoTrack
    case cannotCreateExportSession
    case compressionFailed
    case compressionCancelled
    case maxAttemptsReached
    case unknownError
    case fileNotFound
    case invalidFormat
}

// MARK: - VideoProcessingManager

final class VideoProcessingManager {
    static let shared = VideoProcessingManager()
    private init() {}
    
    private let maxAttempts = 5
    private let tolerancePercent: Float = 0.1 // 10% 오차 허용
    private let defaultTargetSizeMB: Float = 5.0
    
    // MARK: - 메인 압축 메서드
    func compressVideoTo5MB(
        inputURL: URL,
        targetSizeMB: Float = 5.0
    ) async throws -> CompressionResult {
        
        logProcessing("동영상 압축 시작 - 목표 크기: \(targetSizeMB)MB")
        
        // 1. 동영상 분석
        let metadata = try await analyzeVideo(inputURL)
        logProcessing("분석 완료 - 길이: \(String(format: "%.1f", metadata.duration))초, 크기: \(metadata.fileSize / 1024 / 1024)MB, 복잡도: \(metadata.complexity)")
        
        // 2. 반복적 압축으로 목표 크기 달성
        return try await adaptiveCompress(
            inputURL: inputURL,
            metadata: metadata,
            targetSizeMB: targetSizeMB
        )
    }
    
    // MARK: - PhotoPicker용 썸네일 생성 (미리보기용, 캐싱 없음)
    func generateThumbnailDataForPreview(
        _ videoURL: URL,
        size: CGSize = CGSize(width: 200, height: 200)
    ) async -> Data? {
        
        logProcessing("📹 미리보기 썸네일 직접 생성 시작: \(videoURL.lastPathComponent) (\(Int(size.width))x\(Int(size.height)))")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let thumbnailData = await generateThumbnailDataCore(from: videoURL, size: size)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        if let data = thumbnailData {
            logProcessing("✅ 미리보기 썸네일 생성 완료: \(Int(processingTime * 1000))ms, \(data.count / 1024)KB")
        } else {
            logProcessing("❌ 미리보기 썸네일 생성 실패: \(Int(processingTime * 1000))ms")
        }
        
        return thumbnailData
    }
    
    // MARK: - 서버 동영상용 썸네일 생성 (캐싱 적용)
    func generateThumbnailDataForServer(
        _ videoURL: URL,
        size: CGSize = CGSize(width: 300, height: 300)
    ) async -> Data? {
        
        // ImageCacheManager와 유사한 캐싱 전략 사용
        return await ServerVideoThumbnailCache.shared.loadThumbnail(
            from: videoURL.absoluteString,
            size: size
        ) { [weak self] in
            // 캐시 미스 시 실제 생성
            return await self?.generateThumbnailDataCore(from: videoURL, size: size)
        }
    }
    
    // MARK: - 동영상 분석
    private func analyzeVideo(_ inputURL: URL) async throws -> VideoMetadata {
        let asset = AVAsset(url: inputURL)
        
        // 기본 정보 추출
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        
        guard let videoTrack = tracks.first else {
            throw VideoError.noVideoTrack
        }
        
        // 상세 정보 추출
        let naturalSize = try await videoTrack.load(.naturalSize)
        let estimatedDataRate = try await videoTrack.load(.estimatedDataRate)
        let fileSize = getFileSize(inputURL)
        
        // 복잡도 분석
        let complexity = await analyzeComplexity(asset)
        
        return VideoMetadata(
            duration: duration.seconds,
            resolution: naturalSize,
            currentBitrate: Double(estimatedDataRate),
            fileSize: fileSize,
            complexity: complexity
        )
    }
    
    // MARK: - 복잡도 분석 (iOS 16.0+ 최신 API 사용)
    private func analyzeComplexity(_ asset: AVAsset) async -> VideoComplexity {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 200, height: 200) // 빠른 분석용 작은 크기
        
        do {
            // iOS 16.0+ 비동기 API로 duration 로드
            let duration = try await asset.load(.duration)
            let durationSeconds = duration.seconds
            
            // 10개 샘플 프레임으로 복잡도 측정
            let sampleCount = 10
            let interval = durationSeconds / Double(sampleCount)
            
            var frameDifferences: [Double] = []
            var previousFrame: CGImage?
            
            for i in 0..<sampleCount {
                let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 600)
                
                do {
                    // iOS 16.0+ 새로운 비동기 이미지 생성 API
                    let (currentFrame, _) = try await generator.image(at: time)
                    
                    if let previous = previousFrame {
                        let difference = calculateFrameDifference(previous, currentFrame)
                        frameDifferences.append(difference)
                    }
                    previousFrame = currentFrame
                } catch {
                    continue // 실패한 프레임은 건너뛰기
                }
            }
            
            guard !frameDifferences.isEmpty else { 
                print("📹 복잡도 분석 실패: 프레임 추출 불가")
                return .medium 
            }
            
            let averageDifference = frameDifferences.reduce(0, +) / Double(frameDifferences.count)
            
            switch averageDifference {
            case 0..<0.1: return .low      // 정적 영상
            case 0.1..<0.3: return .medium // 일반 영상  
            default: return .high          // 동적 영상
            }
            
        } catch {
            print("📹 복잡도 분석 실패: \(error)")
            return .medium // 에러 발생시 기본값
        }
    }
    
    // MARK: - 반복적 압축
    private func adaptiveCompress(
        inputURL: URL,
        metadata: VideoMetadata,
        targetSizeMB: Float
    ) async throws -> CompressionResult {
        
        let asset = AVAsset(url: inputURL)
        var currentSettings = calculateInitialSettings(metadata: metadata, targetSizeMB: targetSizeMB)
        
        for attempt in 0..<maxAttempts {
            logProcessing("압축 시도 \(attempt + 1)/\(maxAttempts) - 비트레이트: \(Int(currentSettings.videoBitrate/1000))kbps")
            
            // 임시 출력 파일 생성
            let tempURL = createTempURL(attempt: attempt)
            
            do {
                // 압축 실행
                let result = try await compressVideo(
                    asset: asset,
                    settings: currentSettings,
                    outputURL: tempURL
                )
                
                // 결과 검증
                let validation = validateCompressionResult(
                    result: result,
                    targetSizeMB: targetSizeMB
                )
                
                switch validation {
                case .success(let actualSize):
                    logProcessing("압축 성공! 최종 크기: \(String(format: "%.1f", actualSize))MB")
                    return result
                    
                case .tooLarge(let actualSize, let compressionRatio):
                    logProcessing("시도 \(attempt + 1): 파일이 큼 (\(String(format: "%.1f", actualSize))MB) - 재압축 필요")
                    
                    if attempt < maxAttempts - 1 {
                        currentSettings = adjustSettingsForNextAttempt(
                            currentSettings: currentSettings,
                            compressionRatio: compressionRatio,
                            attempt: attempt
                        )
                        try? FileManager.default.removeItem(at: tempURL)
                    } else {
                        logProcessing("최대 시도 횟수 도달 - 현재 결과 반환")
                        return result
                    }
                    
                case .tooSmall(let actualSize, _):
                    logProcessing("목표보다 작음 (\(String(format: "%.1f", actualSize))MB) - 완료")
                    return result
                }
                
            } catch {
                if attempt < maxAttempts - 1 {
                    logProcessing("압축 실패, 재시도: \(error)")
                    continue
                } else {
                    throw error
                }
            }
        }
        
        throw VideoError.maxAttemptsReached
    }
    
    // MARK: - 초기 설정 계산
    private func calculateInitialSettings(
        metadata: VideoMetadata,
        targetSizeMB: Float
    ) -> CompressionSettings {
        
        // 1. 기본 목표 비트레이트 계산
        let targetSizeBytes = Double(targetSizeMB * 1024 * 1024)
        let totalBitsAvailable = targetSizeBytes * 8
        
        // 2. 오디오 비트레이트 제외 (128kbps)
        let audioBitrate: Double = 128000
        let videoBitsPerSecond = (totalBitsAvailable / metadata.duration) - audioBitrate
        
        // 3. 컨테이너 오버헤드 고려 (10%)
        let adjustedVideoBitrate = videoBitsPerSecond * 0.9
        
        // 4. 복잡도에 따른 조정
        let complexityAdjustedBitrate = adjustForComplexity(
            adjustedVideoBitrate,
            complexity: metadata.complexity
        )
        
        // 5. 해상도 결정
        let targetResolution = determineOptimalResolution(
            original: metadata.resolution,
            targetBitrate: complexityAdjustedBitrate
        )
        
        return CompressionSettings(
            videoBitrate: complexityAdjustedBitrate,
            audioBitrate: audioBitrate,
            resolution: targetResolution,
            frameRate: 30
        )
    }
    
    // MARK: - 복잡도별 비트레이트 조정
    private func adjustForComplexity(_ bitrate: Double, complexity: VideoComplexity) -> Double {
        switch complexity {
        case .low:
            return bitrate * 0.7    // 30% 감소 - 정적 영상
        case .medium:
            return bitrate * 1.0    // 그대로
        case .high:
            return bitrate * 1.2    // 20% 증가 - 동적 영상
        }
    }
    
    // MARK: - 해상도 최적화
    private func determineOptimalResolution(
        original: CGSize,
        targetBitrate: Double
    ) -> CGSize {
        
        let pixelCount = original.width * original.height
        let bitsPerPixel = targetBitrate / Double(pixelCount)
        
        // 비트레이트 밀도에 따른 해상도 조정
        let scaleFactor: CGFloat
        
        switch bitsPerPixel {
        case 0..<0.1:
            scaleFactor = 0.5      // 50% 크기
        case 0.1..<0.2:
            scaleFactor = 0.7      // 70% 크기  
        case 0.2..<0.4:
            scaleFactor = 0.85     // 85% 크기
        default:
            scaleFactor = 1.0      // 원본 크기
        }
        
        let newWidth = (original.width * scaleFactor / 16).rounded() * 16  // 16의 배수로 정렬
        let newHeight = (original.height * scaleFactor / 16).rounded() * 16
        
        return CGSize(width: newWidth, height: newHeight)
    }
    
    // MARK: - 압축 실행 (iOS 16.0+ 최신 API 사용)
    private func compressVideo(
        asset: AVAsset,
        settings: CompressionSettings,
        outputURL: URL
    ) async throws -> CompressionResult {
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            throw VideoError.cannotCreateExportSession
        }
        
        // iOS 16.0+ 비동기 API로 필요한 속성들 로드
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        
        guard let videoTrack = tracks.first else {
            throw VideoError.noVideoTrack
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        
        // 출력 설정
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        // 비디오 컴포지션 적용 (필요한 속성들 전달)
        exportSession.videoComposition = createVideoComposition(
            asset: asset, 
            settings: settings, 
            duration: duration, 
            naturalSize: naturalSize
        )
        
        // 압축 실행
        await exportSession.export()
        
        // 결과 확인
        switch exportSession.status {
        case .completed:
            let resultSize = getFileSize(outputURL)
            let actualBitrate = calculateActualBitrate(resultSize, duration: duration.seconds)
            
            return CompressionResult(
                url: outputURL,
                fileSize: resultSize,
                actualBitrate: actualBitrate,
                compressionRatio: Float(getFileSize(asset.sourceURL)) / Float(resultSize)
            )
        case .failed:
            throw exportSession.error ?? VideoError.compressionFailed
        case .cancelled:
            throw VideoError.compressionCancelled
        default:
            throw VideoError.unknownError
        }
    }
    
    // MARK: - 비디오 컴포지션 생성 (iOS 16.0+ 호환)
    private func createVideoComposition(
        asset: AVAsset,
        settings: CompressionSettings,
        duration: CMTime,
        naturalSize: CGSize
    ) -> AVMutableVideoComposition {
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = settings.resolution
        videoComposition.frameDuration = CMTime(value: 1, timescale: Int32(settings.frameRate))
        
        let tracks = asset.tracks(withMediaType: .video)
        guard let videoTrack = tracks.first else {
            fatalError("No video track found")
        }
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        
        // 해상도 변경을 위한 Transform 계산 (매개변수로 받은 naturalSize 사용)
        let targetSize = settings.resolution
        
        let scaleX = targetSize.width / naturalSize.width
        let scaleY = targetSize.height / naturalSize.height
        let scale = min(scaleX, scaleY) // Aspect ratio 유지
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        layerInstruction.setTransform(transform, at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        return videoComposition
    }
    
    // MARK: - 결과 검증
    private func validateCompressionResult(
        result: CompressionResult,
        targetSizeMB: Float
    ) -> ValidationCompressionResult {
        
        let resultSizeMB = Float(result.fileSize) / (1024 * 1024)
        let lowerBound = targetSizeMB * (1 - tolerancePercent)
        let upperBound = targetSizeMB * (1 + tolerancePercent)
        
        if resultSizeMB >= lowerBound && resultSizeMB <= upperBound {
            return .success(resultSizeMB)
        } else if resultSizeMB > upperBound {
            return .tooLarge(resultSizeMB, compressionRatio: targetSizeMB / resultSizeMB)
        } else {
            return .tooSmall(resultSizeMB, qualityLoss: (targetSizeMB - resultSizeMB) / targetSizeMB)
        }
    }
    
    // MARK: - 설정 재조정 (5단계 강화 압축)
    private func adjustSettingsForNextAttempt(
        currentSettings: CompressionSettings,
        compressionRatio: Float,
        attempt: Int
    ) -> CompressionSettings {
        
        logProcessing("압축 단계 \(attempt + 2)/5: 압축비 \(String(format: "%.1f", compressionRatio))배 필요")
        
        switch attempt {
        case 0: // 1차 실패 후 - 비트레이트만 50% 감소
            return CompressionSettings(
                videoBitrate: currentSettings.videoBitrate * 0.5,
                audioBitrate: currentSettings.audioBitrate,
                resolution: currentSettings.resolution,
                frameRate: currentSettings.frameRate
            )
            
        case 1: // 2차 실패 후 - 720p + 비트레이트 40% 감소  
            let newResolution = constrainToStandardResolution(
                target: CGSize(width: 1280, height: 720),
                original: currentSettings.resolution
            )
            
            return CompressionSettings(
                videoBitrate: currentSettings.videoBitrate * 0.4,
                audioBitrate: currentSettings.audioBitrate,
                resolution: newResolution,
                frameRate: currentSettings.frameRate
            )
            
        case 2: // 3차 실패 후 - 480p + 비트레이트 30% 감소
            let newResolution = constrainToStandardResolution(
                target: CGSize(width: 854, height: 480),
                original: currentSettings.resolution
            )
            
            return CompressionSettings(
                videoBitrate: currentSettings.videoBitrate * 0.3,
                audioBitrate: currentSettings.audioBitrate,
                resolution: newResolution,
                frameRate: currentSettings.frameRate
            )
            
        case 3: // 4차 실패 후 - 480p + 24fps + 비트레이트 20% 감소
            let newResolution = constrainToStandardResolution(
                target: CGSize(width: 854, height: 480),
                original: currentSettings.resolution
            )
            
            return CompressionSettings(
                videoBitrate: currentSettings.videoBitrate * 0.2,
                audioBitrate: currentSettings.audioBitrate,
                resolution: newResolution,
                frameRate: 24
            )
            
        default: // 5차 실패 후 - 360p + 최대 압축 (마지막 시도)
            let newResolution = constrainToStandardResolution(
                target: CGSize(width: 640, height: 360),
                original: currentSettings.resolution
            )
            
            return CompressionSettings(
                videoBitrate: currentSettings.videoBitrate * 0.15,
                audioBitrate: 96000, // 오디오 비트레이트도 감소
                resolution: newResolution,
                frameRate: 24
            )
        }
    }
    
    // MARK: - 표준 해상도로 제한 (aspect ratio 유지)
    private func constrainToStandardResolution(target: CGSize, original: CGSize) -> CGSize {
        // 원본 aspect ratio 계산
        let aspectRatio = original.width / original.height
        
        var width = target.width
        var height = target.height
        
        // aspect ratio를 유지하면서 target 크기에 맞춤
        if target.width / target.height > aspectRatio {
            // 높이 기준으로 조정
            width = height * aspectRatio
        } else {
            // 너비 기준으로 조정
            height = width / aspectRatio
        }
        
        // 16의 배수로 정렬 (비디오 인코딩 최적화)
        width = (width / 16).rounded() * 16
        height = (height / 16).rounded() * 16
        
        // 최소 해상도 보장 (240p)
        width = max(width, 320)
        height = max(height, 240)
        
        return CGSize(width: width, height: height)
    }
    
    
    // MARK: - 헬퍼 메서드들
    private func calculateFrameDifference(_ image1: CGImage, _ image2: CGImage) -> Double {
        // 간단한 픽셀 차이 계산
        guard let data1 = image1.dataProvider?.data,
              let data2 = image2.dataProvider?.data,
              CFDataGetLength(data1) == CFDataGetLength(data2) else {
            return 1.0
        }
        
        let bytes1 = CFDataGetBytePtr(data1)
        let bytes2 = CFDataGetBytePtr(data2)
        let length = CFDataGetLength(data1)
        
        var totalDifference = 0
        for i in 0..<length {
            totalDifference += abs(Int(bytes1![i]) - Int(bytes2![i]))
        }
        
        return Double(totalDifference) / Double(length * 255)
    }
    
    private func getFileSize(_ url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func calculateActualBitrate(_ fileSize: Int64, duration: Double) -> Double {
        return Double(fileSize * 8) / duration
    }
    
    private func createTempURL(attempt: Int) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "compressed_video_attempt_\(attempt)_\(UUID().uuidString).mp4"
        return tempDir.appendingPathComponent(fileName)
    }
    
    private func logProcessing(_ message: String) {
        print("🎬 \(message)")
    }
    
    // MARK: - 썸네일 생성 핵심 로직 (iOS 16.0+ 최신 API 사용)
    func generateThumbnailDataCore(from videoURL: URL, size: CGSize) async -> Data? {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        
        generator.maximumSize = size
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        do {
            // iOS 16.0+ 비동기 API 사용
            let duration = try await asset.load(.duration)
            let time = CMTime(seconds: duration.seconds * 0.3, preferredTimescale: 600)
            
            // iOS 16.0+ 새로운 비동기 이미지 생성 API
            let (cgImage, _) = try await generator.image(at: time)
            
            // 직접 CGImage → JPEG Data 변환 (UIImage 생략)
            let mutableData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                mutableData,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            ) else {
                logProcessing("썸네일 destination 생성 실패")
                return nil
            }
            
            // JPEG 압축 옵션 (품질 0.8)
            let options = [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary
            CGImageDestinationAddImage(destination, cgImage, options)
            
            guard CGImageDestinationFinalize(destination) else {
                logProcessing("썸네일 finalize 실패")
                return nil
            }
            
            return mutableData as Data
            
        } catch {
            logProcessing("썸네일 생성 실패: \(error)")
            return nil
        }
    }
}

// MARK: - ServerVideoThumbnailCache (서버 동영상 썸네일 캐싱)
final class ServerVideoThumbnailCache: CacheManagerProtocol {
    typealias CacheKey = NSString
    typealias CacheValue = NSData
    static let shared = ServerVideoThumbnailCache()
    
    let memoryCache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let cacheQueue = DispatchQueue(label: "com.pickple.server.video.thumbnail.cache", qos: .utility)
    
    private init() {
        // 캐시 디렉토리 설정
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("ServerVideoThumbnails")
        
        createCacheDirectoryIfNeeded()
        setupMemoryCache()
        setupLifecycleObservers()
        
        logCaching("🎬 서버 동영상 썸네일 캐시 초기화 완료 (메모리 + 디스크 캐싱)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 캐시 로드 (ImageCacheManager와 유사한 패턴)
    func loadThumbnail(
        from videoPath: String,
        size: CGSize,
        generator: () async -> Data?
    ) async -> Data? {
        
        let cacheKey = generateCacheKey(path: videoPath, size: size)
        
        // 1. 메모리 캐시 확인
        if let cachedData = memoryCache.object(forKey: cacheKey) {
            logCaching("✅ 서버 동영상 썸네일 메모리 캐시 히트: \(cacheKey)")
            return cachedData as Data
        }
        
        // 2. 디스크 캐시 확인
        let diskCacheURL = diskCacheURL(for: cacheKey)
        if fileManager.fileExists(atPath: diskCacheURL.path),
           let diskData = try? Data(contentsOf: diskCacheURL) {
            
            // 메모리 캐시에도 저장
            memoryCache.setObject(diskData as NSData, forKey: cacheKey, cost: diskData.count)
            logCaching("✅ 서버 동영상 썸네일 디스크 캐시 히트: \(cacheKey)")
            return diskData
        }
        
        // 3. 캐시 미스 - 새로 생성
        logCaching("🔄 서버 동영상 썸네일 생성 시작: \(cacheKey)")
        
        guard let thumbnailData = await generator() else {
            logCaching("❌ 서버 동영상 썸네일 생성 실패: \(cacheKey)")
            return nil
        }
        
        // 4. 캐시 저장 (백그라운드)
        Task.detached(priority: .utility) { [weak self] in
            await self?.storeThumbnailData(thumbnailData, forKey: cacheKey, diskURL: diskCacheURL)
        }
        
        // 5. 즉시 메모리 캐시 저장
        memoryCache.setObject(thumbnailData as NSData, forKey: cacheKey, cost: thumbnailData.count)
        
        logCaching("✅ 서버 동영상 썸네일 생성 및 캐시 저장: \(cacheKey), \(thumbnailData.count / 1024)KB")
        return thumbnailData
    }
    
    // MARK: - 데이터 기반 썸네일 생성 (UnifiedMediaCacheManager 전용)
    func generateThumbnailFromData(data: Data, url: String, size: CGSize) async -> Data? {
        let cacheKey = generateCacheKey(path: url, size: size)
        
        print("🎬 [ServerVideoCache] 데이터 기반 썸네일 생성 시작: \(cacheKey) (\(data.count / 1024)KB)")
        
        // 임시 파일 생성 (AVAsset이 Data를 직접 처리할 수 없음)
        let tempURL = createTempFileURL(data: data, extension: "mp4")
        
        defer {
            // 임시 파일 정리
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        print("🎬 [ServerVideoCache] 임시 동영상 파일 생성: \(tempURL.path)")
        
        // VideoProcessingManager로 썸네일 생성
        guard let thumbnailData = await VideoProcessingManager.shared.generateThumbnailDataCore(from: tempURL, size: size) else {
            print("❌ [ServerVideoCache] 썸네일 생성 실패: \(url)")
            return nil
        }
        
        // 캐시 저장 (백그라운드)
        let diskURL = diskCacheURL(for: cacheKey)
        Task.detached(priority: .utility) { [weak self] in
            await self?.storeThumbnailData(thumbnailData, forKey: cacheKey, diskURL: diskURL)
        }
        
        // 즉시 메모리 캐시 저장
        memoryCache.setObject(thumbnailData as NSData, forKey: cacheKey, cost: thumbnailData.count)
        
        print("✅ [ServerVideoCache] 데이터 기반 썸네일 생성 및 캐시 저장: \(cacheKey), \(thumbnailData.count / 1024)KB")
        return thumbnailData
    }
    
    // 임시 파일 생성 헬퍼
    private func createTempFileURL(data: Data, extension ext: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
        try? data.write(to: tempFile)
        return tempFile
    }
    
    // MARK: - 캐시 키 생성
    private func generateCacheKey(path: String, size: CGSize) -> NSString {
        // 동영상 썸네일은 크기에 관계없이 파일명만으로 캐시키 생성
        // (동영상은 풀사이즈/썸네일 구분이 없고, 뷰에서 크기 조정하므로)
        let fileName = extractFileName(from: path)
        
        return "vid_\(fileName)" as NSString
    }
    
    // URL에서 파일명만 추출
    private func extractFileName(from path: String) -> String {
        guard let url = URL(string: path) else { return path }
        return url.lastPathComponent
    }
    
    private func diskCacheURL(for cacheKey: NSString) -> URL {
        return cacheDirectory.appendingPathComponent(cacheKey as String)
    }
    
    // MARK: - 캐시 저장
    private func storeThumbnailData(_ data: Data, forKey cacheKey: NSString, diskURL: URL) async {
        do {
            try data.write(to: diskURL)
            logCaching("💾 서버 동영상 썸네일 디스크 저장 완료: \(cacheKey)")
        } catch {
            logCaching("❌ 서버 동영상 썸네일 디스크 저장 실패: \(error)")
        }
    }
    
    // MARK: - 캐시 설정
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func setupMemoryCache() {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let cacheLimit = min(50 * 1024 * 1024, Int(totalMemory / 20)) // 최대 50MB 또는 전체 메모리의 5%
        
        memoryCache.totalCostLimit = cacheLimit
        memoryCache.countLimit = max(20, cacheLimit / (200 * 1024)) // 평균 200KB per thumbnail
        
        logCaching("🎬 서버 동영상 썸네일 메모리 캐시 설정: \(cacheLimit / 1024 / 1024)MB")
    }
    
    private func setupLifecycleObservers() {
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
    
    // MARK: - 메모리 관리
    func handleMemoryWarning() {
        memoryCache.removeAllObjects()
        logCaching("⚠️ 메모리 부족 - 서버 동영상 썸네일 메모리 캐시 전체 삭제")
    }
    
    private func handleBackgroundTransition() {
        // 백그라운드에서는 메모리 캐시 크기 축소
        let originalLimit = memoryCache.totalCostLimit
        memoryCache.totalCostLimit = originalLimit / 4
        memoryCache.countLimit = max(5, memoryCache.countLimit / 4)
        
        logCaching("🌙 백그라운드 모드: 서버 동영상 썸네일 메모리 캐시 25%로 축소")
    }
    
    // MARK: - 캐시 정리
    
    /// 특정 파일의 캐시를 삭제 (게시물 삭제용)
    func clearSpecificCache(for filePath: String) {
        let cacheKey = generateCacheKey(path: filePath, size: .zero) // 크기는 사용되지 않음
        
        // 1. 메모리 캐시에서 삭제
        memoryCache.removeObject(forKey: cacheKey)
        
        // 2. 디스크 캐시에서 삭제 (백그라운드)
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            
            let diskURL = self.diskCacheURL(for: cacheKey)
            
            if self.fileManager.fileExists(atPath: diskURL.path) {
                do {
                    try self.fileManager.removeItem(at: diskURL)
                    print("💾 [ServerVideoCache] 디스크 캐시 파일 삭제: \(cacheKey)")
                } catch {
                    print("❌ [ServerVideoCache] 디스크 캐시 파일 삭제 실패: \(error)")
                }
            }
        }
        
        print("🗑️ [ServerVideoCache] 특정 파일 캐시 삭제 완료: \(filePath)")
    }
    
    func clearCache(for videoPath: String) {
        cacheQueue.async { [weak self] in
            guard let self else { return }
            
            // 해당 동영상의 모든 크기 썸네일 삭제 (파일명 기반)
            let fileName = extractFileName(from: videoPath)
            let pattern = "vid_\(fileName)_"
            
            do {
                let files = try self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil)
                for file in files {
                    if file.lastPathComponent.hasPrefix(pattern) {
                        try self.fileManager.removeItem(at: file)
                        
                        // 메모리 캐시에서도 제거 (정확한 키를 모르므로 전체 정리)
                        DispatchQueue.main.async {
                            self.memoryCache.removeAllObjects()
                        }
                    }
                }
                self.logCaching("🗑️ 서버 동영상 썸네일 캐시 삭제 완료: \(videoPath)")
            } catch {
                self.logCaching("❌ 서버 동영상 썸네일 캐시 삭제 실패: \(error)")
            }
        }
    }
    
    func clearAllCache() {
        cacheQueue.async { [weak self] in
            guard let self else { return }
            
            // 디스크 캐시 전체 삭제
            try? self.fileManager.removeItem(at: self.cacheDirectory)
            self.createCacheDirectoryIfNeeded()
            
            // 메모리 캐시 전체 삭제
            DispatchQueue.main.async {
                self.memoryCache.removeAllObjects()
            }
            
            self.logCaching("🗑️ 서버 동영상 썸네일 캐시 전체 삭제 완료")
        }
    }
    
    func logCaching(_ message: String) {
        print("🎬💾 \(message)")
    }
}


// MARK: - Supporting Extensions

extension AVAsset {
    var sourceURL: URL {
        return (self as? AVURLAsset)?.url ?? URL(fileURLWithPath: "")
    }
}

// MARK: - String SHA256 Extension
import CryptoKit

extension String {
    var sha256Hash: String {
        let inputData = Data(self.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
    }
}
