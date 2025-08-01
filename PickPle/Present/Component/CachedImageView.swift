//
//  CachedImageView.swift
//  PickPle
//
//  Created by 정인선 on 5/23/25.
//

import SwiftUI
import UIKit

struct CachedImageView: View {
    let imagePath: String
    let size: CGSize
    let contentMode: ContentMode
    let showRetry: Bool
    let maxRetries: Int
    let isFullSize: Bool  // 2단계 캐싱 지원
    let onTap: (() -> Void)?  // 탭 액션 (동영상 재생용)
    let showVideoOverlay: Bool  // 비디오 재생 버튼 표시 여부
    
    // ImageViewer 지원
    let enableImageViewer: Bool
    let imageUrls: [String]
    let currentIndex: Int
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var retryCount = 0
    @State private var isAnimatedGIF = false
    @State private var isVideo = false
    @State private var showImageViewer = false
    
    // 기존 초기화 메서드 (하위 호환성 유지)
    init(
        imagePath: String,
        size: CGSize,
        contentMode: ContentMode = .fill,
        showRetry: Bool = true,
        maxRetries: Int = 2,
        isFullSize: Bool = false,  // 기본값: 썸네일 사용
        onTap: (() -> Void)? = nil,  // 탭 액션
        showVideoOverlay: Bool = true  // 기본값: 비디오 오버레이 표시
    ) {
        self.imagePath = imagePath
        self.size = size
        self.contentMode = contentMode
        self.showRetry = showRetry
        self.maxRetries = maxRetries
        self.isFullSize = isFullSize
        self.onTap = onTap
        self.showVideoOverlay = showVideoOverlay
        
        // ImageViewer 비활성화
        self.enableImageViewer = false
        self.imageUrls = []
        self.currentIndex = 0
    }
    
    // ImageViewer 지원 초기화 메서드
    init(
        imagePath: String,
        size: CGSize,
        contentMode: ContentMode = .fill,
        showRetry: Bool = true,
        maxRetries: Int = 2,
        isFullSize: Bool = false,
        imageUrls: [String],
        currentIndex: Int = 0,
        showVideoOverlay: Bool = true  // 기본값: 비디오 오버레이 표시
    ) {
        self.imagePath = imagePath
        self.size = size
        self.contentMode = contentMode
        self.showRetry = showRetry
        self.maxRetries = maxRetries
        self.isFullSize = isFullSize
        self.onTap = nil  // ImageViewer 사용 시 onTap 무시
        self.showVideoOverlay = showVideoOverlay
        
        // ImageViewer 활성화
        self.enableImageViewer = true
        self.imageUrls = imageUrls
        self.currentIndex = currentIndex
    }
    
    var body: some View {
        // ✅ 항상 고정된 크기의 Rectangle 배경으로 레이아웃 안정성 보장
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size.width, height: size.height)
            .overlay(
                ZStack {
                    if let image = image {
                        if isAnimatedGIF {
                            // GIF 애니메이션은 UIImageView 래핑
                            AnimatedImageWrapper(image: image)
                                .frame(width: size.width, height: size.height)
                                .clipped()
                        } else {
                            // 일반 이미지/동영상 썸네일
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: contentMode)
                                .frame(width: size.width, height: size.height)
                                .clipped()
                        }
                        
                        // 동영상일 때 플레이 버튼 오버레이 (showVideoOverlay가 true일 때만)
                        if isVideo && showVideoOverlay {
                            VideoPlayOverlay(size: size)
                        }
                    } else if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if showRetry && retryCount > 0 && retryCount < maxRetries {
                        // 재시도
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if retryCount >= maxRetries {
                        // 모든 재시도 실패
                        Image(systemName: "photo")
                            .font(.system(size: min(size.width, size.height) * 0.2))
                            .foregroundStyle(.gray)
                    } else {
                        // 초기 상태
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            )
            .background(Color.clear)  // 탭 영역 확보를 위한 투명 배경
            .conditionalTapGesture(
                isVideo: isVideo,
                onTap: onTap,
                enableImageViewer: enableImageViewer,
                onImageViewerTap: { showImageViewer = true }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        if enableImageViewer {
                            print("🖼️ simultaneousGesture 탭 감지!")
                            showImageViewer = true
                        }
                    }
            )
        .onAppear {
            loadImageTraditional()
        }
        .onChange(of: imagePath) { _ in
            loadImageTraditional()
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            if enableImageViewer {
                ImageViewer(imageUrls: imageUrls, initialIndex: currentIndex)
            }
        }
    }
    
    // ✅ 데이터 기반 정확한 GIF 판별로 변경
    private func loadImageTraditional() {
        // 이미 로드된 이미지가 있으면 스킵
        guard image == nil else { return }
        
        // 이미 로딩 중이면 스킵
        guard !isLoading else { return }
        
        print("🖼️ [CachedImageView] 데이터 기반 이미지 로드 시작: \(imagePath)")
        
        isAnimatedGIF = false
        isVideo = isVideoFile(imagePath)
        isLoading = true
        retryCount = 0
        
        // 🎯 새로운 방식: 네트워크에서 받은 실제 데이터로 판별
        loadImageWithDataAnalysis()
    }
    
    // 데이터 기반 정확한 이미지 로드 - 통합 캐시 매니저 사용
    private func loadImageWithDataAnalysis() {
        Task {
            let result = await UnifiedMediaCacheManager.shared.loadImage(
                from: imagePath,
                size: size,
                isFullSize: isFullSize
            )
            
            await MainActor.run {
                if let result {
                    print("✅ [CachedImageView] 통합 캐시로 데이터 로드 성공: \(self.imagePath)")
                    print("🔍 [CachedImageView] 감지된 포맷: \(result.detectedFormat)")
                    print("🎬 [CachedImageView] 애니메이션 GIF: \(result.isAnimatedGIF)")
                    
                    self.image = result.image
                    self.isAnimatedGIF = result.isAnimatedGIF
                    self.isLoading = false
                    self.retryCount = 0
                } else {
                    print("❌ [CachedImageView] 통합 캐시로 데이터 로드 실패: \(self.imagePath)")
                    self.handleLoadFailure()
                }
            }
        }
    }
    
    private func handleLoadFailure() {
        if retryCount < maxRetries {
            retryCount += 1
            print("🔄 [CachedImageView] 재시도 \(retryCount)/\(maxRetries): \(imagePath)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadImageWithDataAnalysis()
            }
        } else {
            print("🚫 [CachedImageView] 모든 재시도 실패: \(imagePath)")
            isLoading = false
        }
    }
    
    // 동영상 파일 확장자 감지
    private func isVideoFile(_ path: String) -> Bool {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "wmv"]
        let pathLowercase = path.lowercased()
        return videoExtensions.contains { pathLowercase.hasSuffix(".\($0)") }
    }
}

// MARK: - Video Play Overlay
struct VideoPlayOverlay: View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            // 반투명 배경
            Color.black.opacity(0.3)
                .frame(width: size.width, height: size.height)
            
            // 플레이 버튼
            Button(action: {}) {
                ZStack {
                    // 원형 배경
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: min(size.width, size.height) * 0.3, 
                               height: min(size.width, size.height) * 0.3)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    
                    // 플레이 아이콘
                    Image(systemName: "play.fill")
                        .font(.system(size: min(size.width, size.height) * 0.12, weight: .medium))
                        .foregroundColor(.black.opacity(0.8))
                        .offset(x: 2) // 플레이 아이콘을 약간 오른쪽으로 이동하여 중앙 정렬
                }
            }
            .disabled(true) // 탭 이벤트는 상위에서 처리
        }
    }
}

// MARK: - UIImageView Wrapper for GIF Animation
struct AnimatedImageWrapper: UIViewRepresentable {
    let image: UIImage
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        // 이미지가 변경된 경우에만 업데이트
        if uiView.image != image {
            print("🎬 [AnimatedImageWrapper] 이미지 업데이트 및 애니메이션 시작")
            uiView.image = image
            
            // 애니메이션 이미지인 경우 애니메이션 시작
            if image.images != nil {
                uiView.startAnimating()
                print("✅ [AnimatedImageWrapper] GIF 애니메이션 시작됨 - 프레임 수: \(image.images?.count ?? 0)")
            }
        } else {
            // 이미지는 같지만 애니메이션이 중단되었다면 재시작
            if image.images != nil && !uiView.isAnimating {
                print("🔄 [AnimatedImageWrapper] 애니메이션 재시작")
                uiView.startAnimating()
            }
        }
    }
}

// MARK: - View Extension for Conditional Tap Gesture
extension View {
    @ViewBuilder
    func conditionalTapGesture(
        isVideo: Bool, 
        onTap: (() -> Void)?,
        enableImageViewer: Bool = false,
        onImageViewerTap: (() -> Void)? = nil
    ) -> some View {
        if isVideo, let onTap = onTap {
            // 동영상이고 onTap 콜백이 있을 때만 탭 제스처 추가
            self.onTapGesture {
                onTap()
            }
        } else if enableImageViewer, let onImageViewerTap = onImageViewerTap {
            // ImageViewer가 활성화된 경우 ImageViewer 탭 제스처 추가
            self.onTapGesture {
                onImageViewerTap()
            }
        } else {
            // 탭 제스처 없음 - NavigationLink가 정상 동작
            self
        }
    }
}
