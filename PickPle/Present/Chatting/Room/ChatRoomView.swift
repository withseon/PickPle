//
//  ChatRoomView.swift
//  PickPle
//
//  Created by 정인선 on 7/20/25.
//

import SwiftUI
import PhotosUI

// 메인 채팅뷰
struct ChatRoomView: View {
    @StateObject var viewModel: ChatRoomViewModel
    @State private var newMessage = ""
    @State private var scrollTarget: Int = 0
    @State private var showFileOptions = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showDocumentPicker = false
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
                showFileOptions: showFileOptions,
                onSend: sendMessage,
                onPlusButtonTapped: {
                    handlePlusButtonTap()
                },
                onTextFieldTapped: {
                    handleTextFieldTap()
                }
            )
            
            // 파일 옵션 뷰 (MessageInputBar 아래)
            if showFileOptions {
                FileOptionsView(
                    selectedPhotoItems: $selectedPhotoItems,
                    showDocumentPicker: $showDocumentPicker,
                    onImageTap: {
                        print("앨범 선택")
                    },
                    onCameraTap: {
                        print("카메라 촬영")
                        dismissFileOptions()
                    },
                    onFileTap: {
                        print("파일 선택")
                        showDocumentPicker = true
                    }
                )
                .frame(height: max(keyboardHeight, 200))
                .background(.gray15)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(nick)
        .navigationBarTitleDisplayMode(.inline)
        .background(.gray15)
        .onTapGesture {
            dismissAll()
        }
        .task {
            viewModel.action(.fetchMessages)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardFrame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .onChange(of: selectedPhotoItems) { newItems in
            Task {
                selectedImages.removeAll()
                
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
                
                if !selectedImages.isEmpty {
                    dismissFileOptions()
                    handleSelectedImages(selectedImages)
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(
                allowedContentTypes: [
                    .pdf,
                    .jpeg,
                    .png,
                    UTType(filenameExtension: "jpg") ?? .jpeg,
                    UTType(filenameExtension: "gif") ?? .gif
                ],
                onDocumentPicked: { url in
                    handleDocumentPicked(url)
                    dismissFileOptions()
                }
            )
        }
    }
    
    private func handleSelectedImages(_ images: [UIImage]) {
        // TODO: 이미지 선택 후 처리
        for image in images {
            print("선택된 이미지 크기: \(image.size)")
        }
        
        selectedPhotoItems.removeAll()
        selectedImages.removeAll()
    }
    
    private func handleDocumentPicked(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let fileExtension = url.pathExtension.lowercased()
            
            print("선택된 파일: \(fileName)")
            print("파일 크기: \(data.count) bytes")
            print("파일 확장자: \(fileExtension)")
            
            // 파일 형식에 따른 처리
            switch fileExtension {
            case "pdf":
                handlePDFFile(data, fileName: fileName)
            case "jpg", "jpeg", "png", "gif":
                if let image = UIImage(data: data) {
                    handleSelectedImages([image])
                }
            default:
                print("지원하지 않는 파일 형식입니다.")
            }
            
        } catch {
            print("파일 읽기 오류: \(error)")
        }
    }
    
    private func handlePDFFile(_ data: Data, fileName: String) {
        print("PDF 파일: \(fileName)")
        print("PDF 파일 크기: \(data.count) bytes")
        // TODO: 파일 선택 후 처리
        
        selectedPhotoItems.removeAll()
    }
    
    private func handlePlusButtonTap() {
        withAnimation(.easeOut(duration: 0.3)) {
            if showFileOptions {
                showFileOptions = false
            } else if isTextFieldFocused {
                // 키보드가 올라와있으면 키보드를 먼저 내림
                isTextFieldFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showFileOptions = true
                    }
                }
            } else {
                // 키보드가 없으면 바로 파일 옵션 표시
                showFileOptions = true
            }
        }
    }
    
    private func handleTextFieldTap() {
        withAnimation(.easeOut(duration: 0.3)) {
            if showFileOptions {
                // 닫고 키보드 올림
                showFileOptions = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            } else {
                // 즉시 키보드 올림
                isTextFieldFocused = true
            }
        }
    }
    
    private func dismissFileOptions() {
        showFileOptions = false
    }
    
    private func dismissAll() {
        isTextFieldFocused = false
        showFileOptions = false
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

// 파일 옵션 뷰
struct FileOptionsView: View {
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    @Binding var showDocumentPicker: Bool
    let onImageTap: () -> Void
    let onCameraTap: () -> Void
    let onFileTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            Spacer()
            HStack(spacing: 30) {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    FileOptionButton(
                        icon: "photo",
                        title: "사진"
                    )
                }
                
                FileOptionButton(
                    icon: "camera",
                    title: "카메라",
                    action: onCameraTap
                )
                
                FileOptionButton(
                    icon: "doc",
                    title: "파일",
                    action: onFileTap
                )
            }
            
            Spacer()
        }
        .background(.gray15)
    }
}

// 파일 옵션 버튼
struct FileOptionButton: View {
    let icon: String
    let title: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            if let action {
                buttonContent
                    .wrapToButton {
                        action()
                    }
            } else {
                buttonContent
            }
            
            Text(title)
                .font(.pretendard(.caption1))
                .foregroundColor(.gray100)
        }
    }
    
    private var buttonContent: some View {
        Image(systemName: icon)
            .frame(width: 50, height: 50)
            .foregroundColor(.blackSprout)
            .background(.gray0)
            .clipShape(Circle())
            .shadow(color: .gray100.opacity(0.1), radius: 2, x: 0, y: 1)
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
    let showFileOptions: Bool
    let onSend: () -> Void
    let onPlusButtonTapped: () -> Void
    let onTextFieldTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // 파일 전송
                ZStack {
                    Image(systemName: "plus")
                        .iconFrame(20)
                        .foregroundColor(.gray60)
                        .wrapToButton {
                            onPlusButtonTapped()
                        }
                        .opacity(showFileOptions ? 0 : 1)
                    
                    Image(systemName: "xmark")
                        .iconFrame(20)
                        .foregroundColor(.gray60)
                        .wrapToButton {
                            onPlusButtonTapped()
                        }
                        .opacity(showFileOptions ? 1 : 0)
                }
                
                // 텍스트 입력 필드
                TextField("메시지를 입력하세요...", text: $newMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.gray0)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        onSend()
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            onTextFieldTapped()
                        }
                    )
                
                // 전송 버튼
                Image(systemName: "arrow.up.circle.fill")
                    .iconFrame(20)
                    .foregroundStyle(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray60 : .blackSprout)
                .wrapToButton {
                    onSend()
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
