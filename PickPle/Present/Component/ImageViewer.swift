//
//  ImageViewer.swift
//  PickPle
//
//  Created by 정인선 on 8/31/25.
//

import SwiftUI
import AVKit

// MARK: - ImageViewer
struct ImageViewer: View {
    let imageUrls: [String]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var dragVelocity: CGSize = .zero
    
    init(imageUrls: [String], initialIndex: Int = 0) {
        self.imageUrls = imageUrls
        self.initialIndex = max(0, min(initialIndex, imageUrls.count - 1))
        self._currentIndex = State(initialValue: max(0, min(initialIndex, imageUrls.count - 1)))
    }
    
    var body: some View {
        ZStack {
            // 동적 배경: 드래그할수록 투명해짐
            Color.black
                .opacity(isDragging ? max(0.1, Double(1 - abs(dragOffset.height) / 300)) : 1)
                .ignoresSafeArea()
                .animation(.easeOut(duration: isDragging ? 0.1 : 0.3), value: isDragging)
                .allowsHitTesting(!isDragging) // 드래그 중이 아닐 때만 터치 허용
                .onTapGesture {
                    dismiss()
                }
            
            VStack {
                // 상단 헤더
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(imageUrls.count)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding()
                
                // 메인 미디어 영역
                GeometryReader { geometry in
                    TabView(selection: $currentIndex) {
                        ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, url in
                            MediaViewerItem(
                                mediaUrl: url,
                                size: CGSize(width: geometry.size.width, height: geometry.size.height)
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                
                Spacer()
            }
        }
        .offset(y: dragOffset.height)
        .scaleEffect(1 - abs(dragOffset.height) / 1000)
        .opacity(Double(1 - abs(dragOffset.height) / 500))
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    // 세로 드래그만 인식 (상하 스와이프)
                    if abs(value.translation.height) > abs(value.translation.width) {
                        isDragging = true
                        dragOffset = CGSize(width: 0, height: value.translation.height)
                        dragVelocity = value.velocity
                    }
                }
                .onEnded { value in
                    // 세로 드래그만 처리
                    if abs(value.translation.height) > abs(value.translation.width) {
                        let dismissThreshold: CGFloat = 150
                        let velocityThreshold: CGFloat = 500
                        
                        if abs(value.translation.height) > dismissThreshold || 
                           abs(dragVelocity.height) > velocityThreshold {
                            // 하단으로 스와이프하거나 빠른 속도로 드래그했을 때 dismiss
                            dismiss()
                        } else {
                            // 원래 위치로 복귀
                            withAnimation(.easeOut(duration: 0.3)) {
                                dragOffset = .zero
                                isDragging = false
                            }
                        }
                    } else {
                        // 가로 드래그는 TabView가 처리하도록 복귀
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = .zero
                            isDragging = false
                        }
                    }
                }
        )
    }
}

// MARK: - MediaViewerItem
struct MediaViewerItem: View {
    let mediaUrl: String
    let size: CGSize
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var player: AVPlayer?
    @State private var isAnimatedGIF = false
    @State private var isVideo = false
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else {
                if isVideo {
                    // 동영상 표시
                    if let player = player {
                        VideoPlayerView(player: player)
                            .frame(maxWidth: size.width, maxHeight: size.height)
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "play.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                } else {
                    // 이미지 표시 (일반 이미지 또는 GIF)
                    if let image = loadedImage {
                        if isAnimatedGIF {
                            // GIF 애니메이션
                            AnimatedImageWrapper(image: image)
                                .frame(maxWidth: size.width, maxHeight: size.height)
                                .aspectRatio(contentMode: .fit)
                        } else {
                            // 일반 이미지 (줌 가능)
                            ZoomableImageView(image: image)
                        }
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear {
            loadMedia()
        }
        .onDisappear {
            // 동영상 정리
            player?.pause()
            player = nil
        }
    }
    
    private func loadMedia() {
        Task {
            await loadMediaContent()
        }
    }
    
    @MainActor
    private func loadMediaContent() async {
        isLoading = true
        defer { isLoading = false }
        
        // UnifiedMediaCacheManager를 통해 미디어 로드
        let result = await UnifiedMediaCacheManager.shared.loadImage(
            from: mediaUrl,
            size: size,
            isFullSize: true  // 뷰어에서는 항상 full size
        )
        
        if let result = result {
            loadedImage = result.image
            isAnimatedGIF = result.isAnimatedGIF
            
            // 캐시 매니저가 감지한 포맷을 기반으로 비디오 여부 결정
            //mp4, mov, avi, mkv, wmv
            if result.detectedFormat == .mp4 ||
                result.detectedFormat == .mov ||
                result.detectedFormat == .avi ||
                result.detectedFormat == .mkv ||
                result.detectedFormat == .wmv{
                isVideo = true
                // 동영상인 경우 AVPlayer 설정 (상대 경로를 절대 URL로 변환)
                let fullURL = mediaUrl.hasPrefix("http") ? mediaUrl : APIURL.PICKUP + "/v1\(mediaUrl)"
                if let url = URL(string: fullURL) {
                    // 인증 토큰을 비동기로 가져와서 AVPlayer 설정
                    await setupPlayerWithAuth(url: url)
                } else {
                    print("❌ [ImageViewer] URL 생성 실패: \(fullURL)")
                }
            } else {
                isVideo = false
            }
        } else {
            // 캐시 매니저로 로드 실패한 경우, URL 기반으로 동영상 여부 추정
            let lowercased = mediaUrl.lowercased()
            if lowercased.contains("mp4") || lowercased.contains("mov") || 
               lowercased.contains("avi") || lowercased.contains("mkv") ||
               lowercased.contains("wmv") || lowercased.contains("video") {
                isVideo = true
                // 상대 경로를 절대 URL로 변환
                let fullURL = mediaUrl.hasPrefix("http") ? mediaUrl : APIURL.PICKUP + "/v1\(mediaUrl)"
                if let url = URL(string: fullURL) {
                    // 폴백에서도 인증 토큰을 비동기로 가져와서 AVPlayer 설정
                    await setupPlayerWithAuth(url: url, isFallback: true)
                } else {
                    print("❌ [ImageViewer] 폴백 URL 생성 실패: \(fullURL)")
                }
            }
        }
    }
    
    // 인증 토큰과 함께 AVPlayer 설정
    private func setupPlayerWithAuth(url: URL, isFallback: Bool = false) async {
        await withCheckedContinuation { continuation in
            SecureTokenManager.shared.retrieveAndDecryptToken(forKey: SecureKey.ACCESS_TOKEN) { result in
                Task {
                    switch result {
                    case .success(let token):
                        // APIRequestInterceptor와 동일한 헤더 패턴 적용
                        let httpHeaders = [
                            "SesacKey": APIKEY.PICKUP,
                            "Authorization": token,
                            "User-Agent": "PickPle iOS App"
                        ]
                        
                        let asset = AVURLAsset(url: url, options: [
                            "AVURLAssetHTTPHeaderFieldsKey": httpHeaders
                        ])
                        
                        let playerItem = AVPlayerItem(asset: asset)
                        player = AVPlayer(playerItem: playerItem)
                        
                    case .failure(let error):
                        // 토큰 없이 시도 (테스트용)
                        player = AVPlayer(url: url)
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
}

// MARK: - ZoomableImageView
struct ZoomableImageView: View {
    let image: UIImage
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    // 확대/축소 제스처
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                            // 최소/최대 스케일 제한
                            if scale < 1.0 {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    scale = 1.0
                                    lastScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            } else if scale > 3.0 {
                                scale = 3.0
                                lastScale = 3.0
                            }
                        }
                        .simultaneously(with:
                            // 드래그 제스처는 확대된 상태에서만 활성화
                            scale > 1.0 ? 
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                            : nil
                        )
                )
                .onTapGesture(count: 2) {
                    // 더블 탭으로 확대/축소
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                            lastScale = 2.0
                        }
                    }
                }
        }
    }
}

// MARK: - VideoPlayerView
struct VideoPlayerView: View {
    let player: AVPlayer
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player.play()
            }
            .onDisappear {
                player.pause()
            }
    }
}
