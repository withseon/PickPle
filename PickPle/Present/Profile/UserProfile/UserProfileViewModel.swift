//
//  UserProfileViewModel.swift
//  PickPle
//
//  Created by 정인선 on 6/7/25.
//

import Foundation
import Combine
import UIKit

struct UpdateProfileParam {
    var nick: String?
    var phoneNum: String?
    var profileImage: String?
    
    static var empty: UpdateProfileParam {
        return .init()
    }
}

final class UserProfileViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    private let userId: String? // nil이면 현재 사용자
    private let userRepository: UserRepository
    private let postRepository: PostRepository
    private var userPostsParam = UserPostsParam.empty
    private var updateProfileParam = UpdateProfileParam.empty

    init(userId: String? = nil, nickname: String? = nil, profileImage: String? = nil, userRepository: UserRepository, postRepository: PostRepository) {
        self.userId = userId
        self.userRepository = userRepository
        self.postRepository = postRepository
        super.init()
        // 현재 사용자인지 판단
        output.isCurrentUser = (userId == nil || userId == UserDefaultsManager.userId)

        // 타 사용자 정보가 전달된 경우 즉시 설정
        if !output.isCurrentUser, let nickname = nickname {
            output.nickname = nickname
            output.profileImage = profileImage ?? ""
        }

        transform()
    }
}

// MARK: - Input/Output
extension UserProfileViewModel {
    struct Input {
        let fetchDataTrigger = PassthroughSubject<Void, Never>()
        let selectTabTrigger = PassthroughSubject<ProfileTab, Never>()
        let validateNicknameTrigger = PassthroughSubject<String, Never>()
        let validatePhoneNumTrigger = PassthroughSubject<String, Never>()
        let updateProfileImageTrigger = PassthroughSubject<(data: Data, fileName: String, previewImage: UIImage), Never>()
        let updateNicknameTrigger = PassthroughSubject<String, Never>()
        let updatePhoneNumTrigger = PassthroughSubject<String, Never>()
    }

    struct Output {
        var isCurrentUser: Bool = false
        var profileImage = ""
        var nickname = ""
        var phoneNumber = ""
        var selectedTab: ProfileTab = .posts
        var posts = [PostThumbnail]()
        
        // ✅ 프로필 업데이트 관련 필드들
        var temporaryProfileImage: UIImage? = nil
        var isUpdatingProfile = false
        
        // ✅ 검증 관련 필드들 - 코드에서 사용하는 필수 필드들
        var nicknameErrorMessage = ""
        var phoneNumberErrorMessage = ""
        var isProfileDataValid = true
        var canSaveProfile = false
        
        // ✅ 로딩 상태 관리
        var isPostsLoading = false
    }

    func transform() {
        input.fetchDataTrigger
            .sink(with: self) { owner, _ in
                owner.fetchProfileData()
                owner.fetchPostData()
            }
            .store(in: &cancellables)
        
        input.selectTabTrigger
            .sink(with: self) { owner, tab in
                owner.output.selectedTab = tab
            }
            .store(in: &cancellables)
        
        input.validateNicknameTrigger
            .sink { [weak self] nickname in
                guard let self else { return }
                updateProfileParam.nick = nickname
                validateAllProfileData() // 전체 검증
            }
            .store(in: &cancellables)
        
        input.validatePhoneNumTrigger
            .sink { [weak self] phoneNumber in
                guard let self else { return }
                updateProfileParam.phoneNum = phoneNumber
                validateAllProfileData() // 전체 검증
            }
            .store(in: &cancellables)
        
        input.updateProfileImageTrigger
            .sink(with: self) { owner, imageData in
                owner.updateProfileImage(data: imageData.data, fileName: imageData.fileName, previewImage: imageData.previewImage)
            }
            .store(in: &cancellables)
        
        input.updateNicknameTrigger
            .sink(with: self) { owner, nickname in
                owner.updateNickname(nickname)
            }
            .store(in: &cancellables)
        
        input.updatePhoneNumTrigger
            .sink(with: self) { owner, phoneNumber in
                owner.updatePhoneNumber(phoneNumber)
            }
            .store(in: &cancellables)
    }
    
    private func fetchProfileData() {
        if output.isCurrentUser {
            // 현재 사용자인 경우 UserDefaults에서 가져오기
            if let userProfile = UserDefaultsManager.userProfile {
                DispatchQueue.main.async {
                    self.output.profileImage = userProfile.profileImage ?? ""
                    self.output.nickname = userProfile.nickname
                    self.output.phoneNumber = userProfile.phoneNum ?? ""
                }
            } else {
                print("❌ UserDefaults에 userProfile이 없음")
            }
        }
        // 타 사용자 정보는 init에서 이미 설정됨
    }

    private func fetchPostData() {
        guard let currentUserId = UserDefaultsManager.userId else { return }
        userPostsParam.userId = userId ?? currentUserId
        
        let publish = postRepository.userPosts(userPostsParam)
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    owner.output.posts = success.data.map { $0.asPostThumbnail }
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - 프로필 이미지 업데이트 로직
extension UserProfileViewModel {
    // MARK: - 프로필 이미지 업데이트 메인 로직
    private func updateProfileImage(data: Data, fileName: String, previewImage: UIImage) {
        print("🔄 프로필 이미지 업데이트 시작")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 1. 즉시 UI에 반영 (사용자 경험 향상)
        DispatchQueue.main.async {
            self.output.temporaryProfileImage = previewImage
            self.output.isUpdatingProfile = true
            print("✅ UI에 즉시 반영 완료")
        }
        
        // 2. 백그라운드에서 이미지 처리 및 서버 전송
        Task.detached(priority: .userInitiated) {
            let processingStartTime = CFAbsoluteTimeGetCurrent()
            
            // 다운샘플링 및 압축
            guard let processedData = await self.processImageDataForUpload(data, fileName: fileName) else {
                await self.handleProfileImageUploadFailure(ProfileUpdateError.imageProcessingFailed)
                return
            }
            
            let processingTime = CFAbsoluteTimeGetCurrent() - processingStartTime
            print("📊 이미지 처리 소요시간: \(processingTime)초")
            
            // 3. 서버에 전송
            await self.uploadProfileImageToServer(processedData, originalImage: previewImage)
            
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            print("📊 전체 프로필 이미지 업데이트 소요시간: \(totalTime)초")
        }
    }
    
    // MARK: - 이미지 처리 (Data 기반 다운샘플링 + 압축)
    private func processImageDataForUpload(_ data: Data, fileName: String) async -> Data? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // MultipartFile을 통한 포맷 감지 및 처리
                guard let multipartFile = MultipartFile.from(
                    data: data,
                    originalFileName: fileName,
                    fieldName: "profileImage",
                    maxSizeKB: 1024 // 1MB 제한
                ) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: multipartFile.data)
            }
        }
    }
    
    // MARK: - 서버 업로드 및 캐싱
    private func uploadProfileImageToServer(_ imageData: Data, originalImage: UIImage) async {
        let uploadStartTime = CFAbsoluteTimeGetCurrent()
        
        // MultipartFile 생성
        guard let multipartFile = MultipartFile.from(
            data: imageData,
            originalFileName: "profile_\(UserDefaultsManager.userId ?? UUID().uuidString)",
            fieldName: "profileImage",
            maxSizeKB: 1024
        ) else {
            print("❌UserProfileViewModel - Multipart 생성 실패")
            return
        }
        
        do {
            let response = userRepository.uploadProfileImage(multipartFile)
        }
        
        // TODO: 서버 업로드 API 호출
        // do {
        //     let response = try await userRepository.uploadProfileImage(multipartFile)
        //     await handleProfileImageUploadSuccess(
        //         serverImagePath: response.imagePath,
        //         originalImage: originalImage,
        //         processedData: imageData
        //     )
        // } catch {
        //     await handleProfileImageUploadFailure(error)
        // }
        
        // 임시로 성공 시뮬레이션 (2초 후)
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        let mockServerImagePath = "/profile/images/profile_\(UUID().uuidString).jpg"
        
        let uploadTime = CFAbsoluteTimeGetCurrent() - uploadStartTime
        print("📊 서버 업로드 소요시간: \(uploadTime)초")
        
        // 성공 시 처리
        await handleProfileImageUploadSuccess(
            serverImagePath: mockServerImagePath,
            originalImage: originalImage,
            processedData: imageData
        )
    }
    
    // MARK: - 업로드 성공 처리
    private func handleProfileImageUploadSuccess(
        serverImagePath: String,
        originalImage: UIImage,
        processedData: Data
    ) async {
        let cacheStartTime = CFAbsoluteTimeGetCurrent()
        
        // 4. UserDefaults에 새로운 이미지 경로 저장
        await MainActor.run {
            if var userProfile = UserDefaultsManager.userProfile {
                userProfile.profileImage = serverImagePath
                UserDefaultsManager.userProfile = userProfile
                
                // UI 업데이트 - 정식 이미지로 전환
                self.output.profileImage = serverImagePath
                self.output.temporaryProfileImage = nil
                self.output.isUpdatingProfile = false
                
                print("✅ UserDefaults 및 UI 업데이트 완료")
            }
        }
        
        // 5. 이미지 캐시에 저장 (향후 빠른 로딩을 위해)
        let cacheKey = serverImagePath.replacingOccurrences(of: "/", with: "")
        
        // 캐시에 다운샘플된 이미지와 원본 데이터 저장
        let cachedImage = ImageProcessingManager.shared.downsampleForDisplay(
            data: processedData,
            pointSize: CGSize(width: 150, height: 150), // 프로필 이미지 표시 크기
            scale: UIScreen.main.scale
        ) ?? originalImage
        
        ImageCacheManager.shared.cacheUploadedImage(
            image: cachedImage,
            forKey: cacheKey,
            originalData: processedData
        )
        
        let cacheTime = CFAbsoluteTimeGetCurrent() - cacheStartTime
        print("📊 캐싱 소요시간: \(cacheTime)초")
        print("🎉 프로필 이미지 업데이트 완료: \(serverImagePath)")
    }
    
    // MARK: - 업로드 실패 처리
    private func handleProfileImageUploadFailure(_ error: Error) async {
        await MainActor.run {
            print("❌ 프로필 이미지 업로드 실패: \(error)")
            
            // UI 상태 롤백
            self.output.temporaryProfileImage = nil
            self.output.isUpdatingProfile = false
            
            // TODO: 사용자에게 오류 메시지 표시
            // TODO: Alert 또는 Toast 메시지로 에러 알림
        }
    }
}

// MARK: - 검증 로직 (ValidationHelper 사용)
extension UserProfileViewModel {
    
    // ✅ ValidationHelper를 사용한 전체 프로필 데이터 검증 (SignUpViewModel 패턴)
    private func validateAllProfileData() {
        let currentNickname = updateProfileParam.nick ?? ""
        let currentPhoneNumber = updateProfileParam.phoneNum ?? ""
        
        let validationResult = ValidationHelper.validateUserInfo(
            nickname: currentNickname,
            phoneNumber: currentPhoneNumber
        )
        
        // UI 상태 업데이트
        output.nicknameErrorMessage = validationResult.nicknameErrorMessage
        output.phoneNumberErrorMessage = validationResult.phoneNumberErrorMessage
        output.isProfileDataValid = validationResult.isValid
        
        // ✅ 편집 버튼 활성화 조건 체크
        updateCanSaveProfile()
        
        print("📊 프로필 검증 결과 - 닉네임: \(validationResult.nickname.isValid), 핸드폰: \(validationResult.phoneNumber.isValid)")
    }
    
    // ✅ 편집 버튼 활성화 조건 확인 (변경사항이 있고 + 검증 통과)
    private func updateCanSaveProfile() {
        let hasNicknameChanged = updateProfileParam.nick != output.nickname
        let hasPhoneNumberChanged = updateProfileParam.phoneNum != output.phoneNumber
        let hasChanges = hasNicknameChanged || hasPhoneNumberChanged
        
        // 변경사항이 있고 검증을 통과한 경우에만 저장 가능
        output.canSaveProfile = hasChanges && output.isProfileDataValid
        
        print("📊 편집 버튼 상태 - 변경사항: \(hasChanges), 검증통과: \(output.isProfileDataValid), 저장가능: \(output.canSaveProfile)")
    }
    
    // ✅ 닉네임만 개별 검증
    private func validateNicknameOnly(_ nickname: String) -> ValidationResult {
        return ValidationHelper.validateNickname(nickname)
    }
    
    // ✅ 핸드폰 번호만 개별 검증
    private func validatePhoneNumberOnly(_ phoneNumber: String) -> ValidationResult {
        return ValidationHelper.validatePhoneNumber(phoneNumber)
    }
}

// MARK: - 닉네임 업데이트 로직
extension UserProfileViewModel {
    
    // MARK: - 닉네임 업데이트 로직
    private func updateNickname(_ newNickname: String) {
        print("🔄 닉네임 업데이트 시작: \(newNickname)")
        
        // ✅ ValidationHelper를 사용한 닉네임 검증
        let validationResult = ValidationHelper.validateNickname(newNickname)
        
        guard validationResult.isValid else {
            print("❌ 닉네임 검증 실패: \(validationResult.errorMessage)")
            // UI 에러 메시지 업데이트
            output.nicknameErrorMessage = validationResult.errorMessage
            return
        }
        
        // 검증된 닉네임으로 진행
        guard let validatedNickname = validationResult.value else { return }
        
        // 1. 즉시 UI에 반영
        let previousNickname = output.nickname
        output.nickname = validatedNickname
        output.isUpdatingProfile = true
        output.nicknameErrorMessage = "" // 에러 메시지 클리어
        
        // 2. 서버 업데이트
        Task {
            do {
                // TODO: 서버 API 호출
                // try await userRepository.updateNickname(validatedNickname)
                
                // 임시로 성공 시뮬레이션 (1초 후)
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    // 성공 시 UserDefaults 업데이트
                    if var userProfile = UserDefaultsManager.userProfile {
                        userProfile.nickname = validatedNickname
                        UserDefaultsManager.userProfile = userProfile
                    }
                    
                    self.output.isUpdatingProfile = false
                    print("✅ 닉네임 업데이트 완료: \(validatedNickname)")
                }
                
            } catch {
                await MainActor.run {
                    // 실패 시 기존 닉네임으로 롤백
                    self.output.nickname = previousNickname
                    self.output.isUpdatingProfile = false
                    print("❌ 닉네임 업데이트 실패: \(error)")
                    
                    // TODO: 사용자에게 오류 메시지 표시
                }
            }
        }
    }
    
    // MARK: - 핸드폰 번호 업데이트 로직
    private func updatePhoneNumber(_ newPhoneNumber: String) {
        print("🔄 핸드폰 번호 업데이트 시작: \(newPhoneNumber)")
        
        // ✅ ValidationHelper를 사용한 핸드폰 번호 검증
        let validationResult = ValidationHelper.validatePhoneNumber(newPhoneNumber)
        
        guard validationResult.isValid else {
            print("❌ 핸드폰 번호 검증 실패: \(validationResult.errorMessage)")
            // UI 에러 메시지 업데이트
            output.phoneNumberErrorMessage = validationResult.errorMessage
            return
        }
        
        // 검증된 핸드폰 번호로 진행
        guard let validatedPhoneNumber = validationResult.value else { return }
        
        // 1. 즉시 UI에 반영
        let previousPhoneNumber = output.phoneNumber
        output.phoneNumber = validatedPhoneNumber
        output.isUpdatingProfile = true
        output.phoneNumberErrorMessage = "" // 에러 메시지 클리어
        
        // 2. 서버 업데이트
        Task {
            do {
                // TODO: 서버 API 호출
                // try await userRepository.updatePhoneNumber(validatedPhoneNumber)
                
                // 임시로 성공 시뮬레이션 (1초 후)
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    // 성공 시 UserDefaults 업데이트
                    if var userProfile = UserDefaultsManager.userProfile {
                        userProfile.phoneNum = validatedPhoneNumber
                        UserDefaultsManager.userProfile = userProfile
                    }
                    
                    self.output.isUpdatingProfile = false
                    print("✅ 핸드폰 번호 업데이트 완료: \(validatedPhoneNumber)")
                }
                
            } catch {
                await MainActor.run {
                    // 실패 시 기존 핸드폰 번호로 롤백
                    self.output.phoneNumber = previousPhoneNumber
                    self.output.isUpdatingProfile = false
                    print("❌ 핸드폰 번호 업데이트 실패: \(error)")
                    
                    // TODO: 사용자에게 오류 메시지 표시
                }
            }
        }
    }
}

// MARK: - Action
extension UserProfileViewModel {
    enum Action {
        case fetchData
        case selectTab(_ tab: ProfileTab)
        case validateNickname(_ nickname: String)  // 🆕 추가 필요
        case validatePhoneNum(_ phoneNumber: String)  // 🆕 추가 필요
        case updateProfileImage(data: Data, fileName: String, previewImage: UIImage)
        case updateNickname(_ nick: String)
        case updatePhoneNum(_ phoneNumber: String)  // 🆕 추가 필요 (기존에도 Input은 있었음)
        case startChat
    }

    func action(_ action: Action) {
        switch action {
        case .fetchData:
            input.fetchDataTrigger.send(())
        case .selectTab(let tab):
            input.selectTabTrigger.send(tab)
        case .validateNickname(let nickname):  // 🆕 추가
            input.validateNicknameTrigger.send(nickname)
        case .validatePhoneNum(let phoneNumber):  // 🆕 추가
            input.validatePhoneNumTrigger.send(phoneNumber)
        case .updateProfileImage(let data, let fileName, let previewImage):
            input.updateProfileImageTrigger.send((data: data, fileName: fileName, previewImage: previewImage))
        case .updateNickname(let nick):
            input.updateNicknameTrigger.send(nick)
        case .updatePhoneNum(let phoneNumber):  // 🆕 추가
            input.updatePhoneNumTrigger.send(phoneNumber)
        case .startChat:
            // TODO: 채팅 시작 로직 구현
            print("채팅 시작 로직 구현 필요")
        }
    }
}
// MARK: - 에러 타입 정의
enum ProfileUpdateError: Error, LocalizedError {
    case imageProcessingFailed
    case uploadFailed
    case nicknameUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "이미지 처리에 실패했습니다."
        case .uploadFailed:
            return "이미지 업로드에 실패했습니다."
        case .nicknameUpdateFailed:
            return "닉네임 업데이트에 실패했습니다."
        }
    }
}
