//
//  SelectedFile.swift
//  PickPle
//
//  Created by 정인선 on 8/28/25.
//

import Foundation
import UIKit

struct SelectedFile: Identifiable {
    let id: UUID
    let type: FileType
    let image: UIImage?
    let data: Data
    let fileName: String
    
    enum FileType {
        case image
        case pdf
        case video
        
        // 파일 확장자로부터 FileType 추론
        static func from(fileName: String) -> FileType? {
            let ext = URL(fileURLWithPath: fileName).pathExtension.lowercased()
            switch ext {
            case "jpg", "jpeg", "png", "gif", "webp":
                return .image
            case "pdf":
                return .pdf
            case "mp4", "mov", "avi", "mkv", "wmv":
                return .video
            default:
                return nil
            }
        }
    }
}

extension SelectedFile {
    var asMultipartFile: MultipartFile? {
        // 새로운 개선된 방식: 원본 파일명 유지
        return MultipartFile.from(
            data: self.data,
            originalFileName: self.fileName,
            fieldName: "files", // 서버 스펙에 맞게 "files"로 변경
            maxSizeKB: 5120
        )
    }
}
