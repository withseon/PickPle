//
//  ProfileViewModel.swift
//  PickPle
//
//  Created by 정인선 on 6/7/25.
//

import Foundation
import Combine

final class UserProfileViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    private let postRepository: PostRepository
    private let user: UserInfo
    private var userPostsParam = UserPostsParam.empty

    init(postRepository: PostRepository, user: UserInfo) {
        self.postRepository = postRepository
        self.user = user
        super.init()
        transform()
    }
}

// MARK: - Input/Output
extension UserProfileViewModel {
    struct Input {
        let fetchDataTrigger = PassthroughSubject<Void, Never>()
        let selectTabTrigger = PassthroughSubject<ProfileTab, Never>()
    }

    struct Output {
        var profileImage = ""
        var nickname = ""
        var selectedTab: ProfileTab = .posts
        var posts = [PostThumbnail]()
    }

    func transform() {
        input.fetchDataTrigger
            .sink(with: self) { owner, _ in
                owner.output.profileImage = owner.user.profileImage ?? ""
                owner.output.nickname = owner.user.nickname
                owner.fetchPostData()
            }
            .store(in: &cancellables)
        
        input.selectTabTrigger
            .sink(with: self) { owner, tab in
                owner.output.selectedTab = tab
            }
            .store(in: &cancellables)
    }
    
    private func fetchPostData() {
        let publish = postRepository.userPosts(userPostsParam)
        publish
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

// MARK: - Action
extension UserProfileViewModel {
    enum Action {
        case fetchData
        case selectTab(_ tab: ProfileTab)
    }

    func action(_ action: Action) {
        switch action {
        case .fetchData:
            input.fetchDataTrigger
                .send(())
        case .selectTab(let tab):
            input.selectTabTrigger
                .send(tab)
        }
    }
}

