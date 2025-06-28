//
//  ProfileView.swift
//  PickPle
//
//  Created by 정인선 on 6/7/25.
//

import SwiftUI

enum ProfileTab: String, CaseIterable {
    case posts = "게시글"
    case reviews = "리뷰"
}

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel
    var body: some View {
        VStack {
            MainProfileView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.action(.fetchData)
        }
    }
}

struct MainProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
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
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { tab in
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.pretendard(.body1))
                            .foregroundColor(viewModel.output.selectedTab == tab ? .blackSprout : .gray60)
                        
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
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(.gray0)
    }
}

struct PostsGridView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        if viewModel.output.posts.isEmpty {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    Text("게시글이 없습니다.")
                        .font(.pretendard(.body1))
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
                    GeometryReader { geometry in
                        if let postImage = post.mainImageUrl {
                            CachedAsyncImage(
                                path: postImage,
                                width: geometry.size.width,
                                height: geometry.size.width
                            )
                        } else {
                            Rectangle()
                        }
                    }
                    .aspectRatio(1, contentMode: .fill)
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
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            ProfileImageView(viewModel: viewModel)
            ProfileInfoView(viewModel: viewModel)
            PrimaryButton("채팅하기") {
                print("채팅화면")
            }
        }
        .padding(.horizontal, 20)
    }
    
    private struct ProfileImageView: View {
        @ObservedObject var viewModel: ProfileViewModel
        
        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(.gray0)
                        .frame(width: 180, height: 180)
                        .overlay(
                            Circle()
                                .stroke(.deepSprout)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    CachedAsyncImage(path: viewModel.output.profileImage, width: 136, height: 136)
                        .clipShape (
                            Circle()
                        )
                }
                Circle()
                    .fill(.gray0)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .frame(width: 20, height: 20)
                            .foregroundColor(.blackSprout)
                    )
                    .overlay(
                        Circle()
                            .stroke(.deepSprout)
                    )
                    .padding(.trailing, 14)
                    .padding(.bottom, 7)
                    .wrapToButton {
                        print("프로필 사진 변경")
                    }
            }
        }
    }
    
    private struct ProfileInfoView: View {
        @ObservedObject var viewModel: ProfileViewModel
        var body: some View {
            VStack(spacing: 12) {
                Text(viewModel.output.nickname)
                    .font(.pretendard(.title))
            }
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel(postRepository: DefaultPostRepository(networkManager: NetworkManager()), user: UserInfo(
        userId: "66115b1197488f90d3e7e6e5", nickname: "re_jack", profileImage: "/data/profiles/1712413657554.png")))
}
