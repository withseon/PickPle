//
//  CreatePostView.swift
//  PickPle
//
//  Created by 정인선 on 8/27/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import Photos

// MARK: - Movie Type for Video Handling
struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie.mov")
            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

struct CreatePostView: View {
    @StateObject private var viewModel: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Edit mode support
    private let editingPost: PostDetail?
    private let onPostUpdated: (() -> Void)?
    private var isEditMode: Bool { editingPost != nil }
    
    // Form states
    @State private var category: String = ""
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var storeId: String = ""
    
    // Media picker states
    @State private var selectedMediaItems: [PhotosPickerItem] = []
    @State private var existingFileUrls: [String] = []       // 기존 파일 URL들 (서버 요청용)
    @State private var existingFiles: [SelectedFile] = []    // 기존 파일들 (UI 표시용)
    @State private var newFiles: [SelectedFile] = []         // 새로 선택한 파일들
    @State private var existingImages: [UIImage] = []        // 기존 파일 미리보기
    @State private var newImages: [UIImage] = []             // 새 파일 미리보기
    @State private var isLoadingMedia: Bool = false
    
    // 전체 파일들 (기존 + 새로운)
    private var allFiles: [SelectedFile] { existingFiles + newFiles }
    private var allImages: [UIImage] { existingImages + newImages }
    private var remainingFileSlots: Int { max(0, 5 - existingFiles.count) }
    
    // UI states
    @State private var showingStorePicker = false
    @State private var isFormValid = false
    
    // Video warning states
    @State private var showingLargeVideoWarning = false
    @State private var pendingLargeVideoItems: [PhotosPickerItem] = []
    @State private var showingCompressionFailureAlert = false
    @State private var showingPhotoPicker = false
    
    // 새 게시글 작성용 생성자
    init(viewModel: CreatePostViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.editingPost = nil
        self.onPostUpdated = nil
    }
    
    // 게시글 수정용 생성자
    init(editingPost: PostDetail, viewModel: CreatePostViewModel, onPostUpdated: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.editingPost = editingPost
        self.onPostUpdated = onPostUpdated
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    categorySection
                    titleSection
                    contentSection
                    storeSection
                    mediaSection
                    
                    if !allImages.isEmpty || isLoadingMedia {
                        selectedMediaPreview
                            .padding(4)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            
            // Loading Overlay
            if viewModel.output.isLoading {
                loadingOverlay
            }
        }
        .navigationTitle(isEditMode ? "게시글 수정" : "게시글 작성")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("취소")
                    .wrapToButton {
                        dismiss()
                    }
                    .disabled(viewModel.output.isLoading)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("완료")
                    .wrapToButton {
                        handleSubmitPost()
                    }
                    .disabled(!isFormValid || viewModel.output.isLoading || isLoadingMedia)
                    .foregroundColor((isFormValid && !viewModel.output.isLoading && !isLoadingMedia) ? .blackSprout : .gray)
            }
        }
        .onChange(of: selectedMediaItems) { _ in
            loadSelectedMedia()
        }
        .onChange(of: [category, title, content]) { _ in
            viewModel.input.validateFormTrigger.send((category: category, title: title, content: content))
        }
        .onChange(of: viewModel.output.isFormValid) { isValid in
            isFormValid = isValid
        }
        .onChange(of: viewModel.output.createPostSuccess) { success in
            if success {
                if isEditMode {
                    // 수정 모드일 때 업데이트 콜백 호출 및 알림 전송
                    onPostUpdated?()
                    if let postId = editingPost?.postId {
                        NotificationCenter.default.post(
                            name: Notification.Name("PostUpdated"),
                            object: postId
                        )
                        print("📝 [CreatePostView] 게시글 수정 알림 전송: \(postId)")
                    }
                } else {
                    // 생성 모드일 때 알림 전송
                    NotificationCenter.default.post(
                        name: Notification.Name("PostCreated"),
                        object: nil
                    )
                    print("📝 [CreatePostView] 게시글 생성 알림 전송")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            }
        }
        .onAppear {
            if let editingPost = editingPost {
                // 수정 모드일 때 기존 게시물 데이터로 폼 채우기
                category = editingPost.category
                title = editingPost.title
                content = editingPost.content
                storeId = editingPost.store?.id ?? ""
                
                // 기존 파일 URL들을 저장 (서버 요청용)
                existingFileUrls = editingPost.files
                
                // 기존 이미지들을 UI에 로드
                if !editingPost.files.isEmpty {
                    loadExistingImages(from: editingPost.files)
                }
            }
            viewModel.input.validateFormTrigger.send((category: category, title: title, content: content))
        }
        .alert("게시물 업로드 실패", isPresented: $viewModel.output.showError) {
            Button("확인") {
                viewModel.input.clearErrorTrigger.send(())
            }
        } message: {
            Text(viewModel.output.errorMessage)
        }
        .alert("파일 크기 초과", isPresented: $showingLargeVideoWarning) {
            Button("확인") {
                pendingLargeVideoItems = []
            }
        } message: {
            Text("선택한 동영상이 너무 큽니다 (30MB 초과)")
        }
        .alert("동영상 압축 실패", isPresented: $showingCompressionFailureAlert) {
            Button("확인") { }
        } message: {
            Text("선택한 동영상을 압축할 수 없습니다")
        }
        .handleErrors(viewModel: viewModel)
    }
}

// MARK: - UI Components
private extension CreatePostView {
    
    var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("카테고리")
                .font(.pretendard(.body1))
                .foregroundColor(.blackSprout)
            
            TextField("카테고리를 입력해주세요", text: $category)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.pretendard(.body2))
        }
    }
    
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("제목")
                .font(.pretendard(.body1))
                .foregroundColor(.blackSprout)
            
            TextField("제목을 입력해주세요", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.pretendard(.body2))
        }
    }
    
    var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("내용")
                .font(.pretendard(.body1))
                .foregroundColor(.blackSprout)
            
            TextEditor(text: $content)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .font(.pretendard(.body2))
        }
    }
    
    var storeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("매장 선택 (선택사항)")
                .font(.pretendard(.body1))
                .foregroundColor(.blackSprout)
            
            Button {
                showingStorePicker = true
            } label: {
                HStack {
                    Text(storeId.isEmpty ? "매장을 선택해주세요" : storeId)
                        .font(.pretendard(.body2))
                        .foregroundColor(storeId.isEmpty ? .gray : .blackSprout)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    var mediaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("사진/동영상/GIF 선택")
                    .font(.pretendard(.body1))
                    .foregroundColor(.blackSprout)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if isLoadingMedia {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                    Text("(\(allImages.count)/5)")
                        .font(.pretendard(.caption1))
                        .foregroundColor(.gray)
                }
            }
            
            Button(action: {
                Task {
                    await requestPhotosPermissionAndShowPicker()
                }
            }) {
                HStack {
                    if isLoadingMedia {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(.deepSprout)
                    }
                    
                    Text(isLoadingMedia ? "미디어 처리 중..." : remainingFileSlots > 0 ? "사진/동영상/GIF 추가하기 (최대 \(remainingFileSlots)개)" : "파일 제한 도달 (5/5)")
                        .font(.pretendard(.body2))
                        .foregroundColor(.deepSprout)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.deepSprout.opacity(isLoadingMedia ? 0.05 : 0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.deepSprout.opacity(isLoadingMedia ? 0.5 : 1.0), lineWidth: 1)
                )
            }
            .disabled(isLoadingMedia || remainingFileSlots <= 0)
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedMediaItems,
                maxSelectionCount: remainingFileSlots,
                matching: .any(of: [.images, .videos]),
                photoLibrary: .shared()
            )
        }
    }
    
    var selectedMediaPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("선택된 미디어")
                .font(.pretendard(.body1))
                .foregroundColor(.blackSprout)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 기존 파일들 표시
                    ForEach(Array(existingImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button {
                                removeExistingMedia(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .offset(x: 5, y: -5)
                        }
                        .padding(4)
                    }
                    
                    // 새로 선택한 파일들 표시
                    ForEach(Array(newImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button {
                                removeNewMedia(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .offset(x: 5, y: -5)
                        }
                        .padding(4)
                    }
                    
                    if isLoadingMedia {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 80, height: 80)
                            
                            VStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("처리중")
                                    .font(.pretendard(.caption2))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(4)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .deepSprout))
                    
                    Text("게시글을 업로드하고 있습니다...")
                        .font(.pretendard(.body2))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                }
            )
    }
}

// MARK: - Private Methods
private extension CreatePostView {
    // 권한 요청 후 PhotosPicker 표시
    func requestPhotosPermissionAndShowPicker() async {
        print("🚀 [CreatePostView] 권한 확인 및 PhotosPicker 표시 준비...")
        
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        print("📱 [CreatePostView] 현재 권한 상태: \(authStatus.rawValue)")
        
        var finalStatus = authStatus
        
        // 권한이 결정되지 않았다면 요청
        if authStatus == .notDetermined {
            print("📱 [CreatePostView] 권한 요청 Alert 표시...")
            finalStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            print("📱 [CreatePostView] 권한 요청 결과: \(finalStatus.rawValue)")
        }
        
        // 권한 상태와 관계없이 PhotosPicker 표시
        await MainActor.run {
            showingPhotoPicker = true
            print("✅ [CreatePostView] PhotosPicker 표시됨 (권한 상태: \(finalStatus.rawValue))")
        }
    }
    // 초고속 파일 크기 확인 (데이터 로드 없이)
    func getFileSizeQuickly(_ item: PhotosPickerItem) async -> Float? {
        print("🚀 [CreatePostView] 초고속 크기 확인 시작...")
        
        // Photos 권한 상태 확인 (이미 버튼에서 요청됨)
        let authStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        print("📱 [CreatePostView] 권한 상태: \(authStatus.rawValue)")
        
        // 방법 1: PHAsset 우선 (권한이 있을 때만)
        if let assetIdentifier = item.itemIdentifier, 
           authStatus == .authorized || authStatus == .limited {
            print("✅ [CreatePostView] PHAsset ID 발견: \(assetIdentifier)")
            let fileSizeMB = await withCheckedContinuation { (continuation: CheckedContinuation<Float?, Never>) in
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                
                guard let asset = fetchResult.firstObject else {
                    print("❌ [CreatePostView] PHAsset 찾기 실패")
                    continuation.resume(returning: nil)
                    return
                }
                
                let resources = PHAssetResource.assetResources(for: asset)
                for resource in resources {
                    if resource.type == .video || resource.type == .photo {
                        if let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                            let fileSizeMB = Float(fileSize) / (1024 * 1024)
                            print("✅ [CreatePostView] PHAsset 크기: \(String(format: "%.1f", fileSizeMB))MB (0.1초 완료)")
                            continuation.resume(returning: fileSizeMB)
                            return
                        }
                    }
                }
                print("❌ [CreatePostView] PHAsset 크기 속성 없음")
                continuation.resume(returning: nil)
            }
            
            if let size = fileSizeMB {
                return size
            }
        } else if let assetIdentifier = item.itemIdentifier {
            print("⚠️ [CreatePostView] PHAsset ID 있지만 권한 없음: \(assetIdentifier)")
            print("📱 [CreatePostView] 권한 상태: \(authStatus) - Movie 방식으로 진행")
        } else {
            print("❌ [CreatePostView] PHAsset ID 없음")
            print("🔍 [CreatePostView] PhotosPickerItem 정보:")
            print("  - supportedContentTypes: \(item.supportedContentTypes)")
            if let typeID = item.supportedContentTypes.first?.identifier {
                print("  - 주요 Content Type: \(typeID)")
            }
        }
        
        // 방법 2: 임시 Movie 파일로 크기만 확인 (Data 로드 없이)
        print("🎬 [CreatePostView] Movie 임시 파일 방법 시도...")
        do {
            if let movie = try await item.loadTransferable(type: Movie.self) {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: movie.url.path())
                if let fileSize = fileAttributes[FileAttributeKey.size] as? Int64 {
                    let fileSizeMB = Float(fileSize) / (1024 * 1024)
                    print("✅ [CreatePostView] Movie 파일 크기: \(String(format: "%.1f", fileSizeMB))MB (1-2초 완료)")
                    
                    // 임시 파일 정리
                    try? FileManager.default.removeItem(at: movie.url)
                    
                    return fileSizeMB
                }
            }
        } catch {
            print("❌ [CreatePostView] Movie 파일 크기 확인 실패: \(error)")
        }
        
        print("❌ [CreatePostView] 모든 빠른 크기 확인 방법 실패 - 폴백 필요")
        return nil
    }
    
    func loadSelectedMedia() {
        isLoadingMedia = true
        print("📸 [CreatePostView] 미디어 로딩 시작: \(selectedMediaItems.count)개 아이템")
        
        Task {
            var images: [UIImage] = []
            var files: [SelectedFile] = []
            var hasLargeVideoError = false
            var failedItemIndices: [Int] = [] // 실패한 아이템들의 인덱스 추적
            
            for (index, item) in selectedMediaItems.enumerated() {
                print("📸 [CreatePostView] 아이템 \(index + 1) 처리 중...")
                
                // 🚀 0단계: 빠른 파일 크기 확인 (Data > Movie > PHAsset 순서)
                if let fileSizeMB = await getFileSizeQuickly(item) {
                    if fileSizeMB > 30.0 {
                        print("🚨 [CreatePostView] 파일 크기 초과: \(String(format: "%.1f", fileSizeMB))MB > 30MB - 즉시 거부")
                        hasLargeVideoError = true
                        failedItemIndices.append(index)
                        continue // Movie 로드 없이 바로 다음 파일로!
                    }
                    print("✅ [CreatePostView] 크기 체크 통과: \(String(format: "%.1f", fileSizeMB))MB - 처리 계속")
                } else {
                    print("⚠️ [CreatePostView] 빠른 크기 체크 실패 - 전체 로드 후 체크")
                }
                
                // 🎬 1단계: Movie 로드 (PHAsset 체크 통과한 파일만)
                if let movie = try? await item.loadTransferable(type: Movie.self) {
                    print("✅ [CreatePostView] Movie 로드 성공: \(movie.url)")
                    
                    // 🔄 2단계: 데이터 로드 (PHAsset에서 이미 크기 확인했으므로 바로 로드)
                    guard let originalVideoData = try? Data(contentsOf: movie.url) else {
                        print("❌ [CreatePostView] 비디오 데이터 로드 실패")
                        failedItemIndices.append(index)
                        continue
                    }
                    
                    let fileSizeMB = Float(originalVideoData.count) / (1024 * 1024)
                    print("📊 [CreatePostView] 데이터 로드 완료: \(String(format: "%.1f", fileSizeMB))MB")
                    
                    let fileName = "video_\(Int(Date().timeIntervalSince1970))_\(index).mp4"
                    
                    // 🔄 3단계: 압축 처리 (5MB 이상일 경우)
                    var processedData = originalVideoData
                    if fileSizeMB > 5.0 {
                        print("🔄 [CreatePostView] 동영상 압축 시작: \(String(format: "%.1f", fileSizeMB))MB → 목표 5MB")
                        
                        do {
                            let compressionResult = try await VideoProcessingManager.shared.compressVideoTo5MB(
                                inputURL: movie.url,
                                targetSizeMB: 5.0
                            )
                            processedData = try Data(contentsOf: compressionResult.url)
                            let compressedSizeMB = Float(processedData.count) / (1024 * 1024)
                            print("✅ [CreatePostView] 동영상 압축 완료: \(String(format: "%.1f", fileSizeMB))MB → \(String(format: "%.1f", compressedSizeMB))MB")
                            
                            // 임시 파일 정리
                            try? FileManager.default.removeItem(at: compressionResult.url)
                        } catch {
                            print("❌ [CreatePostView] 동영상 압축 실패: \(error)")
                            
                            failedItemIndices.append(index)
                            await MainActor.run {
                                showCompressionFailureAlert()
                            }
                            continue // 압축 실패시 썸네일 생성 없이 다음 파일로
                        }
                    }
                    
                    // 📸 4단계: 썸네일 생성 (성공한 파일에 대해서만)
                    print("📸 [CreatePostView] 썸네일 생성 시작 (처리된 파일 크기: \(String(format: "%.1f", Float(processedData.count) / (1024 * 1024)))MB)")
                    
                    if let thumbnailData = await VideoProcessingManager.shared.generateThumbnailDataForPreview(
                        movie.url,
                        size: CGSize(width: 300, height: 300)
                    ) {
                        print("✅ [CreatePostView] 동영상 썸네일 데이터 생성: \(thumbnailData.count) bytes")
                        if let thumbnailImage = UIImage(data: thumbnailData) {
                            images.append(thumbnailImage)
                            print("✅ [CreatePostView] 동영상 썸네일 생성 및 처리 완료")
                        } else {
                            print("❌ [CreatePostView] 썸네일 데이터 → UIImage 변환 실패")
                            images.append(createVideoPlaceholderImage())
                        }
                    } else {
                        print("❌ [CreatePostView] 동영상 썸네일 데이터 생성 실패")
                        images.append(createVideoPlaceholderImage())
                    }
                    
                    // 🎯 5단계: SelectedFile 생성 (모든 처리 완료 후)
                    let selectedFile = SelectedFile(
                        id: UUID(),
                        type: .video,
                        image: nil,
                        data: processedData,
                        fileName: fileName
                    )
                    files.append(selectedFile)
                }
                // 동영상이 아니면 이미지/GIF로 처리
                else if let data = try? await item.loadTransferable(type: Data.self) {
                    print("📸 [CreatePostView] Data 로드 성공: \(data.count) bytes")
                    
                    let format = UnifiedMediaCacheManager.DetectedMediaFormat.detect(from: data)
                    print("📸 [CreatePostView] 감지된 포맷: \(format)")
                    
                    let fileName: String
                    let fileType: SelectedFile.FileType = .image
                    
                    if format == .gif {
                        fileName = "gif_\(Int(Date().timeIntervalSince1970))_\(index).gif"
                        print("📸 [CreatePostView] GIF 처리 시작")
                    } else {
                        fileName = "image_\(Int(Date().timeIntervalSince1970))_\(index).jpg"
                        print("📸 [CreatePostView] 일반 이미지 처리 시작")
                    }
                    
                    let thumbnailImage = ImageProcessingManager.shared.downsampleForDisplay(
                        data: data,
                        pointSize: CGSize(width: 300, height: 300),
                        scale: UIScreen.main.scale
                    ) ?? UIImage(data: data)
                    
                    if let thumbnail = thumbnailImage {
                        let selectedFile = SelectedFile(
                            id: UUID(),
                            type: fileType,
                            image: thumbnail,
                            data: data,
                            fileName: fileName
                        )
                        files.append(selectedFile)
                        images.append(thumbnail)
                        print("✅ [CreatePostView] \(format == .gif ? "GIF" : "이미지") 처리 완료")
                    } else {
                        print("❌ [CreatePostView] 썸네일 생성 실패")
                    }
                } else {
                    print("❌ [CreatePostView] 알 수 없는 미디어 타입")
                }
            }
            
            await MainActor.run {
                newImages = images      // 새 파일용 배열에 저장
                newFiles = files        // 새 파일용 배열에 저장
                
                // 실패한 아이템들을 selectedMediaItems에서 제거 (역순으로 제거해야 인덱스 오류 방지)
                for index in failedItemIndices.sorted(by: >) {
                    if index < selectedMediaItems.count {
                        selectedMediaItems.remove(at: index)
                        print("📸 [CreatePostView] 실패한 아이템 제거: index \(index)")
                    }
                }
                
                isLoadingMedia = false
                print("📸 [CreatePostView] 미디어 로딩 완료: \(images.count)개 새 이미지, \(files.count)개 새 파일")
                print("📸 [CreatePostView] 제거된 실패 아이템: \(failedItemIndices.count)개")
                
                // 30MB 초과 파일이 있었다면 Alert 표시
                if hasLargeVideoError {
                    showingLargeVideoWarning = true
                }
            }
        }
    }
    
    func showCompressionFailureAlert() {
        showingCompressionFailureAlert = true
    }
    
    func removeExistingMedia(at index: Int) {
        existingImages.remove(at: index)
        existingFiles.remove(at: index)
        existingFileUrls.remove(at: index)  // URL도 함께 제거
        print("📸 [CreatePostView] 기존 파일 제거: \(index)")
    }
    
    func removeNewMedia(at index: Int) {
        newImages.remove(at: index)
        newFiles.remove(at: index)
        if index < selectedMediaItems.count {
            selectedMediaItems.remove(at: index)
        }
        print("📸 [CreatePostView] 새 파일 제거: \(index)")
    }
    
    func createVideoPlaceholderImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.systemGray4.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        let playButtonRect = CGRect(x: 35, y: 35, width: 30, height: 30)
        UIColor.white.setFill()
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: playButtonRect.minX + 8, y: playButtonRect.minY + 5))
        path.addLine(to: CGPoint(x: playButtonRect.minX + 8, y: playButtonRect.maxY - 5))
        path.addLine(to: CGPoint(x: playButtonRect.maxX - 5, y: playButtonRect.midY))
        path.close()
        path.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
    
    func loadExistingImages(from filePaths: [String]) {
        Task {
            var images: [UIImage] = []
            var files: [SelectedFile] = []
            
            for (index, file) in filePaths.enumerated() {
                // UnifiedMediaCacheManager를 사용하여 이미지 로드
                if let loadResult = await UnifiedMediaCacheManager.shared.loadImage(
                    from: file,
                    size: CGSize(width: 300, height: 300),
                    isFullSize: false
                ) {
                    images.append(loadResult.image)
                    
                    // SelectedFile 생성 (수정 모드에서는 기존 파일 유지)
                    let selectedFile = SelectedFile(
                        id: UUID(),
                        type: loadResult.detectedFormat.isVideo ? .video : .image,
                        image: loadResult.image,
                        data: loadResult.originalData,
                        fileName: URL(string: file)?.lastPathComponent ?? "existing_file_\(index)"
                    )
                    files.append(selectedFile)
                }
            }
            
            await MainActor.run {
                existingImages = images  // 기존 파일용 배열에 저장
                existingFiles = files    // 기존 파일용 배열에 저장
            }
        }
    }
    
    func handleSubmitPost() {
        if isEditMode {
            // 수정 모드일 때
            guard let editingPost = editingPost else { return }
            
            // 새 파일만 업로드하고, 기존 파일 URL과 병합
            handleUpdatePost(editingPost: editingPost)
        } else {
            // 새 게시글 작성 모드일 때
            let param = CreatePostParam(
                category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                storeId: storeId.isEmpty ? nil : storeId,
                latitude: 0,
                longitude: 0,
                selectedFiles: allFiles,
                existingFileUrls: nil  // 새 게시글에는 기존 파일 없음
            )
            
            viewModel.input.createPostTrigger.send(param)
        }
    }
    
    func handleUpdatePost(editingPost: PostDetail) {
        // 간단하게 통합 처리: 새 파일만 업로드하고 기존 URL과 병합
        let param = CreatePostParam(
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            storeId: storeId.isEmpty ? nil : storeId,
            latitude: editingPost.geolocation.latitude,
            longitude: editingPost.geolocation.longitude,
            selectedFiles: newFiles,                    // 새 파일만 업로드용
            existingFileUrls: existingFileUrls          // 기존 파일 URL들
        )
        
        viewModel.input.updatePostTrigger.send((postId: editingPost.postId, param: param))
    }
}
