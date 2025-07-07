//
//  ChatRoomListView.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import SwiftUI

struct ChatRoomListView: View {
    @StateObject var viewModel: ChatRoomListViewModel
    @State private var searchText = ""
    
    var filteredChatRooms: [ChatRoomThumbnail] {
        if searchText.isEmpty {
            return viewModel.output.chatRoomList
        } else {
            return viewModel.output.chatRoomList.filter { $0.nick.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
            VStack(spacing: 0) {
                SearchTextField("검색어를 입력해주세요.", text: $searchText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                
                // 채팅방 목록
                List(filteredChatRooms, id: \.roomId) { chatRoom in
                    ZStack {
                        NavigationLink(value: ChatRoute.chatRoom(roomId: chatRoom.roomId, nick: chatRoom.nick)) {
                            EmptyView()
                        }
                        .opacity(0)

                        ChatRoomRow(chatRoom: chatRoom)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    
                }
                .listStyle(PlainListStyle())
            }
            .padding(.top, 20)
            .task {
                viewModel.action(.fetchChatList)
            }
    }
}

// 개별 채팅방 행 뷰
struct ChatRoomRow: View {
    let chatRoom: ChatRoomThumbnail
    
    var body: some View {
        HStack(spacing: 12) {
            // 프로필 이미지
            if let profileImage = chatRoom.profileImage {
                CachedAsyncImage(path: profileImage, width: 56, height: 56)
                    .clipShape (
                        Circle()
                    )
            } else {
                Image("empty_profile")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .clipShape(
                        Circle()
                    )
            }
            
            // 채팅방 정보
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chatRoom.nick)
                        .font(.pretendard(.body1))
                        .foregroundColor(.gray100)
                    
                    Spacer()
                    
                    Text(chatRoom.updatedAt)
                        .font(.pretendard(.caption2))
                        .foregroundColor(.gray75)
                }
                
                HStack {
                    Text(chatRoom.lastChat)
                        .font(.pretendard(.caption1))
                        .foregroundColor(.gray75)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 읽지 않은 메시지 개수
//                    if chatRoom.unreadCount > 0 {
//                        Text("\(chatRoom.unreadCount)")
//                            .font(.caption)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white)
//                            .frame(minWidth: 20, minHeight: 20)
//                            .background(Color.red)
//                            .clipShape(Circle())
//                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
