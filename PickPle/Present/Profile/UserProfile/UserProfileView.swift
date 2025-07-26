import SwiftUI
import PhotosUI

enum ProfileTab: String, CaseIterable {
    case posts = "게시글"
    case reviews = "리뷰"
}

struct UserProfileView: View {
    @StateObject var viewModel: UserProfileViewModel

    var body: some View {
        VStack {
            MainProfileView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.action(.fetchData)
        }
        .toolbar(viewModel.output.isCurrentUser ? .visible : .hidden, for: .tabBar)
        .handleErrors(viewModel: viewModel)
    }
}

struct MainProfileView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    ProfileInfoHeaderView(viewModel: viewModel)
                }
                
                Section {
                    switch viewModel.output.selectedTab {
                    case .posts:
                        PostsGridView(viewModel: viewModel)
                    case .reviews:
                        ReviewsListView()
                    }
                } header: {
                    TabSectionHeaderView(viewModel: viewModel)
                }
            }
        }
    }
}

struct TabSectionHeaderView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                VStack(spacing: 8) {
                    Text(tab.rawValue)
                        .font(.pretendard(.body1))
                        .foregroundStyle(viewModel.output.selectedTab == tab ? .blackSprout : .gray60)
                    
                    Rectangle()
                        .fill(viewModel.output.selectedTab == tab ? .deepSprout : .clear)
                        .frame(height: 2)
                }
                .wrapToButton {
                    viewModel.action(.selectTab(tab))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 20)
        .background(.gray0)
    }
}

struct PostsGridView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @EnvironmentObject var profileCoordinator: ProfileCoordinator

    var body: some View {
        if viewModel.output.posts.isEmpty {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    Text("게시글이 없습니다")
                        .font(.pretendard(.body3))
                        .foregroundStyle(.gray60)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height)
            }
            .frame(minHeight: UIScreen.main.bounds.height * 0.4)
        } else {
            LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
                ForEach(viewModel.output.posts, id: \.postId) { post in
                    NavigationLink(value: ProfileRoute.postDetail(post.postId)) {
                        GeometryReader { geometry in
                            if let postImage = post.mainImageUrl {
                                CachedImageView(imagePath: postImage, size: CGSize(width: geometry.size.width, height: geometry.size.width))
                            } else {
                                Rectangle()
                            }
                        }
                        .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
            .padding(.top, 16)
        }
    }
}

struct ReviewsListView: View {
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(0..<10) { item in
                ReviewItemView()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

struct ReviewItemView: View {
    var body: some View {
        VStack {
            
        }
    }
}

struct ProfileInfoHeaderView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)
            
            // 프로필 이미지 뷰 (업데이트 상태 포함)
            ProfileImageView(viewModel: viewModel)
            
            // 프로필 정보 뷰
            ProfileInfoView(viewModel: viewModel)
            
            // 버튼 영역
            if viewModel.output.isCurrentUser {
                CurrentUserButtonsView(viewModel: viewModel)
            } else {
                OtherUserButtonsView(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // ✅ 프로필뷰 - 캐시된 이미지 우선 사용
    private struct ProfileImageView: View {
        @ObservedObject var viewModel: UserProfileViewModel
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(.gray0)
                    .frame(width: 140, height: 140)
                    .overlay(Circle().stroke(.deepSprout))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // ✅ 프로필뷰: 캐시된 이미지 우선, 업데이트 중에만 임시 이미지 표시
                Group {
                    if viewModel.output.isUpdatingProfile, let temporaryImage = viewModel.output.temporaryProfileImage {
                        // 업데이트 중일 때만 임시 이미지 표시
                        Image(uiImage: temporaryImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else if !viewModel.output.profileImage.isEmpty {
                        // 저장된 프로필 이미지 (캐시된 이미지 우선)
                        CachedImageView(
                            imagePath: viewModel.output.profileImage,
                            size: CGSize(width: 100, height: 100)
                        )
                        .clipShape(Circle())
                    } else {
                        // 기본 이미지
                        Image("empty_profile")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    }
                }
                
                // 업데이트 중 인디케이터
                if viewModel.output.isUpdatingProfile {
                    Circle()
                        .fill(.black.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        )
                }
            }
        }
    }
    
    private struct ProfileInfoView: View {
        @ObservedObject var viewModel: UserProfileViewModel
        
        var body: some View {
            VStack(spacing: 12) {
                Text(viewModel.output.nickname)
                    .font(.pretendard(.title))
            }
        }
    }
}

// 현재 사용자용 버튼 (프로필 편집 통합)
struct CurrentUserButtonsView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @State private var showingEditSheet = false
    
    var body: some View {
        PrimaryButton("프로필 편집") {
            showingEditSheet = true
        }
        .disabled(viewModel.output.isUpdatingProfile) // 업데이트 중일 때 비활성화
        .sheet(isPresented: $showingEditSheet) {
            ProfileEditSheet(viewModel: viewModel)
        }
    }
}

// 타 사용자용 버튼
struct OtherUserButtonsView: View {
    @ObservedObject var viewModel: UserProfileViewModel
    
    var body: some View {
        PrimaryButton("채팅하기") {
            viewModel.action(.startChat)
        }
    }
}

// MARK: - 프로필 편집 시트
struct ProfileEditSheet: View {
    @ObservedObject var viewModel: UserProfileViewModel
    @State private var nickname: String = ""
    @State private var phoneNumber: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedImageData: (data: Data, fileName: String, previewImage: UIImage)?
    @State private var hasChanges: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 20) {
                    // 프로필 이미지 편집 섹션
                    profileImageSection
                    // 닉네임 편집 섹션
                    nicknameEditSection
                    // 핸드폰 번호 편집 섹션
                    phoneNumberEditSection
                    Spacer()
                }
                .padding(20)
                .navigationTitle("프로필 편집")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        cancelButton
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        saveButton
                    }
                }
            }
            .disabled(viewModel.output.isUpdatingProfile)
            
            // ✅ 시트 전체 기준 업데이트 인디케이터
            if viewModel.output.isUpdatingProfile {
                sheetUpdateOverlay
            }
        }
        .onAppear {
            // ✅ onAppear에서 초기값 설정
            nickname = viewModel.output.nickname
            phoneNumber = viewModel.output.phoneNumber
            print("🔍 ProfileEditSheet onAppear - nickname: '\(nickname)', phoneNumber: '\(phoneNumber)'")
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let newItem {
                    await loadSelectedImage(from: newItem)
                }
            }
        }
        .onChange(of: viewModel.output.isUpdatingProfile) { isUpdating in
            // 업데이트 완료 시 시트 닫기
            if !isUpdating && hasChanges {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        }
    }
    
    // ✅ 시트 전체 업데이트 오버레이
    private var sheetUpdateOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("업데이트 중...")
                        .font(.pretendard(.body1))
                        .foregroundStyle(.white)
                }
            )
    }
    
    // MARK: - Profile Image Section
    private var profileImageSection: some View {
        VStack(spacing: 16) {
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images
            ) {
                profileImageView
            }
            .disabled(viewModel.output.isUpdatingProfile)
            
            Text("사진을 탭해서 변경하세요")
                .font(.pretendard(.caption1))
                .foregroundStyle(.gray60)
        }
    }
    
    private var profileImageView: some View {
        ZStack {
            Circle()
                .fill(.gray0)
                .frame(width: 120, height: 120)
                .overlay(Circle().stroke(.deepSprout))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            profileImageContent
        }
    }
    
    @ViewBuilder
    private var profileImageContent: some View {
        // ✅ 편집 시트: 선택된 이미지를 Image로 즉시 표시, 기존 이미지는 CachedImageView 사용
        if let selectedImage = selectedImage {
            // 새로 선택된 이미지 (포토피커에서 선택된 UIImage)
            Image(uiImage: selectedImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
        } else if !viewModel.output.profileImage.isEmpty {
            // 기존 프로필 이미지 (캐시된 이미지)
            CachedImageView(
                imagePath: viewModel.output.profileImage,
                size: CGSize(width: 80, height: 80)
            )
            .clipShape(Circle())
        } else {
            // 기본 이미지
            Image("empty_profile")
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
        }
    }
    
    // MARK: - Nickname Edit Section
    private var nicknameEditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .font(.pretendard(.body1))
                .foregroundStyle(.blackSprout)
            ClearableTextField(
                "닉네임을 입력해주세요",
                text: $nickname,
                strokeColor: nicknameStrokeColor,
                errorMessage: viewModel.output.nicknameErrorMessage,
                limit: 15
            )
            .onChange(of: nickname) { newValue in
                viewModel.action(.validateNickname(newValue))
                checkForChanges()
            }
        }
    }
    
    // MARK: - Phone Number Edit Section
    private var phoneNumberEditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("휴대폰 번호")
                .font(.pretendard(.body1))
                .foregroundStyle(.blackSprout)
            ClearableTextField(
                "휴대폰 번호를 입력해주세요",
                text: $phoneNumber,
                strokeColor: phoneNumberStrokeColor,
                errorMessage: viewModel.output.phoneNumberErrorMessage,
                limit: 13
            )
            .keyboardType(.numberPad)
            .onChange(of: phoneNumber) { newValue in
                viewModel.action(.validatePhoneNum(phoneNumber))
                checkForChanges()
            }
        }
    }
    
    private var nicknameStrokeColor: Color {
        viewModel.output.nicknameErrorMessage.isEmpty ? .gray30 : .errorRed
    }
    
    private var phoneNumberStrokeColor: Color {
        viewModel.output.phoneNumberErrorMessage.isEmpty ? .gray30 : .errorRed
    }
    
    // MARK: - Toolbar Buttons
    private var cancelButton: some View {
        Button("취소") {
            dismiss()
        }
        .foregroundStyle(.gray60)
    }
    
    private var saveButton: some View {
        Button("저장") {
            saveChanges()
        }
        .foregroundStyle(saveButtonColor)
        .disabled(saveButtonDisabled)
    }
    
    private var saveButtonColor: Color {
        hasChanges ? .blackSprout : .gray60
    }
    
    private var saveButtonDisabled: Bool {
        !hasChanges || viewModel.output.isUpdatingProfile ||
        !viewModel.output.nicknameErrorMessage.isEmpty ||
        !viewModel.output.phoneNumberErrorMessage.isEmpty
    }
    
    @MainActor
    private func loadSelectedImage(from item: PhotosPickerItem) async {
        do {
            let data = try await item.loadTransferable(type: Data.self)
            
            if let data = data {
                // 파일명 추출 (supportedContentTypes에서 추론)
                let fileName = item.supportedContentTypes.first?.preferredFilenameExtension.map { "profile.\($0)" } ?? "profile.jpg"
                
                // 미리보기용 다운샘플링
                let previewImage = ImageProcessingManager.shared.downsampleForDisplay(
                    data: data,
                    pointSize: CGSize(width: 200, height: 200),
                    scale: UIScreen.main.scale
                )
                
                // UI 즉시 업데이트
                selectedImage = previewImage
                
                // 원본 데이터 저장 (저장 버튼 클릭 시 사용)
                selectedImageData = (data: data, fileName: fileName, previewImage: previewImage ?? UIImage())
                
                checkForChanges()
            }
        } catch {
            print("이미지 로딩 실패: \(error)")
        }
    }
    
    private func checkForChanges() {
        let nicknameChanged = !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                             nickname.trimmingCharacters(in: .whitespacesAndNewlines) != viewModel.output.nickname
        let phoneNumberChanged = !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                                phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines) != viewModel.output.phoneNumber
        let imageChanged = selectedImageData != nil
        
        hasChanges = nicknameChanged || phoneNumberChanged || imageChanged
        
        print("🔍 변경사항 체크 - 닉네임: \(nicknameChanged), 폰번호: \(phoneNumberChanged), 이미지: \(imageChanged)")
    }
    
    private func saveChanges() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 프로필 이미지 변경
        if let imageData = selectedImageData {
            // 임시 이미지로 즉시 UI 업데이트
            viewModel.output.temporaryProfileImage = imageData.previewImage
            viewModel.action(.updateProfileImage(data: imageData.data, fileName: imageData.fileName, previewImage: imageData.previewImage))
        }
        
        // 닉네임 변경
        if !trimmedNickname.isEmpty && trimmedNickname != viewModel.output.nickname {
            viewModel.action(.updateNickname(trimmedNickname))
        }
        
        // 핸드폰 번호 변경
        if !trimmedPhoneNumber.isEmpty && trimmedPhoneNumber != viewModel.output.phoneNumber {
            viewModel.action(.updatePhoneNum(trimmedPhoneNumber))
        }
        
        // 변경사항이 있으면 업데이트 상태로 전환
        if hasChanges {
            viewModel.output.isUpdatingProfile = true
        }
    }
}

