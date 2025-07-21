
//
//  MultipartFile.swift
//  PickPle
//
//  Created by 정인선 on 7/29/25.
//

import Foundation

enum MediaFormat {
    case jpeg, png, gif, webp
    case pdf
    case mp4, mov, avi, mkv, wmv
    
    var mimeType: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .png: return "image/png"
        case .gif: return "image/gif"
        case .webp: return "image/webp"
        case .pdf: return "application/pdf"
        case .mp4: return "video/mp4"
        case .mov: return "video/quicktime"
        case .avi: return "video/x-msvideo"
        case .mkv: return "video/x-matroska"
        case .wmv: return "video/x-ms-wmv"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .gif: return "gif"
        case .webp: return "webp"
        case .pdf: return "pdf"
        case .mp4: return "mp4"
        case .mov: return "mov"
        case .avi: return "avi"
        case .mkv: return "mkv"
        case .wmv: return "wmv"
        }
    }
    
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
    
    // 파일 확장자로부터 MediaFormat 추론 (하위 호환성용)
    static func from(fileExtension: String) -> MediaFormat? {
        let ext = fileExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return .jpeg
        case "png": return .png
        case "gif": return .gif
        case "webp": return .webp
        case "pdf": return .pdf
        case "mp4": return .mp4
        case "mov": return .mov
        case "avi": return .avi
        case "mkv": return .mkv
        case "wmv": return .wmv
        default: return nil
        }
    }
    
    // MIME 타입으로부터 MediaFormat 추론 (하위 호환성용)
    static func from(mimeType: String) -> MediaFormat? {
        switch mimeType.lowercased() {
        case "image/jpeg": return .jpeg
        case "image/png": return .png
        case "image/gif": return .gif
        case "image/webp": return .webp
        case "application/pdf": return .pdf
        case "video/mp4": return .mp4
        case "video/quicktime": return .mov
        case "video/x-msvideo": return .avi
        case "video/x-matroska": return .mkv
        case "video/x-ms-wmv": return .wmv
        default: return nil
        }
    }
    
    // MARK: - 파일 시그니처 기반 포맷 감지 (메인 메서드)
    static func detectFromSignature(_ data: Data) -> MediaFormat? {
        guard data.count >= 16 else {
            print("⚠️ 파일 크기가 너무 작습니다 (16바이트 미만)")
            return nil
        }
        
        let bytes = data.prefix(16)  // 처음 16바이트 확인
        
        // JPEG 시그니처: FF D8 FF
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            print("✅ JPEG 시그니처 감지")
            return .jpeg
        }
        
        // PNG 시그니처: 89 50 4E 47 0D 0A 1A 0A
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            print("✅ PNG 시그니처 감지")
            return .png
        }
        
        // GIF 시그니처: 47 49 46 38 37 61 (GIF87a) 또는 47 49 46 38 39 61 (GIF89a)
        if bytes.starts(with: [0x47, 0x49, 0x46, 0x38]) &&
           (bytes.count >= 6 && (bytes[5] == 0x61)) {  // 'a'
            print("✅ GIF 시그니처 감지")
            return .gif
        }
        
        // WebP 시그니처: 52 49 46 46 [4바이트 크기] 57 45 42 50
        if bytes.starts(with: [0x52, 0x49, 0x46, 0x46]) && // "RIFF"
           data.count >= 12 {
            let webpMarker = data.subdata(in: 8..<12)
            if webpMarker.elementsEqual([0x57, 0x45, 0x42, 0x50]) {  // "WEBP"
                print("✅ WebP 시그니처 감지")
                return .webp
            }
        }
        
        // PDF 시그니처: 25 50 44 46 (%PDF)
        if bytes.starts(with: [0x25, 0x50, 0x44, 0x46]) {
            print("✅ PDF 시그니처 감지")
            return .pdf
        }
        
        // MP4/QuickTime 시그니처: [4바이트 크기] 66 74 79 70 (ftyp)
        if data.count >= 12 {
            let ftypMarker = data.subdata(in: 4..<8)
            if ftypMarker.elementsEqual([0x66, 0x74, 0x79, 0x70]) {  // "ftyp"
                // ftyp 다음 4바이트로 구체적인 포맷 구분
                let brandMarker = data.subdata(in: 8..<12)
                let brandString = String(data: brandMarker, encoding: .ascii) ?? ""
                
                if brandString.hasPrefix("isom") || brandString.hasPrefix("mp41") || brandString.hasPrefix("mp42") {
                    print("✅ MP4 시그니처 감지 (브랜드: \(brandString))")
                    return .mp4
                } else if brandString.hasPrefix("qt") {
                    print("✅ QuickTime MOV 시그니처 감지")
                    return .mov
                } else {
                    print("✅ MP4 계열 시그니처 감지 (기본 MP4 처리)")
                    return .mp4  // 기본적으로 MP4로 처리
                }
            }
        }
        
        // AVI 시그니처: 52 49 46 46 [4바이트 크기] 41 56 49 20
        if bytes.starts(with: [0x52, 0x49, 0x46, 0x46]) && // "RIFF"
           data.count >= 12 {
            let aviMarker = data.subdata(in: 8..<12)
            if aviMarker.elementsEqual([0x41, 0x56, 0x49, 0x20]) {  // "AVI "
                print("✅ AVI 시그니처 감지")
                return .avi
            }
        }
        
        // MKV/WebM 시그니처: 1A 45 DF A3 (EBML 헤더)
        if bytes.starts(with: [0x1A, 0x45, 0xDF, 0xA3]) {
            print("✅ MKV/Matroska 시그니처 감지")
            return .mkv
        }
        
        // WMV/ASF 시그니처: 30 26 B2 75 8E 66 CF 11 A6 D9 00 AA 00 62 CE 6C
        let wmvSignature: [UInt8] = [0x30, 0x26, 0xB2, 0x75, 0x8E, 0x66, 0xCF, 0x11, 0xA6, 0xD9, 0x00, 0xAA, 0x00, 0x62, 0xCE, 0x6C]
        if bytes.starts(with: wmvSignature) {
            print("✅ WMV 시그니처 감지")
            return .wmv
        }
        
        print("❌ 지원하지 않는 파일 시그니처")
        return nil
    }
}

// 하위 호환성을 위한 별칭
typealias ImageFormat = MediaFormat

struct MultipartFile {
    let data: Data
    let fieldName: String
    let fileName: String
    let mimeType: String
    let detectedFormat: MediaFormat  // 실제 감지된 포맷 정보 추가
}

extension MultipartFile {
    // MARK: - 파일 시그니처 기반 미디어 파일 생성 (메인 메서드)
    static func from(data: Data, originalFileName: String, fieldName: String = "files", maxSizeKB: Int = 5120) -> MultipartFile? {
        
        // 1. 파일 시그니처를 통한 실제 포맷 감지
        guard let detectedFormat = MediaFormat.detectFromSignature(data) else {
            print("❌ 지원하지 않는 파일 포맷입니다")
            return nil
        }
        
        // 2. 원본 파일명에서 확장자 제거 (확장자는 무시하고 파일명만 사용)
        let fileURL = URL(string: originalFileName) ?? URL(fileURLWithPath: originalFileName)
        let baseName = fileURL.deletingPathExtension().lastPathComponent.isEmpty ?
                      fileURL.lastPathComponent : fileURL.deletingPathExtension().lastPathComponent
        
        // 3. 감지된 포맷에 맞는 올바른 확장자로 파일명 생성
        let correctedFileName = "\(baseName).\(detectedFormat.fileExtension)"
        
        print("📁 파일명 처리: \(originalFileName) → \(correctedFileName)")
        print("🔍 감지된 포맷: \(detectedFormat)")
        
        // 4. 파일 타입별로 적절한 처리 수행
        if detectedFormat.isImage {
            return processImageData(
                data: data,
                baseName: baseName,
                detectedFormat: detectedFormat,
                fieldName: fieldName,
                maxSizeKB: maxSizeKB
            )
        }
        else if detectedFormat.isVideo {
            return processVideoData(
                data,
                baseName: baseName,
                mediaFormat: detectedFormat,
                fieldName: fieldName,
                targetSizeMB: Double(maxSizeKB) / 1024.0
            )
        }
        else {
            // PDF 등 기타 파일은 원본 데이터 그대로 사용
            return MultipartFile(
                data: data,
                fieldName: fieldName,
                fileName: correctedFileName,
                mimeType: detectedFormat.mimeType,
                detectedFormat: detectedFormat
            )
        }
    }
    
    // MARK: - 이미지 처리 헬퍼 메서드
    /// 이미지 데이터를 압축 처리하는 헬퍼 메서드
    private static func processImageData(
        data: Data,
        baseName: String,
        detectedFormat: MediaFormat,
        fieldName: String,
        maxSizeKB: Int
    ) -> MultipartFile {
        guard let result = ImageProcessingManager.shared.prepareImageDataForUpload(
            data,
            format: detectedFormat,
            maxSizeKB: maxSizeKB
        ) else {
            // 압축 실패시 원본 데이터 사용
            let fileName = "\(baseName).\(detectedFormat.fileExtension)"
            return MultipartFile(
                data: data,
                fieldName: fieldName,
                fileName: fileName,
                mimeType: detectedFormat.mimeType,
                detectedFormat: detectedFormat
            )
        }
        
        // 압축 결과에 따른 최종 파일명 생성
        let finalFileName = "\(baseName).\(result.actualFormat.fileExtension)"
        
        print("🖼️ 이미지 압축 완료: \(detectedFormat.fileExtension) → \(result.actualFormat.fileExtension)")
        
        return MultipartFile(
            data: result.data,
            fieldName: fieldName,
            fileName: finalFileName,
            mimeType: result.actualFormat.mimeType,
            detectedFormat: result.actualFormat  // 실제 처리된 포맷으로 업데이트
        )
    }
    
    // MARK: - 비디오 처리 헬퍼 메서드
    private static func processVideoData(
        _ data: Data,
        baseName: String,
        mediaFormat: MediaFormat,
        fieldName: String,
        targetSizeMB: Double
    ) -> MultipartFile? {
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let inputURL = tempDirectory.appendingPathComponent("temp_input_\(UUID().uuidString).\(mediaFormat.fileExtension)")
        
        do {
            // 1. 임시 파일에 원본 데이터 저장
            try data.write(to: inputURL)
            print("📹 비디오 임시 파일 생성: \(inputURL.lastPathComponent)")
            
            // 2. VideoProcessingManager를 사용하여 비동기 압축
            let semaphore = DispatchSemaphore(value: 0)
            var compressionResult: (success: Bool, outputURL: URL?, error: Error?) = (false, nil, nil)
            
            Task {
                do {
                    let compressedResult = try await VideoProcessingManager.shared.compressVideoTo5MB(
                        inputURL: inputURL,
                        targetSizeMB: Float(targetSizeMB)
                    )
                    compressionResult = (true, compressedResult.url, nil)
                } catch {
                    compressionResult = (false, nil, error)
                }
                semaphore.signal()
            }
            
            // 3. 압축 완료 대기 (최대 30초)
            let result = semaphore.wait(timeout: .now() + 30)
            
            guard result == .success,
                  compressionResult.success,
                  let compressedURL = compressionResult.outputURL else {
                
                print("❌ 비디오 압축 실패: \(compressionResult.error?.localizedDescription ?? "Unknown error")")
                
                // 압축 실패시 크기 체크 후 원본 사용 또는 nil 반환
                let maxBytes = Int(targetSizeMB * 1024 * 1024)
                if data.count > maxBytes {
                    print("❌ 원본 비디오 크기 초과: \(data.count / 1024 / 1024)MB > \(Int(targetSizeMB))MB")
                    return nil
                }
                
                return MultipartFile(
                    data: data,
                    fieldName: fieldName,
                    fileName: "\(baseName).\(mediaFormat.fileExtension)",
                    mimeType: mediaFormat.mimeType,
                    detectedFormat: mediaFormat
                )
            }
            
            // 4. 압축된 파일 데이터 읽기
            let compressedData = try Data(contentsOf: compressedURL)
            print("📹 비디오 압축 완료: \(data.count / 1024)KB → \(compressedData.count / 1024)KB")
            
            // 5. 임시 파일 정리
            try? FileManager.default.removeItem(at: inputURL)
            try? FileManager.default.removeItem(at: compressedURL)
            
            // 6. 압축된 데이터로 MultipartFile 생성 (항상 MP4로 출력)
            return MultipartFile(
                data: compressedData,
                fieldName: fieldName,
                fileName: "\(baseName).mp4",
                mimeType: "video/mp4",
                detectedFormat: .mp4  // 압축 후에는 항상 MP4
            )
            
        } catch {
            print("❌ 비디오 처리 중 오류: \(error.localizedDescription)")
            
            // 오류시 임시 파일 정리
            try? FileManager.default.removeItem(at: inputURL)
            
            // 오류시 원본 데이터로 MultipartFile 생성
            return MultipartFile(
                data: data,
                fieldName: fieldName,
                fileName: "\(baseName).\(mediaFormat.fileExtension)",
                mimeType: mediaFormat.mimeType,
                detectedFormat: mediaFormat
            )
        }
    }
    
    // MARK: - 유틸리티 메서드들
    
    /// 파일 데이터가 지원되는 형식인지 확인 (시그니처 기반)
    /// - Parameter data: 확인할 파일 데이터
    /// - Returns: 지원 여부 (true/false)
    static func isSupported(data: Data) -> Bool {
        return MediaFormat.detectFromSignature(data) != nil
    }
    
    /// 파일명 기반 지원 여부 확인 (하위 호환성용)
    /// - Parameter fileName: 확인할 파일명
    /// - Returns: 지원 여부 (true/false)
    static func isSupported(fileName: String) -> Bool {
        let fileURL = URL(string: fileName) ?? URL(fileURLWithPath: fileName)
        let fileExtension = fileURL.pathExtension
        return MediaFormat.from(fileExtension: fileExtension) != nil
    }
    
    /// 현재 지원되는 모든 파일 확장자 목록 반환
    static var supportedExtensions: [String] {
        return ["jpg", "jpeg", "png", "gif", "webp", "pdf", "mp4", "mov", "avi", "mkv", "wmv"]
    }
}
