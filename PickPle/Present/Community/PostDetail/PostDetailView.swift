//
//  PostDetailView.swift
//  PickPle
//
//  Created by Claude on 8/17/25.
//

import SwiftUI

struct PostDetailView: View {
    @StateObject var viewModel: PostDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var communityCoordinator: CommunityCoordinator
    
    var body: some View {
        ZStack {
            if viewModel.output.isLoading {
                ProgressView("게시글을 불러오는 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let postDetail = viewModel.output.postDetail {
                ScrollView {
                    VStack(spacing: 12) {
                        // 게시글 헤더
                        PostHeaderView(postDetail: postDetail, viewModel: viewModel)
                            .padding(.horizontal, 20)
                        
                        if viewModel.hasImages {
                            ImageCarouselView(
                                imageUrls: postDetail.files,
                                height: 250,
                                indicatorBottomPadding: 12,
                                enableImageViewer: true
                            )
                        }
                        
                        // 게시글 내용
                        PostContentView(postDetail: postDetail)
                            .padding(.horizontal, 20)
                        
                        // 매장 정보 (다운샘플링 적용)
                        if let store = postDetail.store {
                            PostStoreInfoView(store: store)
                        }
                        
                        Divider()
                        
                        // 좋아요 및 댓글 수
                        PostEngagementView(viewModel: viewModel)
                        
                        Divider()
                            .padding(.vertical, 16)
                        
                        // 댓글 섹션 (프로필 이미지 다운샘플링 적용)
                        PostCommentsView(
                            comments: postDetail.comments,
                            viewModel: viewModel
                        )
                    }
                    .padding(.bottom, 100) // 댓글 입력창 공간 확보
                }
                .refreshable {
                    //데이터 새로고침
                    await refreshData()
                }
            } else {
                // iOS 16 호환: ContentUnavailableView 대신 커스텀 뷰 사용
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("게시글을 불러올 수 없습니다")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("네트워크 연결을 확인하고 다시 시도해주세요.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("다시 시도") {
                        viewModel.action(.refreshData)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("게시글")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if let creatorId = viewModel.output.postDetail?.creator.userId,
               creatorId == UserDefaultsManager.userId {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            if let postDetail = viewModel.output.postDetail {
                                communityCoordinator.push(.editPost(postDetail))
                            }
                        } label: {
                            Label("수정", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.output.showDeletePost = true
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            viewModel.action(.fetchPostDetail)
        }
        .alert("게시글 삭제", isPresented: $viewModel.output.showDeletePost) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                viewModel.action(.deletePost)
            }
        } message: {
            Text("게시글을 삭제하시겠습니까?")
        }
        .alert("오류", isPresented: $viewModel.output.showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.output.errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .onChange(of: viewModel.output.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .handleErrors(viewModel: viewModel)
    }
    
    // Pull to refresh를 위한 async 함수
    private func refreshData() async {
        return await withCheckedContinuation { continuation in
            viewModel.action(.refreshData)
            // 데이터 로딩 완료까지 대기
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                continuation.resume()
            }
        }
    }
}

// MARK: - PostHeaderView (CachedImageView 사용)
struct PostHeaderView: View {
    let postDetail: PostDetail
    let viewModel: PostDetailViewModel
    @EnvironmentObject var communityCoordinator: CommunityCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 카테고리 태그
            Text(postDetail.category)
                .font(.pretendard(.caption1))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.brightSprout)
                .foregroundColor(.blackSprout)
                .cornerRadius(8)
            
            // 제목
            Text(postDetail.title)
                .font(.pretendard(.title))
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
            
            // 작성자 정보 - 클릭 가능
            HStack(spacing: 4) {
                // 프로필 이미지 - CachedImageView 사용 (다운샘플링 자동 적용)
                if let profileImage = postDetail.creator.profileImage {
                    CachedImageView(
                        imagePath: profileImage,
                        size: CGSize(width: 28, height: 28),
                        contentMode: .fill
                    )
                    .clipShape(Circle())
                } else {
                    Image("empty_profile")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(postDetail.creator.nickname)
                        .font(.pretendard(.body3))

                    HStack(spacing: 2) {
                        Text(postDetail.createdAtFormatted)
                            .font(.pretendard(.caption2))
                            .foregroundColor(.gray60)
                        
                        if postDetail.createdAt != postDetail.updatedAt {
                            Text("(수정됨)")
                                .font(.pretendard(.caption1))
                                .foregroundColor(.gray60)
                        }
                    }
                }

                Spacer()
            }
            .onTapGesture {
                // 현재 사용자가 아닌 경우에만 프로필로 이동
                if postDetail.creator.userId != UserDefaultsManager.userId {
                    communityCoordinator.push(.profile(postDetail.creator.userId, nickname: postDetail.creator.nickname, profileImage: postDetail.creator.profileImage))
                }
            }
        }
    }
}

// MARK: - PostContentView
struct PostContentView: View {
    let postDetail: PostDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(postDetail.content)
                .font(.body)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - PostStoreInfoView (CachedImageView 사용)
struct PostStoreInfoView: View {
    let store: PostDetail.Store
    @State private var addressText: String?

    var storeInfo: String {
        var info = store.category
        if let address = addressText {
            info += " • \(address)"
        }
        return info
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("매장 정보")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 0) {
                // 매장 이미지 - CachedImageView 사용 (다운샘플링 자동 적용)
                if let firstImage = store.storeImageUrls.first {
                    CachedImageView(
                        imagePath: firstImage,
                        size: CGSize(width: 100, height: 100),
                        contentMode: .fill
                    )
                    .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(store.name)
                            .font(.pretendard(.body2))

                        Spacer()

                        if store.isPicchelin {
                            PickChelinTagView()
                        }
                    }

                    HStack {
                        Text(storeInfo)
                            .font(.pretendard(.caption2))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Spacer()

                        HStack(spacing: 4) {
                            Image("star.fill")
                                .iconFrame(12)
                                .foregroundColor(.yellow)
                            Text(store.totalRatingFormatted)
                                .font(.pretendard(.caption1))
                                .fontWeight(.medium)
                        }
                    }

                    Spacer()

                    // 해시태그
                    if !store.hashTags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(store.hashTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.pretendard(.caption2))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.brightSprout)
                                    .foregroundColor(.blackSprout)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .frame(height: 100)
            }
        }
        .onAppear {
            loadAddress()
        }
    }

    private func loadAddress() {
        GeocodingService.shared.convertToAddress(
            latitude: store.geolocation.latitude,
            longitude: store.geolocation.longitude
        ) { result in
            switch result {
            case .success(let address):
                DispatchQueue.main.async {
                    self.addressText = address
                }
            case .failure:
                // 주소 변환 실패 시 addressText는 nil로 유지 (카테고리만 표시)
                break
            }
        }
    }
}

// MARK: - PostEngagementView
struct PostEngagementView: View {
    @ObservedObject var viewModel: PostDetailViewModel
    
    var body: some View {
        HStack(spacing: 24) {
            // 좋아요 버튼
            Button {
                viewModel.action(.toggleLike)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.output.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.output.isLiked ? .red : .gray)
                    Text("\(viewModel.output.likeCount)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            
            // 댓글 수
            HStack(spacing: 4) {
                Image(systemName: "bubble.left")
                    .foregroundColor(.gray)
                Text("\(viewModel.commentsCount)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - PostCommentsView
struct PostCommentsView: View {
    let comments: [PostDetail.Comment]
    @ObservedObject var viewModel: PostDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("댓글 \(totalCommentsCount)")
                .font(.headline)
                .fontWeight(.semibold)
            
            // 일반 댓글 입력, 대댓글 입력, 또는 댓글 수정 모드
            if let editingCommentId = viewModel.output.editingCommentId {
                // 댓글 수정 모드
                CommentEditView(
                    editText: $viewModel.output.editCommentText,
                    isSubmitting: viewModel.output.isSubmittingEdit,
                    onSave: { 
                        viewModel.action(.saveEditComment(commentId: editingCommentId, content: viewModel.output.editCommentText))
                    },
                    onCancel: { viewModel.action(.cancelEditComment) }
                )
            } else if let replyingToCommentId = viewModel.output.replyingToCommentId {
                // 대댓글 입력 모드
                let replyingComment = comments.first { $0.commentId == replyingToCommentId }
                ReplyInputView(
                    replyingToUser: replyingComment?.creator.nickname ?? "",
                    replyText: $viewModel.output.replyText,
                    isSubmitting: viewModel.output.isSubmittingReply,
                    onSubmit: { 
                        viewModel.action(.addReply(commentId: replyingToCommentId, content: viewModel.output.replyText))
                    },
                    onCancel: { viewModel.action(.cancelReply) }
                )
            } else {
                // 일반 댓글 입력 모드
                CommentInputView(
                    text: $viewModel.output.newCommentText,
                    isSubmitting: viewModel.output.isSubmittingComment,
                    onSubmit: { 
                        viewModel.action(.addComment(viewModel.output.newCommentText))
                    }
                )
            }
            
            // 댓글 목록
            ForEach(comments, id: \.commentId) { comment in
                CommentItemView(
                    comment: comment,
                    viewModel: viewModel,
                    onReplyTap: { viewModel.action(.startReply(commentId: comment.commentId)) },
                    onEditTap: { viewModel.action(.startEditComment(commentId: comment.commentId, currentText: comment.content)) },
                    onDeleteTap: {
                        // 삭제 확인 알림 후 실행
                        showDeleteConfirmation(for: comment.commentId)
                    }
                )
                
                // 대댓글
                if !comment.replies.isEmpty {
                    ForEach(comment.replies, id: \.commentId) { reply in
                        CommentReplyView(
                            reply: reply,
                            viewModel: viewModel,
                            onEditTap: { viewModel.action(.startEditComment(commentId: reply.commentId, currentText: reply.content)) },
                            onDeleteTap: {
                                showDeleteConfirmation(for: reply.commentId)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var totalCommentsCount: Int {
        comments.reduce(0) { count, comment in
            count + 1 + comment.replies.count
        }
    }
    
    private func showDeleteConfirmation(for commentId: String) {
        // iOS에서 기본 Alert를 사용하여 삭제 확인
        let alert = UIAlertController(
            title: "댓글 삭제",
            message: "정말로 이 댓글을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { _ in
            viewModel.action(.deleteComment(commentId: commentId))
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - CommentInputView
struct CommentInputView: View {
    @Binding var text: String
    let isSubmitting: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            TextField("댓글을 입력하세요...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3)
            
            Button {
                onSubmit()
            } label: {
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        }
    }
}

// MARK: - CommentEditView
struct CommentEditView: View {
    @Binding var editText: String
    let isSubmitting: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 수정 모드 표시
            HStack {
                Text("댓글 수정")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
                
                Button("취소") {
                    onCancel()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            // 수정 입력창
            HStack(spacing: 8) {
                TextField("댓글을 수정하세요...", text: $editText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3)
                
                Button {
                    onSave()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                    }
                }
                .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - CommentItemView (CachedImageView 사용)
struct CommentItemView: View {
    let comment: PostDetail.Comment
    let viewModel: PostDetailViewModel
    let onReplyTap: () -> Void
    let onEditTap: () -> Void
    let onDeleteTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                // 프로필 이미지 - CachedImageView 사용 (다운샘플링 자동 적용)
                if let profileImage = comment.creator.profileImage {
                    CachedImageView(
                        imagePath: profileImage,
                        size: CGSize(width: 32, height: 32),
                        contentMode: .fill
                    )
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(comment.creator.nickname)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(comment.createdAtFormatted)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(comment.content)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // 액션 버튼들
            HStack {
                Spacer()
                
                // 답글 버튼
                Button {
                    onReplyTap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.caption)
                        Text("답글")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                // 현재 사용자가 작성한 댓글인 경우 수정/삭제 버튼 표시
                if viewModel.isCurrentUserComment(comment) {
                    Button {
                        onEditTap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.caption)
                            Text("수정")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Button {
                        onDeleteTap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.caption)
                            Text("삭제")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ReplyInputView
struct ReplyInputView: View {
    let replyingToUser: String
    @Binding var replyText: String
    let isSubmitting: Bool
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 답글 대상 표시
            HStack {
                Text("@\(replyingToUser)님에게 답글")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
                
                Button("취소") {
                    onCancel()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            // 입력창
            HStack(spacing: 8) {
                TextField("답글을 입력하세요...", text: $replyText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3)
                
                Button {
                    onSubmit()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                    }
                }
                .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - CommentReplyView (CachedImageView 사용)
struct CommentReplyView: View {
    let reply: PostDetail.Comment.CommentReply
    let viewModel: PostDetailViewModel
    let onEditTap: () -> Void
    let onDeleteTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                // 대댓글 인디케이터
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
                
                // 프로필 이미지 - CachedImageView 사용 (다운샘플링 자동 적용)
                if let profileImage = reply.creator.profileImage {
                    CachedImageView(
                        imagePath: profileImage,
                        size: CGSize(width: 28, height: 28),
                        contentMode: .fill
                    )
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(reply.creator.nickname)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        // 작성자 표시
                        if viewModel.isCurrentUserReply(reply) {
                            Text("작성자")
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Text(reply.createdAtFormatted)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(reply.content)
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // 현재 사용자가 작성한 대댓글인 경우 수정/삭제 버튼 표시
            if viewModel.isCurrentUserReply(reply) {
                HStack {
                    Spacer()
                    
                    Button {
                        onEditTap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.caption2)
                            Text("수정")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Button {
                        onDeleteTap()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.caption2)
                            Text("삭제")
                                .font(.caption2)
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.leading, 16)
        .padding(.vertical, 2)
    }
}
