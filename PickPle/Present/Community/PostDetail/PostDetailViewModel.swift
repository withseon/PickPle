//
//  PostDetailViewModel.swift
//  PickPle
//
//  Created by Claude on 8/17/25.
//

import Foundation
import SwiftUI
import Combine

final class PostDetailViewModel: BaseViewModel, ViewModelType {
    // MARK: - Input/Output
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private Properties
    private let postRepository: PostRepository
    private let postId: String
    
    init(postId: String, postRepository: PostRepository) {
        self.postId = postId
        self.postRepository = postRepository
        super.init()
        transform()
    }
}

// MARK: - Input/Output
extension PostDetailViewModel {
    struct Input {
        let fetchPostDetailTrigger = PassthroughSubject<Void, Never>()
        let toggleLikeTrigger = PassthroughSubject<Void, Never>()
        let addCommentTrigger = PassthroughSubject<String, Never>()
        let startReplyTrigger = PassthroughSubject<String, Never>()
        let addReplyTrigger = PassthroughSubject<(commentId: String, content: String), Never>()
        let cancelReplyTrigger = PassthroughSubject<Void, Never>()
        let startEditCommentTrigger = PassthroughSubject<(commentId: String, currentText: String), Never>()
        let saveEditCommentTrigger = PassthroughSubject<(commentId: String, content: String), Never>()
        let cancelEditCommentTrigger = PassthroughSubject<Void, Never>()
        let deleteCommentTrigger = PassthroughSubject<String, Never>()
        let deletePostTrigger = PassthroughSubject<Void, Never>()
        let refreshDataTrigger = PassthroughSubject<Void, Never>()
    }
    
    struct Output {
        var postDetail: PostDetail?
        var isLoading = false
        var errorMessage: String?
        var showError = false
        var showDeletePost = false
        var shouldDismiss = false
        
        // 댓글 관련
        var newCommentText = ""
        var isSubmittingComment = false
        
        // 대댓글 관련
        var replyingToCommentId: String?
        var replyText = ""
        var isSubmittingReply = false
        
        // 댓글 수정/삭제 관련
        var editingCommentId: String?
        var editCommentText = ""
        var isSubmittingEdit = false
        var isDeletingComment = false
        
        // 좋아요 관련
        var isLiked = false
        var likeCount = 0
    }
    
    func transform() {
        input.fetchPostDetailTrigger
            .sink(with: self) { owner, _ in
                owner.fetchPostDetail()
            }
            .store(in: &cancellables)
        
        input.toggleLikeTrigger
            .sink(with: self) { owner, _ in
                owner.toggleLike()
            }
            .store(in: &cancellables)
        
        input.addCommentTrigger
            .sink(with: self) { owner, content in
                owner.output.newCommentText = content
                owner.addComment()
            }
            .store(in: &cancellables)
        
        input.startReplyTrigger
            .sink(with: self) { owner, commentId in
                owner.startReply(to: commentId)
            }
            .store(in: &cancellables)
        
        input.addReplyTrigger
            .sink(with: self) { owner, data in
                owner.output.replyText = data.content
                owner.addReply(to: data.commentId)
            }
            .store(in: &cancellables)
        
        input.cancelReplyTrigger
            .sink(with: self) { owner, _ in
                owner.cancelReply()
            }
            .store(in: &cancellables)
        
        input.startEditCommentTrigger
            .sink(with: self) { owner, data in
                owner.startEditComment(commentId: data.commentId, currentText: data.currentText)
            }
            .store(in: &cancellables)
        
        input.saveEditCommentTrigger
            .sink(with: self) { owner, data in
                owner.output.editCommentText = data.content
                owner.saveEditComment(commentId: data.commentId)
            }
            .store(in: &cancellables)
        
        input.cancelEditCommentTrigger
            .sink(with: self) { owner, _ in
                owner.cancelEditComment()
            }
            .store(in: &cancellables)
        
        input.deleteCommentTrigger
            .sink(with: self) { owner, commentId in
                owner.deleteComment(commentId: commentId)
            }
            .store(in: &cancellables)
        
        input.deletePostTrigger
            .sink(with: self) { owner, _ in
                owner.deletePost()
            }
            .store(in: &cancellables)
        
        
        input.refreshDataTrigger
            .sink(with: self) { owner, _ in
                owner.refreshData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private Methods
private extension PostDetailViewModel {
    func fetchPostDetail() {
        print("🔥 [PostDetailViewModel] 게시글 상세 조회 시작 - postId: \(postId)")
        
        output.isLoading = true
        output.errorMessage = nil
        
        postRepository.postDetail(postId: postId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.output.isLoading = false
                
                switch result {
                case .success(let response):
                    print("✅ [PostDetailViewModel] 게시글 상세 조회 성공")
                    let postDetailEntity = response.asPostDetail
                    self?.output.postDetail = postDetailEntity
                    self?.output.isLiked = postDetailEntity.isLike
                    self?.output.likeCount = postDetailEntity.likeCount
                case .failure(let error):
                    print("❌ [PostDetailViewModel] 게시글 상세 조회 실패: \(error)")
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    func toggleLike() {
        // TODO: 좋아요 API 연동
        print("❤️ [PostDetailViewModel] 좋아요 토글")
        
        output.isLiked.toggle()
        output.likeCount += output.isLiked ? 1 : -1
    }
    
    func addComment() {
        guard !output.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        print("💬 [PostDetailViewModel] 댓글 추가 시작")
        
        output.isSubmittingComment = true
        
        let commentRequest = CreateCommentRequest(parentCommentId: nil, content: output.newCommentText)
        
        postRepository.createComment(postId: postId, request: commentRequest)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.output.isSubmittingComment = false
                
                switch result {
                case .success(let commentResponse):
                    print("✅ [PostDetailViewModel] 댓글 추가 성공")
                    self?.output.newCommentText = ""
                    // 로컬 상태에 새 댓글 추가 (스크롤 위치 보존)
                    self?.addCommentToLocalState(commentResponse)
                case .failure(let error):
                    print("❌ [PostDetailViewModel] 댓글 추가 실패: \(error)")
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    func startReply(to commentId: String) {
        print("💭 [PostDetailViewModel] 대댓글 작성 시작 - commentId: \(commentId)")
        output.replyingToCommentId = commentId
        output.replyText = ""
    }
    
    func cancelReply() {
        print("❌ [PostDetailViewModel] 대댓글 작성 취소")
        output.replyingToCommentId = nil
        output.replyText = ""
    }
    
    func addReply(to commentId: String) {
        guard !output.replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        print("💬 [PostDetailViewModel] 대댓글 추가 시작 - parentId: \(commentId)")
        
        output.isSubmittingReply = true
        
        let replyRequest = CreateCommentRequest(parentCommentId: commentId, content: output.replyText)
        
        postRepository.createComment(postId: postId, request: replyRequest)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.output.isSubmittingReply = false
                
                switch result {
                case .success(let commentResponse):
                    print("✅ [PostDetailViewModel] 대댓글 추가 성공")
                    self?.output.replyText = ""
                    let parentCommentId = self?.output.replyingToCommentId
                    self?.output.replyingToCommentId = nil
                    // 로컬 상태에 새 대댓글 추가 (스크롤 위치 보존)
                    if let parentId = parentCommentId {
                        self?.addReplyToLocalState(commentResponse, parentCommentId: parentId)
                    }
                case .failure(let error):
                    print("❌ [PostDetailViewModel] 대댓글 추가 실패: \(error)")
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    func refreshData() {
        print("🔄 [PostDetailViewModel] 데이터 새로고침")
        fetchPostDetail()
    }
    
    func startEditComment(commentId: String, currentText: String) {
        print("✏️ [PostDetailViewModel] 댓글 수정 시작 - commentId: \(commentId)")
        output.editingCommentId = commentId
        output.editCommentText = currentText
        // 다른 모드들 취소
        output.replyingToCommentId = nil
        output.replyText = ""
    }
    
    func cancelEditComment() {
        print("❌ [PostDetailViewModel] 댓글 수정 취소")
        output.editingCommentId = nil
        output.editCommentText = ""
    }
    
    func saveEditComment(commentId: String) {
        guard !output.editCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        print("💾 [PostDetailViewModel] 댓글 수정 저장 시작 - commentId: \(commentId)")
        
        output.isSubmittingEdit = true
        
        let updateRequest = UpdateCommentRequest(content: output.editCommentText)
        
        postRepository.updateComment(postId: postId, commentId: commentId, request: updateRequest)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.output.isSubmittingEdit = false
                
                switch result {
                case .success(let commentResponse):
                    print("✅ [PostDetailViewModel] 댓글 수정 성공")
                    self?.output.editingCommentId = nil
                    self?.output.editCommentText = ""
                    // 로컬 상태 업데이트
                    self?.updateCommentInLocalState(commentResponse)
                case .failure(let error):
                    print("❌ [PostDetailViewModel] 댓글 수정 실패: \(error)")
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    func deleteComment(commentId: String) {
        print("🗑️ [PostDetailViewModel] 댓글 삭제 시작 - commentId: \(commentId)")
        
        output.isDeletingComment = true
        
        postRepository.deleteComment(postId: postId, commentId: commentId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.output.isDeletingComment = false
                
                switch result {
                case .success:
                    print("✅ [PostDetailViewModel] 댓글 삭제 성공")
                    // 로컬 상태에서 댓글 제거
                    self?.removeCommentFromLocalState(commentId: commentId)
                case .failure(let error):
                    print("❌ [PostDetailViewModel] 댓글 삭제 실패: \(error)")
                    self?.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    func addCommentToLocalState(_ commentResponse: CommentResponse) {
        guard var currentPostDetail = output.postDetail else { return }
        
        // CommentResponse를 PostDetail.Comment로 변환
        let newComment = PostDetail.Comment(
            commentId: commentResponse.commentId,
            content: commentResponse.content,
            createdAt: commentResponse.createdAt,
            createdAtFormatted: FormatHelper.shared.formatCommentDateTime(commentResponse.createdAt),
            creator: UserInfo(
                userId: commentResponse.creator.userId,
                nickname: commentResponse.creator.nick,
                profileImage: commentResponse.creator.profileImage
            ),
            replies: []
        )
        
        // var로 선언된 필드들을 직접 수정
        currentPostDetail.comments.append(newComment)
        currentPostDetail.commentsCount += 1
        
        self.output.postDetail = currentPostDetail
        
        print("📱 [PostDetailViewModel] 로컬 상태에 댓글 추가 완료")
    }
    
    func addReplyToLocalState(_ commentResponse: CommentResponse, parentCommentId: String) {
        guard var currentPostDetail = output.postDetail else { return }
        
        // CommentResponse를 PostDetail.CommentReply로 변환
        let newReply = PostDetail.Comment.CommentReply(
            commentId: commentResponse.commentId,
            content: commentResponse.content,
            createdAt: commentResponse.createdAt,
            createdAtFormatted: FormatHelper.shared.formatCommentDateTime(commentResponse.createdAt),
            creator: UserInfo(
                userId: commentResponse.creator.userId,
                nickname: commentResponse.creator.nick,
                profileImage: commentResponse.creator.profileImage
            )
        )
        
        // 부모 댓글을 찾아서 대댓글 추가
        if let parentIndex = currentPostDetail.comments.firstIndex(where: { $0.commentId == parentCommentId }) {
            // var로 선언된 replies 배열에 직접 추가
            currentPostDetail.comments[parentIndex].replies.append(newReply)
            currentPostDetail.commentsCount += 1
            
            self.output.postDetail = currentPostDetail
            
            print("📱 [PostDetailViewModel] 로컬 상태에 대댓글 추가 완료 - parentId: \(parentCommentId)")
        }
    }
    
    func updateCommentInLocalState(_ commentResponse: CommentResponse) {
        guard var currentPostDetail = output.postDetail else { return }
        
        // 일반 댓글 업데이트 확인
        if let commentIndex = currentPostDetail.comments.firstIndex(where: { $0.commentId == commentResponse.commentId }) {
            // 기존 댓글의 replies는 유지하면서 내용만 업데이트
            let existingReplies = currentPostDetail.comments[commentIndex].replies
            
            currentPostDetail.comments[commentIndex] = PostDetail.Comment(
                commentId: commentResponse.commentId,
                content: commentResponse.content,
                createdAt: commentResponse.createdAt,
                createdAtFormatted: FormatHelper.shared.formatCommentDateTime(commentResponse.createdAt),
                creator: UserInfo(
                    userId: commentResponse.creator.userId,
                    nickname: commentResponse.creator.nick,
                    profileImage: commentResponse.creator.profileImage
                ),
                replies: existingReplies
            )
            
            self.output.postDetail = currentPostDetail
            print("📱 [PostDetailViewModel] 댓글 수정 로컬 상태 업데이트 완료")
            return
        }
        
        // 대댓글 업데이트 확인
        for commentIndex in currentPostDetail.comments.indices {
            if let replyIndex = currentPostDetail.comments[commentIndex].replies.firstIndex(where: { $0.commentId == commentResponse.commentId }) {
                currentPostDetail.comments[commentIndex].replies[replyIndex] = PostDetail.Comment.CommentReply(
                    commentId: commentResponse.commentId,
                    content: commentResponse.content,
                    createdAt: commentResponse.createdAt,
                    createdAtFormatted: FormatHelper.shared.formatCommentDateTime(commentResponse.createdAt),
                    creator: UserInfo(
                        userId: commentResponse.creator.userId,
                        nickname: commentResponse.creator.nick,
                        profileImage: commentResponse.creator.profileImage
                    )
                )
                
                self.output.postDetail = currentPostDetail
                print("📱 [PostDetailViewModel] 대댓글 수정 로컬 상태 업데이트 완료")
                return
            }
        }
    }
    
    func removeCommentFromLocalState(commentId: String) {
        guard var currentPostDetail = output.postDetail else { return }
        
        // 일반 댓글 삭제 확인
        if let commentIndex = currentPostDetail.comments.firstIndex(where: { $0.commentId == commentId }) {
            let removedComment = currentPostDetail.comments.remove(at: commentIndex)
            // 해당 댓글과 대댓글 수만큼 전체 댓글 수에서 차감
            let removedCount = 1 + removedComment.replies.count
            currentPostDetail.commentsCount -= removedCount
            
            self.output.postDetail = currentPostDetail
            print("📱 [PostDetailViewModel] 댓글 삭제 로컬 상태 업데이트 완료 - 제거된 댓글 수: \(removedCount)")
            return
        }
        
        // 대댓글 삭제 확인
        for commentIndex in currentPostDetail.comments.indices {
            if let replyIndex = currentPostDetail.comments[commentIndex].replies.firstIndex(where: { $0.commentId == commentId }) {
                currentPostDetail.comments[commentIndex].replies.remove(at: replyIndex)
                currentPostDetail.commentsCount -= 1
                
                self.output.postDetail = currentPostDetail
                print("📱 [PostDetailViewModel] 대댓글 삭제 로컬 상태 업데이트 완료")
                return
            }
        }
    }
    
    func deletePost() {
        print("🗑️ [PostDetailViewModel] 게시글 삭제 시작 - postId: \(postId)")
        
        // 삭제할 파일 목록 수집 (캐시 삭제용)
        let filesToClear = output.postDetail?.files ?? []
        
        let publish = postRepository.deletePost(postId: postId)
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success:
                    print("✅ [PostDetailViewModel] 게시글 삭제 성공")
                    
                    // 서버 삭제 성공 시 관련 파일 캐시 삭제
                    if !filesToClear.isEmpty {
                        print("🗑️ [PostDetailViewModel] 삭제된 게시물의 파일 캐시 정리 시작: \(filesToClear.count)개")
                        UnifiedMediaCacheManager.shared.clearCacheForFiles(filesToClear)
                    }
                    
                    // 게시글 삭제 알림 전송
                    NotificationCenter.default.post(
                        name: Notification.Name("PostDeleted"),
                        object: owner.postId
                    )
                    print("📝 [PostDetailViewModel] 게시글 삭제 알림 전송: \(owner.postId)")
                    
                    owner.output.shouldDismiss = true
                case .failure(let error):
                    print("❌ [PostDetailViewModel] 게시글 삭제 실패: \(error)")
                    owner.handleError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    func handleError(_ error: NetworkError) {
        // BaseViewModel의 공통 에러 처리 사용
        handleNetworkError(error)
    }
}

// MARK: - Helper Methods
extension PostDetailViewModel {
    var formattedCreatedDate: String {
        return output.postDetail?.createdAtFormatted ?? ""
    }
    
    var hasImages: Bool {
        return output.postDetail?.hasImages ?? false
    }
    
    var commentsCount: Int {
        return output.postDetail?.commentsCount ?? 0
    }
    
    /// 현재 사용자가 작성한 댓글인지 확인
    func isCurrentUserComment(_ comment: PostDetail.Comment) -> Bool {
        guard let currentUserId = UserDefaultsManager.userId else { return false }
        return comment.creator.userId == currentUserId
    }
    
    /// 현재 사용자가 작성한 대댓글인지 확인
    func isCurrentUserReply(_ reply: PostDetail.Comment.CommentReply) -> Bool {
        guard let currentUserId = UserDefaultsManager.userId else { return false }
        return reply.creator.userId == currentUserId
    }
}


// MARK: - Action
extension PostDetailViewModel {
    enum Action {
        case fetchPostDetail
        case toggleLike
        case addComment(String)
        case addReply(commentId: String, content: String)
        case startReply(commentId: String)
        case cancelReply
        case refreshData
        case startEditComment(commentId: String, currentText: String)
        case saveEditComment(commentId: String, content: String)
        case cancelEditComment
        case deleteComment(commentId: String)
        case deletePost
    }
    
    func action(_ action: Action) {
        switch action {
        case .fetchPostDetail:
            input.fetchPostDetailTrigger.send()
        case .toggleLike:
            input.toggleLikeTrigger.send()
        case .addComment(let content):
            input.addCommentTrigger.send(content)
        case .addReply(let commentId, let content):
            input.addReplyTrigger.send((commentId: commentId, content: content))
        case .startReply(let commentId):
            input.startReplyTrigger.send(commentId)
        case .cancelReply:
            input.cancelReplyTrigger.send()
        case .refreshData:
            input.refreshDataTrigger.send()
        case .startEditComment(let commentId, let currentText):
            input.startEditCommentTrigger.send((commentId: commentId, currentText: currentText))
        case .saveEditComment(let commentId, let content):
            input.saveEditCommentTrigger.send((commentId: commentId, content: content))
        case .cancelEditComment:
            input.cancelEditCommentTrigger.send()
        case .deleteComment(let commentId):
            input.deleteCommentTrigger.send(commentId)
        case .deletePost:
            input.deletePostTrigger.send()
        }
    }
}
