//
//  FileDisplayView.swift
//  PickPle
//
//  Created by 정인선 on 7/30/25.
//

import SwiftUI

struct FileDisplayView: View {
    let message: ChatMessage
    let showTime: Bool
    
    private var hasPDF: Bool {
        message.files.contains { $0.lowercased().hasSuffix(".pdf") }
    }
    
    private var imagePaths: [String] {
        message.files.filter { path in
            let ext = path.lowercased()
            return ext.hasSuffix(".jpg") || ext.hasSuffix(".jpeg") ||
                   ext.hasSuffix(".png") || ext.hasSuffix(".gif")
        }
    }
    
    var body: some View {
        HStack {
            if message.sender.userId == UserDefaultsManager.userId {
                // 내가 보낸 파일 - 오른쪽 정렬
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 8) {
                    Group {
                        if hasPDF {
                            // PDF가 있으면 모든 파일을 리스트로 표시
                            AllFilesListView(filePaths: message.files)
                        } else {
                            // PDF가 없으면 이미지만 그리드로 표시
                            if !imagePaths.isEmpty {
                                ImageGridView(imagePaths: imagePaths)
                            }
                        }
                    }
                    .padding(8)
                    .background(.gray30)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    if showTime {
                        Text(message.createdAt)
                            .font(.pretendard(.caption2))
                            .foregroundStyle(.gray75)
                            .padding(.trailing, 4)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        if hasPDF {
                            // PDF가 있으면 모든 파일을 리스트로 표시
                            AllFilesListView(filePaths: message.files)
                        } else {
                            // PDF가 없으면 이미지만 그리드로 표시
                            if !imagePaths.isEmpty {
                                ImageGridView(imagePaths: imagePaths)
                            }
                        }
                    }
                    .padding(8)
                    .background(.gray30)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    if showTime {
                        Text(message.createdAt)
                            .font(.pretendard(.caption2))
                            .foregroundStyle(.gray75)
                            .padding(.leading, 4)
                    }
                }
                
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - 이미지 그리드 뷰
struct ImageGridView: View {
    let imagePaths: [String]
    
    var body: some View {
        switch imagePaths.count {
        case 1:
            SingleImageView(imagePaths: imagePaths)
        case 2:
            TwoImagesView(imagePaths: imagePaths)
        case 3:
            ThreeImagesView(imagePaths: imagePaths)
        case 4:
            FourImagesView(imagePaths: imagePaths)
        case 5:
            FiveImagesView(imagePaths: imagePaths)
        default:
            EmptyView()
        }
    }
}

// MARK: - 개별 레이아웃 뷰들
struct SingleImageView: View {
    let imagePaths: [String]
    
    var body: some View {
        if let path = imagePaths.first {
            CachedImageView(
                imagePath: path, 
                size: CGSize(width: 250, height: 200),
                imageUrls: imagePaths,
                currentIndex: 0
            )
            .frame(maxWidth: 250, maxHeight: 200)
            .clipped()
            .cornerRadius(4)
        }
    }
}

struct TwoImagesView: View {
    let imagePaths: [String]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(imagePaths.prefix(2).enumerated()), id: \.element) { index, path in
                CachedImageView(
                    imagePath: path, 
                    size: CGSize(width: 123, height: 123),
                    imageUrls: imagePaths,
                    currentIndex: index
                )
                .frame(width: 123, height: 123)
                .clipped()
                .cornerRadius(4)
            }
        }
    }
}

struct ThreeImagesView: View {
    let imagePaths: [String]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(imagePaths.prefix(3).enumerated()), id: \.element) { index, path in
                CachedImageView(
                    imagePath: path, 
                    size: CGSize(width: 80.5, height: 80.5),
                    imageUrls: imagePaths,
                    currentIndex: index
                )
                .frame(width: 80.5, height: 80.5)
                .clipped()
                .cornerRadius(4)
            }
        }
    }
}

struct FourImagesView: View {
    let imagePaths: [String]
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(Array(imagePaths.prefix(2).enumerated()), id: \.element) { index, path in
                    CachedImageView(
                        imagePath: path, 
                        size: CGSize(width: 123, height: 123),
                        imageUrls: imagePaths,
                        currentIndex: index
                    )
                    .frame(width: 123, height: 123)
                    .clipped()
                    .cornerRadius(4)
                }
            }
            
            HStack(spacing: 4) {
                ForEach(Array(imagePaths.suffix(2).enumerated()), id: \.element) { index, path in
                    CachedImageView(
                        imagePath: path, 
                        size: CGSize(width: 123, height: 123),
                        imageUrls: imagePaths,
                        currentIndex: index + 2  // suffix 시작 인덱스 조정
                    )
                    .frame(width: 123, height: 123)
                    .clipped()
                    .cornerRadius(4)
                }
            }
        }
    }
}

struct FiveImagesView: View {
    let imagePaths: [String]
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(Array(imagePaths.prefix(3).enumerated()), id: \.element) { index, path in
                    CachedImageView(
                        imagePath: path, 
                        size: CGSize(width: 80.5, height: 80.5),
                        imageUrls: imagePaths,
                        currentIndex: index
                    )
                    .frame(width: 80.5, height: 80.5)
                    .clipped()
                    .cornerRadius(4)
                }
            }
            
            HStack(spacing: 4) {
                ForEach(Array(imagePaths.suffix(2).enumerated()), id: \.element) { index, path in
                    CachedImageView(
                        imagePath: path, 
                        size: CGSize(width: 123, height: 80.5),
                        imageUrls: imagePaths,
                        currentIndex: index + 3  // suffix 시작 인덱스 조정
                    )
                    .frame(width: 123, height: 80.5)
                    .clipped()
                    .cornerRadius(4)
                }
            }
        }
    }
}

// MARK: - 모든 파일 리스트 뷰
struct AllFilesListView: View {
    let filePaths: [String]
    
    private var imagePaths: [String] {
        filePaths.filter { path in
            let ext = path.lowercased()
            return ext.hasSuffix(".jpg") || ext.hasSuffix(".jpeg") ||
                   ext.hasSuffix(".png") || ext.hasSuffix(".gif") || ext.hasSuffix(".webp")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(filePaths, id: \.self) { path in
                FileRowView(filePath: path, allImagePaths: imagePaths)
            }
        }
        .frame(width: 250)
    }
}

// MARK: - 파일 행 뷰
struct FileRowView: View {
    let filePath: String
    let allImagePaths: [String]
    
    private var fileName: String {
        URL(string: filePath)?.lastPathComponent ?? filePath
    }
    
    private var isImage: Bool {
        let ext = filePath.lowercased()
        return ext.hasSuffix(".jpg") || ext.hasSuffix(".jpeg") ||
               ext.hasSuffix(".png") || ext.hasSuffix(".gif") || ext.hasSuffix(".webp")
    }
    
    private var currentImageIndex: Int {
        allImagePaths.firstIndex(of: filePath) ?? 0
    }
    
    private var isPDF: Bool {
        filePath.lowercased().hasSuffix(".pdf")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 아이콘 또는 썸네일
            if isImage {
                CachedImageView(
                    imagePath: filePath, 
                    size: CGSize(width: 40, height: 40),
                    imageUrls: allImagePaths,
                    currentIndex: currentImageIndex
                )
                .frame(width: 40, height: 40)
                .clipped()
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPDF ? .red : .gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: isPDF ? "doc.fill" : "doc")
                            .foregroundStyle(.white)
                            .font(.system(size: 16, weight: .medium))
                    )
            }
            
            // 파일명
            Text(fileName)
                .font(.system(size: 14))
                .lineLimit(1)
             
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
