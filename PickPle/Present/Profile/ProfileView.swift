//
//  ProfileView.swift
//  PickPle
//
//  Created by 정인선 on 6/7/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            MainProfileView()
        }
    }
}

struct MainProfileView: View {
   var body: some View {
       ScrollView {
           LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
               Section {
                   ProfileInfoHeaderView()
               }
               
               Section {
                   LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
                       ForEach(0..<20) { item in
                           GeometryReader { geometry in
                               CachedAsyncImage(
                                   path: "https://picsum.photos/300/300?random=\(item)",
                                   width: geometry.size.width,
                                   height: geometry.size.width
                               )
                           }
                           .aspectRatio(1, contentMode: .fill)
                       }
                   }
               } header: {
                   PostSectionView()
               }
           }
       }
   }
}

struct ProfileInfoHeaderView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProfileImageView()
            ProfileInfoView()
            PrimaryButton("채팅하기") {
                print("채팅화면")
            }
        }
        .padding(.horizontal, 20)
    }
    
    private struct ProfileImageView: View {
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
                    CachedAsyncImage(path: "", width: 136, height: 136)
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
        var body: some View {
            VStack(spacing: 12) {
                Text("닉네임")
                    .font(.pretendard(.title))
                Text("설명란")
                    .font(.pretendard(.body2))
                    .foregroundStyle(.gray60)
                
                HStack {
                    VStack {
                        Text("127")
                        Text("게시글")
                    }
                    .frame(maxWidth: .infinity)
                    Divider()
                        .frame(width: 1)
                    VStack {
                        Text("70")
                        Text("좋아요")
                    }
                    .frame(maxWidth: .infinity)
                }
                .font(.pretendard(.body1))
                .frame(height: 36)
            }
        }
    }
}

struct PostSectionView: View {
    var body: some View {
        HStack {
            Text("게시글")
                .font(.pretendard(.body1))
                .padding(20)
            Spacer()
        }
        .background(.gray0)
    }
}

#Preview {
    ProfileView()
}
