//
//  ImageProcessingManager.swift
//  PickPle
//
//  Created by 정인선 on 7/29/25.
//

import UIKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - ImageProcessingManager
final class ImageProcessingManager {
    static let shared = ImageProcessingManager()
    private init() {}
    
    // MARK: - 다운샘플링 (표시용)
    /// 화면 표시용 다운샘플링 - UIImage 반환
    func downsampleForDisplay(data: Data, pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOption = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOption) else {
            return nil
        }
        
        // GIF인지 확인 - 첫 프레임만 사용하여 메모리 최적화
        let frameCount = CGImageSourceGetCount(imageSource)
        if frameCount > 1 {
            print("📊 GIF 미리보기: 첫 프레임만 다운샘플링 (\(frameCount)프레임 → 1프레임)")
        }
        
        let maxDimensionsInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionsInPixels
        ] as CFDictionary
        
        // 항상 첫 프레임(index 0)만 사용 - GIF 애니메이션도 첫 프레임으로 미리보기
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    // MARK: - 공통 유틸리티
    private func createImageSource(from data: Data) -> CGImageSource? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        return CGImageSourceCreateWithData(data as CFData, options)
    }
    
    private func createDownsampleOptions(maxPixelSize: CGFloat) -> CFDictionary {
        return [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
    }
    
    private func logProcessing(_ message: String) {
        print("📊 \(message)")
    }
    
    // MARK: - 수정된 전략 패턴
    enum ProcessingStrategy {
        case keepOriginal(format: ImageFormat)
        case convertToJPEG(targetSize: CGSize?, quality: CGFloat)
        case compressGIF(maxSizeKB: Int)
        case downsampleWithOriginalFormat(targetSize: CGSize, format: ImageFormat, quality: CGFloat)
    }
    
    // MARK: - 메인 처리 메서드
    func prepareImageDataForUpload(
        _ data: Data,
        format: ImageFormat = .jpeg,
        maxSizeKB: Int = 5120,
        targetSize: CGSize? = nil
    ) -> (data: Data, actualFormat: ImageFormat)? {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        logProcessing("처리 시작 - 원본 크기: \(data.count / 1024)KB, 포맷: \(format)")
        
        // 1. 실제 포맷 감지 (매개변수 format과 다를 수 있음)
        let detectedFormat = detectFormat(from: data)
        logProcessing("감지된 포맷: \(detectedFormat), 요청 포맷: \(format)")
        
        // 2. 처리 전략 결정 (감지된 포맷 기준)
        let strategy = determineProcessingStrategy(
            data: data,
            format: detectedFormat,
            maxSizeKB: maxSizeKB,
            targetSize: targetSize
        )
        
        // 3. 전략에 따른 처리 실행
        let result = executeStrategy(strategy, data: data)
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        if let result = result {
            logProcessing("처리 완료 - 최종 크기: \(result.data.count / 1024)KB, 최종 포맷: \(result.actualFormat), 소요시간: \(String(format: "%.3f", processingTime))초")
        }
        
        return result
    }
    
    // MARK: - 수정된 전략 결정 로직
    private func determineProcessingStrategy(
        data: Data,
        format: ImageFormat,
        maxSizeKB: Int,
        targetSize: CGSize?
    ) -> ProcessingStrategy {
        
        let maxBytes = maxSizeKB * 1024
        let isOversized = data.count > maxBytes
        let isLargeFile = data.count > 500 * 1024
        
        switch format {
        case .webp:
            // WebP는 iOS에서 출력 지원이 제한적이므로 큰 파일은 JPEG로 변환
            if isOversized {
                return .convertToJPEG(targetSize: targetSize, quality: 0.8)
            } else {
                return .keepOriginal(format: .webp)
            }
                
        case .gif:
            // GIF는 애니메이션 유지 시도, 실패시만 JPEG 변환
            if isOversized {
                return .compressGIF(maxSizeKB: maxSizeKB)
            } else {
                return .keepOriginal(format: .gif)
            }
                
        case .jpeg, .png:
            // 우선순위: 1) targetSize 지정됨 2) 큰 파일 3) 원본 유지
            if let targetSize {
                return .downsampleWithOriginalFormat(
                    targetSize: targetSize,
                    format: format,
                    quality: 0.8
                )
            }
            
            if isLargeFile {
                let defaultTargetSize = CGSize(width: 1080, height: 1080)
                return .downsampleWithOriginalFormat(
                    targetSize: defaultTargetSize,
                    format: format,
                    quality: 0.8
                )
            }
            
            return .keepOriginal(format: format)
            
        default:
            // 지원하지 않는 포맷은 JPEG로 변환
            return .convertToJPEG(targetSize: targetSize, quality: 0.8)
        }
    }
    
    // MARK: - 수정된 전략 실행
    private func executeStrategy(
        _ strategy: ProcessingStrategy,
        data: Data
    ) -> (data: Data, actualFormat: ImageFormat)? {
        
        switch strategy {
        case .keepOriginal(let format):
            logProcessing("원본 유지 - 포맷: \(format)")
            return (data: data, actualFormat: format)
            
        case .convertToJPEG(let targetSize, let quality):
            logProcessing("JPEG 변환 - targetSize: \(targetSize?.debugDescription ?? "nil")")
            guard let jpegData = convertToJPEG(data, targetSize: targetSize, quality: quality) else {
                return nil
            }
            return (data: jpegData, actualFormat: .jpeg)
            
        case .compressGIF(let maxSizeKB):
            logProcessing("GIF 압축 시도")
            if let compressedGIF = compressGIFByReducingFrames(data, maxSizeKB: maxSizeKB) {
                logProcessing("GIF 압축 성공 - 애니메이션 유지")
                return (data: compressedGIF, actualFormat: .gif)
            } else {
                logProcessing("GIF 압축 실패 - JPEG로 변환")
                guard let jpegData = convertToJPEG(
                    data,
                    targetSize: CGSize(width: 1080, height: 1080),
                    quality: 0.8
                ) else {
                    return nil
                }
                return (data: jpegData, actualFormat: .jpeg)
            }
            
        case .downsampleWithOriginalFormat(let targetSize, let format, let quality):
            logProcessing("다운샘플링 - targetSize: \(targetSize), 포맷 유지: \(format)")
            guard let processedData = downsampleWithFormat(
                data,
                targetSize: targetSize,
                format: format,
                quality: quality
            ) else {
                return nil
            }
            return (data: processedData, actualFormat: format)
        }
    }
    
    // MARK: - 포맷별 인코딩 (수정됨)
    private func encodeImage(
        _ cgImage: CGImage,
        format: ImageFormat,
        quality: CGFloat
    ) -> Data? {
        
        let mutableData = NSMutableData()
        let utType = getUTType(for: format)
        
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            utType.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        
        var options: [CFString: Any] = [:]
        
        switch format {
        case .jpeg:
            options[kCGImageDestinationLossyCompressionQuality] = quality
            
        case .png:
            // PNG는 무손실 압축이므로 품질 설정 없음
            break
            
        case .gif:
            // GIF 인코딩 시에는 품질 설정 없음 (무손실)
            break
            
        case .webp:
            // WebP는 JPEG로 변환되므로 JPEG 품질 적용
            options[kCGImageDestinationLossyCompressionQuality] = quality
            
        default:
            options[kCGImageDestinationLossyCompressionQuality] = quality
        }
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return mutableData as Data
    }
    
    // MARK: - UTType 결정 (포맷 보존 우선)
    private func getUTType(for format: ImageFormat) -> UTType {
        switch format {
        case .jpeg:
            return UTType.jpeg
        case .png:
            return UTType.png
        case .gif:
            // GIF 압축 실패시 JPEG 변환에서만 호출되므로 JPEG 반환
            return UTType.jpeg
        case .webp:
            // iOS WebP 출력 제한으로 JPEG 변환
            return UTType.jpeg
        default:
            return UTType.jpeg
        }
    }
    
    // MARK: - 포맷 감지 (WebP 지원 추가)
    private func detectFormat(from data: Data) -> ImageFormat {
        guard data.count > 12 else { return .jpeg }
        
        let bytes = data.prefix(12)
        
        // JPEG 시그니처: FF D8 FF
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return .jpeg
        }
        // PNG 시그니처: 89 50 4E 47
        else if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return .png
        }
        // GIF 시그니처: 47 49 46
        else if bytes.starts(with: [0x47, 0x49, 0x46]) {
            return .gif
        }
        // WebP 시그니처: RIFF....WEBP (8-11바이트에 WEBP)
        else if bytes.count >= 12 &&
                bytes.starts(with: [0x52, 0x49, 0x46, 0x46]) && // "RIFF"
                bytes[8...11] == Data([0x57, 0x45, 0x42, 0x50]) { // "WEBP"
            return .webp
        }
        
        return .jpeg // 기본값
    }
    
    // MARK: - 헬퍼 메서드들
    private func convertToJPEG(
        _ data: Data,
        targetSize: CGSize?,
        quality: CGFloat
    ) -> Data? {
        
        guard let imageSource = createImageSource(from: data) else { return nil }
        
        let cgImage: CGImage?
        
        if let targetSize = targetSize {
            let maxPixelSize = max(targetSize.width, targetSize.height)
            let options = createDownsampleOptions(maxPixelSize: maxPixelSize)
            cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)
        } else {
            cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        }
        
        guard let image = cgImage else { return nil }
        
        return encodeImage(image, format: .jpeg, quality: quality)
    }
    
    private func downsampleWithFormat(
        _ data: Data,
        targetSize: CGSize,
        format: ImageFormat,
        quality: CGFloat
    ) -> Data? {
        
        guard let imageSource = createImageSource(from: data) else { return nil }
        
        let maxPixelSize = max(targetSize.width, targetSize.height)
        let downsampleOptions = createDownsampleOptions(maxPixelSize: maxPixelSize)
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
            imageSource, 0, downsampleOptions
        ) else {
            return nil
        }
        
        return encodeImage(downsampledImage, format: format, quality: quality)
    }
    
    // MARK: - GIF 압축 (기존 로직)
    private func compressGIFByReducingFrames(_ data: Data, maxSizeKB: Int) -> Data? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(imageSource)
        guard frameCount > 2 else { return data }
        
        let targetBytes = maxSizeKB * 1024
        let compressionRatio = Double(targetBytes) / Double(data.count)
        
        let keepRatio = max(0.5, min(1.0, compressionRatio * 1.2))
        let framesToKeep = max(2, Int(Double(frameCount) * keepRatio))
        let frameSkip = max(1, frameCount / framesToKeep)
        
        logProcessing("GIF압축 원본 프레임: \(frameCount)개 → 유지 프레임: \(framesToKeep)개 (간격: \(frameSkip))")
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.gif.identifier as CFString,
            framesToKeep,
            nil
        ) else {
            return nil
        }
        
        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)
        
        var addedFrames = 0
        for i in stride(from: 0, to: frameCount, by: frameSkip) {
            guard addedFrames < framesToKeep,
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else {
                continue
            }
            
            let frameProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as? [String: Any]
            let gifFrameProperties = frameProperties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
            let delayTime = gifFrameProperties?[kCGImagePropertyGIFDelayTime as String] as? Double ?? 0.1
            
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
        logProcessing("GIF압축 완료: \(data.count / 1024)KB → \(compressedSize / 1024)KB (\(Int((1.0 - Double(compressedSize) / Double(data.count)) * 100))% 절약)")
        
        return mutableData as Data
    }
}
