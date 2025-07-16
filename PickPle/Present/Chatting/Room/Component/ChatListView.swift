//
//  ChatListView.swift
//  PickPle
//
//  Created by 정인선 on 8/12/25.
//

import SwiftUI

struct ChatListView: View {
    let chatItems: [ChatItem]
    let isLoadingMore: Bool
    let hasMoreMessages: Bool
    @Binding var scrollTarget: Int
    @Binding var showScrollToBottomButton: Bool
    @Binding var accumulatedScrollDistance: CGFloat
    @Binding var lastDragValue: CGFloat
    let onLoadOlderMessages: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List {
                // 로딩 인디케이터
                if isLoadingMore {
                    ChatLoadingIndicator()
                        .id("loading")
                }

                // 채팅 아이템들
                ForEach(Array(chatItems.reversed().enumerated()), id: \.offset) { index, item in
                    ChatItemView(
                        item: item,
                        isLastInTimeGroup: isLastInTimeGroup(index: index, items: Array(chatItems.reversed()))
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                    .id("message_\(index)")
                    .rotationEffect(.degrees(180))
                    .scaleEffect(x: -1, y: 1, anchor: .center)
                    .onAppear {
                        let totalCount = chatItems.count
                        let actualIndex = totalCount - 1 - index

                        if actualIndex == 0 && hasMoreMessages && !isLoadingMore {
                            onLoadOlderMessages()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(.gray15)
            // List를 180도 회전 + x축 뒤집기
            .rotationEffect(.degrees(180))
            .scaleEffect(x: -1, y: 1, anchor: .center)
            .onAppear {
                scrollToLatestMessage(proxy: proxy, animated: false)
            }
            .onChange(of: scrollTarget) { _ in
                scrollToLatestMessage(proxy: proxy, animated: true)
                // 스크롤 버튼 클릭 시 누적 거리 리셋
                accumulatedScrollDistance = 0
                showScrollToBottomButton = false
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        let currentY = value.translation.height
                        let deltaY = currentY - lastDragValue
                        lastDragValue = currentY

                        if deltaY > 0 {
                            accumulatedScrollDistance += abs(deltaY)
                        } else if deltaY < 0 {
                            accumulatedScrollDistance = max(0, accumulatedScrollDistance - abs(deltaY))
                        }

                        let shouldShow = accumulatedScrollDistance > 200

                        if showScrollToBottomButton != shouldShow {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showScrollToBottomButton = shouldShow
                            }
                        }
                    }
                    .onEnded { _ in
                        lastDragValue = 0
                    }
            )
        }
    }

    // MARK: - Helper Methods
    private func scrollToLatestMessage(proxy: ScrollViewProxy, animated: Bool = true) {
        guard !chatItems.isEmpty else { return }

        let firstMessageId = "message_0"

        if animated {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(firstMessageId, anchor: .top)
            }
        } else {
            proxy.scrollTo(firstMessageId, anchor: .top)
        }
    }

    private func isLastInTimeGroup(index: Int, items: [ChatItem]) -> Bool {
        let currentItem = items[index]

        guard index > 0 else { return true }

        let previousItem = items[index - 1]

        if currentItem.message.sender.userId != previousItem.message.sender.userId {
            return true
        }

        return currentItem.message.createdAt != previousItem.message.createdAt
    }
}
