//
//  ChatRoomView.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import SwiftUI

// 메인 채팅뷰
struct ChatRoomView: View {
    @StateObject var viewModel: ChatRoomViewModel
    @State private var newMessage = ""
    @State private var scrollTarget: Int = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var nick: String
    
    var body: some View {
        VStack(spacing: 0) {
            // 채팅 메시지 리스트
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(viewModel.output.chatMessages.enumerated()), id: \.offset) { index, message in
                            MessageBubble(message: message)
                                .id("message_\(index)")
                        }
                        
                        // 하단 앵커
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .opacity(viewModel.output.isInitialLoading ? 0 : 1)
                .onChange(of: viewModel.output.isInitialLoading) { isLoading in
                    if !isLoading {
                        DispatchQueue.main.async {
                            scrollToBottom(proxy: proxy, animated: false)
                        }
                    }
                }
                .onChange(of: scrollTarget) { _ in
                    scrollToBottom(proxy: proxy, animated: true)
                }
            }
            
            if viewModel.output.isInitialLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
            
            // 메시지 입력창
            MessageInputBar(
                newMessage: $newMessage,
                isTextFieldFocused: $isTextFieldFocused,
                onSend: sendMessage
            )
        }
        .navigationTitle(nick)
        .navigationBarTitleDisplayMode(.inline)
        .background(.gray15)
        .onTapGesture {
            isTextFieldFocused = false
        }
        .task {
            viewModel.action(.fetchMessages)
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
    
    private func triggerScroll() {
        scrollTarget += 1
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        viewModel.action(.sendMessage(newMessage))
        newMessage = ""
        
        triggerScroll()
    }
}

// 메시지 버블 컴포넌트
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.sender.userId == UserDefaultsManager.userId {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.blackSprout)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.createdAt)
                        .font(.pretendard(.caption2))
                        .foregroundColor(.gray75)
                        .padding(.trailing, 4)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.gray0)
                        .foregroundColor(.gray100)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .gray100.opacity(0.1), radius: 1, x: 0, y: 1)
                    
                    Text(message.createdAt)
                        .font(.pretendard(.caption2))
                        .foregroundColor(.gray75)
                        .padding(.leading, 4)
                }
                
                Spacer(minLength: 60)
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// 메시지 입력 바 컴포넌트
struct MessageInputBar: View {
    @Binding var newMessage: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // 텍스트 입력 필드
                TextField("메시지를 입력하세요...", text: $newMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        onSend()
                    }
                
                // 전송 버튼
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .iconFrame(20)
                        .foregroundColor(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray60 : .blackSprout)
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .toolbar(.hidden, for: .tabBar)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.gray30)
        }
        .animation(.easeOut(duration: 0.25), value: isTextFieldFocused)
    }
}
