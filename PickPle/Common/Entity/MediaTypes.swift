//
//  MediaTypes.swift
//  PickPle
//
//  Created by 정인선 on 8/30/25.
//

import UIKit
import Foundation

// MARK: - 통합 이미지 로드 결과
struct MediaLoadResult {
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
        // 바이너리 시그니처로 정확한 포맷 감지
        if data.count < 8 { return .unknown }
        
        let bytes = data.prefix(12) // MP4는 더 많은 바이트가 필요할 수 있음
        
        // 이미지 포맷 감지
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
        
        // 동영상 포맷 감지
        // MP4: "ftyp" 시그니처 (4-11 바이트 위치)
        if data.count >= 12 {
            let ftypBytes = data[4...7]
            if ftypBytes == Data([0x66, 0x74, 0x79, 0x70]) { // "ftyp"
                return .mp4
            }
        }
        
        // MOV: QuickTime "moov" 또는 "mdat"
        if data.range(of: Data([0x6D, 0x6F, 0x6F, 0x76])) != nil || // "moov"
           data.range(of: Data([0x6D, 0x64, 0x61, 0x74])) != nil {   // "mdat"
            return .mov
        }
        
        // AVI: "RIFF" + "AVI " 
        if bytes.prefix(4) == Data([0x52, 0x49, 0x46, 0x46]) && // "RIFF"
           data.count >= 11 && data[8...11] == Data([0x41, 0x56, 0x49, 0x20]) { // "AVI "
            return .avi
        }
        
        // PDF: "%PDF"
        if bytes.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]) {
            return .pdf
        }
        
        return .unknown
    }
}
