//
//  CreatePostViewModel.swift
//  PickPle
//
//  Created by 정인선 on 8/27/25.
//

import Foundation
import Combine

final class CreatePostViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    private let postRepository: PostRepository
    
    init(postRepository: PostRepository) {
        self.postRepository = postRepository
        super.init()
        transform()
    }
}

// MARK: - Input/Output
extension CreatePostViewModel {
    struct Input {
        let createPostTrigger = PassthroughSubject<CreatePostParam, Never>()
        let updatePostTrigger = PassthroughSubject<(postId: String, param: CreatePostParam), Never>()
        let validateFormTrigger = PassthroughSubject<(category: String, title: String, content: String), Never>()
        let clearErrorTrigger = PassthroughSubject<Void, Never>()
    }
    
    struct Output {
        var isLoading = false
        var errorMessage = ""
        var showError = false
        var isFormValid = false
        var uploadedFilePaths: [String] = []
        var createPostSuccess = false
    }
    
    func transform() {
        input.createPostTrigger
            .sink { [weak self] param in
                self?.createPost(param)
            }
            .store(in: &cancellables)
        
        input.updatePostTrigger
            .sink { [weak self] postData in
                self?.updatePost(postId: postData.postId, param: postData.param)
            }
            .store(in: &cancellables)
        
        input.validateFormTrigger
            .sink { [weak self] formData in
                self?.validateForm(category: formData.category, title: formData.title, content: formData.content)
            }
            .store(in: &cancellables)
        
        input.clearErrorTrigger
            .sink { [weak self] _ in
                self?.clearError()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private Methods
private extension CreatePostViewModel {
    // MARK: - Form Validation
    func validateForm(category: String, title: String, content: String) {
        output.isFormValid = !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Clear Error
    func clearError() {
        output.showError = false
        output.errorMessage = ""
    }
    
    // MARK: - Create Post
    func createPost(_ param: CreatePostParam) {
        output.isLoading = true
        output.errorMessage = ""
        output.createPostSuccess = false
        
        print("📝 [CreatePostViewModel] 게시글 작성 시작")
        
        // 위치 정보 확인
        guard let selectedLocation = UserDefaultsManager.selectedLocation else {
            print("❌ [CreatePostViewModel] 위치 정보가 없습니다")
            output.errorMessage = "위치 정보를 설정해주세요."
            output.showError = true
            output.isLoading = false
            return
        }
        
        // 파일이 있는 경우 파일 업로드 먼저 처리
        if !param.selectedFiles.isEmpty {
            uploadFiles(param.selectedFiles) { [weak self] uploadedFilePaths in
                guard let self else { return }
                // 기존 파일 URL + 새 업로드 URL 병합 (새 게시글에서는 기존 파일 없음)
                let allFileUrls = (param.existingFileUrls ?? []) + uploadedFilePaths
                createPostWithUploadedFiles(param, uploadedFilePaths: allFileUrls, selectedLocation: selectedLocation)
            }
        } else {
            // 파일이 없는 경우 바로 게시글 작성
            createPostWithUploadedFiles(param, uploadedFilePaths: param.existingFileUrls ?? [], selectedLocation: selectedLocation)
        }
    }
    
    // MARK: - File Upload
    func uploadFiles(_ selectedFiles: [SelectedFile], completion: (([String]) -> Void)?) {
        print("📸 [CreatePostViewModel] 파일 업로드 시작: \(selectedFiles.count)개")
        
        // SelectedFile을 MultipartFile로 변환 (asMultipartFile 사용)
        Task {
            var multipartFiles: [MultipartFile] = []
            
            for (index, selectedFile) in selectedFiles.enumerated() {
                print("📸 [CreatePostViewModel] 파일 아이템 \(index + 1) 처리 중...")
                
                // SelectedFile의 asMultipartFile 사용 (압축 포함)
                if let multipartFile = selectedFile.asMultipartFile {
                    multipartFiles.append(multipartFile)
                    print("✅ [CreatePostViewModel] 압축 및 MultipartFile 생성 완료: \(selectedFile.fileName)")
                    print("📊 [CreatePostViewModel] 압축 결과: \(selectedFile.data.count / 1024)KB → \(multipartFile.data.count / 1024)KB")
                } else {
                    print("❌ [CreatePostViewModel] MultipartFile 생성 실패: \(selectedFile.fileName)")
                }
            }
            
            await MainActor.run {
                guard !multipartFiles.isEmpty else {
                    print("❌ [CreatePostViewModel] MultipartFile 변환 실패")
                    output.errorMessage = "파일 변환에 실패했습니다."
                    output.showError = true
                    output.isLoading = false
                    return
                }
                
                // PostRepository의 sendFile 메서드로 파일 업로드
                postRepository.sendFile(files: multipartFiles)
                    .receive(on: DispatchQueue.main)
                    .sink(with: self) { owner, result in
                        switch result {
                        case .success(let response):
                            print("✅ [CreatePostViewModel] 파일 업로드 완료: \(response.files)")
                            owner.output.uploadedFilePaths = response.files
                            completion?(response.files)
                        case .failure(let error):
                            print("❌ [CreatePostViewModel] 파일 업로드 실패: \(error)")
                            owner.output.errorMessage = "파일 업로드에 실패했습니다.\n네트워크 상태를 확인하고 다시 시도해주세요."
                            owner.output.showError = true
                            owner.output.isLoading = false
                        }
                    }
                    .store(in: &cancellables)
            }
        }
    }
    
    // MARK: - Create Post With Uploaded Files
    func createPostWithUploadedFiles(_ param: CreatePostParam, uploadedFilePaths: [String], selectedLocation: Location) {
        // 업로드된 파일 경로로 CreatePostRequest 생성
        let request = CreatePostRequest(
            category: param.category,
            title: param.title,
            content: param.content,
            storeId: param.storeId,
            latitude: selectedLocation.latitude,
            longitude: selectedLocation.longitude,
            files: uploadedFilePaths
        )
        
        // 게시글 작성 API 호출
        postRepository.createPost(request: request)
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                owner.output.isLoading = false
                switch result {
                case .success(let response):
                    print("✅ [CreatePostViewModel] 게시글 작성 성공: \(response.postId)")
                    owner.output.createPostSuccess = true
                case .failure(let error):
                    print("❌ [CreatePostViewModel] 게시글 작성 실패: \(error)")
                    owner.output.errorMessage = "게시물 업로드에 실패했습니다.\n잠시 후 다시 시도해주세요."
                    owner.output.showError = true
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Update Post
    func updatePost(postId: String, param: CreatePostParam) {
        output.isLoading = true
        output.errorMessage = ""
        output.createPostSuccess = false
        
        print("📝 [CreatePostViewModel] 게시글 수정 시작: \(postId)")
        
        // 새 파일이 있는 경우 새 파일만 업로드
        if !param.selectedFiles.isEmpty {
            uploadFiles(param.selectedFiles) { [weak self] newUploadedFilePaths in
                guard let self else { return }
                // 기존 파일 URL + 새 업로드 URL 병합
                let allFileUrls = (param.existingFileUrls ?? []) + newUploadedFilePaths
                updatePostWithUploadedFiles(postId: postId, param: param, uploadedFilePaths: allFileUrls)
            }
        } else {
            // 새 파일이 없는 경우 기존 파일 URL만 사용
            let existingUrls = param.existingFileUrls ?? []
            updatePostWithUploadedFiles(postId: postId, param: param, uploadedFilePaths: existingUrls)
        }
    }
    
    // MARK: - Update Post With Uploaded Files
    func updatePostWithUploadedFiles(postId: String, param: CreatePostParam, uploadedFilePaths: [String]) {
        // 업로드된 파일 경로로 UpdatePostRequest 생성
        let request = UpdatePostRequest(
            category: param.category,
            title: param.title,
            content: param.content,
            storeId: param.storeId,
            latitude: param.latitude,
            longitude: param.longitude,
            files: uploadedFilePaths
        )
        
        // 게시글 수정 API 호출
        postRepository.updatePost(postId: postId, request: request)
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                owner.output.isLoading = false
                switch result {
                case .success(let response):
                    print("✅ [CreatePostViewModel] 게시글 수정 성공: \(response.postId)")
                    owner.output.createPostSuccess = true
                case .failure(let error):
                    print("❌ [CreatePostViewModel] 게시글 수정 실패: \(error)")
                    owner.output.errorMessage = "게시물 수정에 실패했습니다.\n잠시 후 다시 시도해주세요."
                    owner.output.showError = true
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Action
extension CreatePostViewModel {
    enum Action {
        case createPost(CreatePostParam)
        case validateForm(category: String, title: String, content: String)
        case clearError
    }
    
    func action(_ action: Action) {
        switch action {
        case .createPost(let param):
            input.createPostTrigger.send(param)
        case .validateForm(let category, let title, let content):
            input.validateFormTrigger.send((category: category, title: title, content: content))
        case .clearError:
            input.clearErrorTrigger.send(())
        }
    }
}
