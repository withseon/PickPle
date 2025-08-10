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
    @Environment(\.scenePhase) private var scenePhase // ✅ 추가
    
    var filteredChatRooms: [ChatRoom] {
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChatRoomRead"))) { notification in
                if let userInfo = notification.userInfo,
                   let roomId = userInfo["roomId"] as? String {
                    viewModel.action(.markAsRead(roomId))
                }
            }
        // ✅ 앱이 포그라운드로 돌아올 때 데이터 새로고침
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    print("📱 ChatRoomListView - 포그라운드 복귀, 데이터 새로고침")
                    viewModel.action(.fetchChatList) // 전체 새로고침
                }
            }
            .handleErrors(viewModel: viewModel)
    }
}

// 개별 채팅방 행 뷰
struct ChatRoomRow: View {
    let chatRoom: ChatRoom
    
    var body: some View {
        HStack(spacing: 12) {
            // 프로필 이미지
            if let profileImage = chatRoom.profileImage {
                CachedImageView(imagePath: profileImage, size: CGSize(width: 44, height: 44))
                    .clipShape (
                        Circle()
                    )
            } else {
                Image("empty_profile")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .clipShape(
                        Circle()
                    )
            }
            
            // 채팅방 정보
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chatRoom.nick)
                        .font(.pretendard(.body1))
                        .foregroundStyle(.gray100)
                    
                    Spacer()
                    
                    Text(chatRoom.updatedAt)
                        .font(.pretendard(.caption2))
                        .foregroundStyle(.gray75)
                }
                
                HStack {
                    Text(chatRoom.lastChat)
                        .font(.pretendard(.caption1))
                        .foregroundStyle(.gray75)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // 읽지 않은 메시지 개수
                    if chatRoom.unreadCount > 0 {
                        Text("\(chatRoom.unreadCount)")
                            .font(.pretendard(.caption2))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(.red)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
