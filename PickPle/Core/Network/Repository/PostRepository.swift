//
//  PostRepository.swift
//  PickPle
//
//  Created by 정인선 on 6/11/25.
//

import Foundation
import Combine

protocol PostRepository {
    func postList(_ param: PostListParam) -> AnyPublisher<Result<PostSummaryListResponse, NetworkError>, Never>
    func userPosts(_ param: UserPostsParam) -> AnyPublisher<Result<PostSummaryListResponse, NetworkError>, Never>
    func postDetail(postId: String) -> AnyPublisher<Result<PostDetailResponse, NetworkError>, Never>
    func sendFile(files: [MultipartFile]) -> AnyPublisher<Result<PostFileResponse, NetworkError>, Never>
    func createPost(request: CreatePostRequest) -> AnyPublisher<Result<CreatePostResponse, NetworkError>, Never>
    func updatePost(postId: String, request: UpdatePostRequest) -> AnyPublisher<Result<CreatePostResponse, NetworkError>, Never>
    func deletePost(postId: String) -> AnyPublisher<Result<Void, NetworkError>, Never>
    func createComment(postId: String, request: CreateCommentRequest) -> AnyPublisher<Result<CommentResponse, NetworkError>, Never>
    func updateComment(postId: String, commentId: String, request: UpdateCommentRequest) -> AnyPublisher<Result<CommentResponse, NetworkError>, Never>
    func deleteComment(postId: String, commentId: String) -> AnyPublisher<Result<Void, NetworkError>, Never>
}

final class DefaultPostRepository: PostRepository {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func postList(_ param: PostListParam) -> AnyPublisher<Result<PostSummaryListResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self,
                      let latitude = UserDefaultsManager.selectedLocation?.latitude,
                      let longitude = UserDefaultsManager.selectedLocation?.longitude else { return }
                do {
                    let dto = PostSummaryRequest(
                        category: param.category?.title,
                        longitude: Float(longitude),
                        latitude: Float(latitude),
                        maxDistance: param.distance,
                        limit: param.limit,
                        next: param.next,
                        orderBy: param.orderBy?.rawValue)
                    let postList = try await networkManager.request(
                        target: PostRouter.posts(dto),
                        responseType: PostSummaryListResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(postList)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func userPosts(_ param: UserPostsParam) -> AnyPublisher<Result<PostSummaryListResponse, NetworkError>, Never> {
        print("👤 [PostRepository] userPosts 호출됨")
        
        return Future { promise in
            print("👤 [PostRepository] 전통적인 Alamofire 방식으로 변경")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            Task { [weak self] in
                guard let self else { return }
                do {
                    let dto = UserPostsRequest(
                        category: param.category,
                        limit: param.limit,
                        next: param.next,
                        userId: param.userId
                    )
                    let response = try await networkManager.request(
                        target: PostRouter.userPosts(dto),
                        responseType: PostSummaryListResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(response)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func postDetail(postId: String) -> AnyPublisher<Result<PostDetailResponse, NetworkError>, Never> {
        print("📄 [PostRepository] postDetail 호출됨 - postId: \(postId)")
        
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: PostRouter.postDetail(postId: postId),
                        responseType: PostDetailResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(response)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func sendFile(files: [MultipartFile]) -> AnyPublisher<Result<PostFileResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let chatFiles = try await networkManager.uploadMultipart(
                        target: PostRouter.sendFile,
                        fileData: files,
                        responseType: PostFileResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(chatFiles)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createPost(request: CreatePostRequest) -> AnyPublisher<Result<CreatePostResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: PostRouter.createPost(request),
                        responseType: CreatePostResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(response)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updatePost(postId: String, request: UpdatePostRequest) -> AnyPublisher<Result<CreatePostResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: PostRouter.updatePost(
                            postId: postId,
                            request: request
                        ),
                        responseType: CreatePostResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(response)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deletePost(postId: String) -> AnyPublisher<Result<Void, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let _ = try await networkManager.requestVoid(
                        target: PostRouter.deletePost(postId),
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(())))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createComment(postId: String, request: CreateCommentRequest) -> AnyPublisher<Result<CommentResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: PostRouter.createComment(postId: postId, request: request),
                        responseType: CommentResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(response)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateComment(postId: String, commentId: String, request: UpdateCommentRequest) -> AnyPublisher<Result<CommentResponse, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await networkManager.request(
                        target: PostRouter.updateComment(
                            postId: postId,
                            commentId: commentId,
                            request: request
                        ),
                        responseType: CommentResponse.self,
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(response)))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteComment(postId: String, commentId: String) -> AnyPublisher<Result<Void, NetworkError>, Never> {
        return Future { promise in
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await networkManager.requestVoid(
                        target: PostRouter.deleteComment(
                            postId: postId,
                            commentId: commentId
                        ),
                        errorType: UserErrorResponse.self
                    )
                    promise(.success(.success(())))
                } catch {
                    if case let NetworkError.server(serverError) = error {
                        promise(.success(.failure(.server(serverError))))
                    } else {
                        promise(.success(.failure(.unknown(error))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
