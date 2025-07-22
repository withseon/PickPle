//
//  CreatePostParam.swift
//  PickPle
//
//  Created by 정인선 on 8/27/25.
//

import Foundation
import SwiftUI

struct CreatePostParam {
    let category: String
    let title: String
    let content: String
    let storeId: String?
    let latitude: Double
    let longitude: Double
    let selectedFiles: [SelectedFile]
    let existingFileUrls: [String]?  // 수정 모드에서 기존 파일 URL들
    
    // 하위 호환성을 위한 computed property - 이미지 파일의 썸네일만 반환
    var selectedImages: [UIImage] {
        return selectedFiles.compactMap { file in
            // 이미지와 PDF 타입의 경우 저장된 image 사용
            if file.type == .image, let image = file.image {
                return image
            }
            // 비디오는 별도로 View에서 처리하므로 여기서는 제외
            return nil
        }
    }
}
