//
//  ChatRoomView.swift
//  PickPle
//
//  Created by 정인선 on 8/12/25.
//

import SwiftUI
import PhotosUI

// MARK: - 채팅룸 뷰
struct ChatRoomView: View {
    @StateObject var viewModel: ChatRoomViewModel
    @State private var newMessage = ""

    // MARK: - 파일 관련 상태
    @State private var showFileOptions = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showDocumentPicker = false

    // MARK: - 스크롤 관련 상태
    @State private var scrollTarget: Int = 0
    @State private var showScrollToBottomButton = false
    @State private var accumulatedScrollDistance: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0

    // MARK: - UI 상태
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.scenePhase) private var scenePhase

    var nick: String

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 로딩 상태 또는 채팅 리스트
            ZStack {
                if viewModel.output.isInitialLoading {
                    // 초기 로딩 인디케이터
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 채팅 리스트
                    ChatListView(
                        chatItems: viewModel.output.chatItems,
                        isLoadingMore: viewModel.output.isLoadingMore,
                        hasMoreMessages: viewModel.output.hasMoreMessages,
                        scrollTarget: $scrollTarget,
                        showScrollToBottomButton: $showScrollToBottomButton,
                        accumulatedScrollDistance: $accumulatedScrollDistance,
                        lastDragValue: $lastDragValue,
                        onLoadOlderMessages: {
                            viewModel.action(.loadOlderMessages)
                        },
                        onDismiss: {
                            dismissAll()
                        }
                    )
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if showScrollToBottomButton {
                    ScrollToBottomButton {
                        triggerScroll()
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
            .onTapGesture {
                dismissAll()
            }

            // MARK: - 파일 미리보기
            if !viewModel.output.selectedFiles.isEmpty {
                FilePreviewView(
                    selectedFiles: $viewModel.output.selectedFiles,
                    onSendFiles: {
                        handleSendFiles()
                    },
                    onRemoveFile: { index in
                        viewModel.action(.removeSelectedFile(at: index))
                    }
                )
            }

            // MARK: - 메시지 입력창
            MessageInputBar(
                newMessage: $newMessage,
                isTextFieldFocused: $isTextFieldFocused,
                showFileOptions: showFileOptions,
                hasSelectedFiles: !viewModel.output.selectedFiles.isEmpty,
                selectedFiles: viewModel.output.selectedFiles,
                onSend: sendMessage,
                onPlusButtonTapped: {
                    handlePlusButtonTap()
                },
                onTextFieldTapped: {
                    handleTextFieldTap()
                }
            )

            // MARK: - 파일 옵션 뷰 (MessageInputBar 아래)
            if showFileOptions {
                FileOptionsView(
                    selectedPhotoItems: $selectedPhotoItems,
                    showDocumentPicker: $showDocumentPicker,
                    onImageTap: { },
                    onCameraTap: {
                        dismissFileOptions()
                    },
                    onFileTap: {
                        showDocumentPicker = true
                    }
                )
                .frame(height: 200)
                .background(.gray15)
                .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(nick)
        .navigationBarTitleDisplayMode(.inline)
        .background(.gray15)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            setupInitialData()
        }
        .onDisappear {
            print("🔴 ChatRoomView onDisappear - roomId: \(viewModel.roomId)")
            ChatStateManager.shared.exitChatRoom()
            viewModel.action(.socketDisconnect)
        }
        .onChange(of: scenePhase) { phase in
            handleScenePhase(phase)
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
        .onChange(of: selectedPhotoItems) { items in
            handlePhotoSelection(items)
        }
    }

    // MARK: - Helper Methods
    private func setupInitialData() {
        print("🟢 ChatRoomView onAppear - roomId: \(viewModel.roomId)")

        viewModel.action(.fetchMessages)
        ChatStateManager.shared.enterChatRoom(roomId: viewModel.roomId)
        clearNotifications()
        viewModel.action(.markAsRead)
    }

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            print("📱 Scene Active - 웹소켓 연결")
            viewModel.action(.socketConnect)
            clearNotifications()
        case .inactive:
            print("📱 Scene Inactive")
        case .background:
            print("📱 Scene Background - 웹소켓 해제")
            viewModel.action(.socketDisconnect)
        @unknown default:
            break
        }
    }

    private func sendMessage() {
        if !viewModel.output.selectedFiles.isEmpty {
            handleSendFiles()
            triggerScroll()
            return
        }

        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        viewModel.action(.sendMessage(newMessage))
        newMessage = ""

        triggerScroll()
    }

    private func handleSendFiles() {
        viewModel.action(.sendFile(viewModel.output.selectedFiles))
        viewModel.action(.clearSelectedFiles)
    }

    private func clearNotifications() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["chat_\(viewModel.roomId)"])
    }

    private func handlePlusButtonTap() {
        if showFileOptions {
            withAnimation(.easeOut(duration: 0.3)) {
                showFileOptions = false
            }
        } else if isTextFieldFocused {
            isTextFieldFocused = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showFileOptions = true
                }
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                showFileOptions = true
            }
        }
    }

    private func handleTextFieldTap() {
        if showFileOptions {
            withAnimation(.easeOut(duration: 0.3)) {
                showFileOptions = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isTextFieldFocused = true
            }
        } else {
            isTextFieldFocused = true
        }
    }

    private func dismissFileOptions() {
        withAnimation(.easeOut(duration: 0.3)) {
            showFileOptions = false
        }
    }

    private func dismissAll() {
        withAnimation(.easeOut(duration: 0.3)) {
            isTextFieldFocused = false
            showFileOptions = false
        }
    }

    private func triggerScroll() {
        scrollTarget += 1
    }

    // MARK: - File Conversion Methods
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        Task.detached(priority: .userInitiated) {
            var convertedFiles: [SelectedFile] = []

            await withTaskGroup(of: SelectedFile?.self) { group in
                for item in items.prefix(5) {
                    group.addTask {
                        do {
                            if let data = try await item.loadTransferable(type: Data.self) {
                                let downsampledImage = ImageProcessingManager.shared.downsampleForDisplay(
                                    data: data,
                                    pointSize: CGSize(width: 300, height: 300),
                                    scale: 1.0
                                )

                                return SelectedFile(
                                    id: UUID(),
                                    type: .image,
                                    image: downsampledImage,
                                    data: data,
                                    fileName: "image.jpg"
                                )
                            }
                        } catch {
                            print("이미지 로드 에러: \(error)")
                        }

                        return nil
                    }
                }

                for await file in group {
                    if let file = file {
                        convertedFiles.append(file)
                    }
                }
            }

            await MainActor.run {
                self.viewModel.action(.addSelectedFiles(convertedFiles))
                self.selectedPhotoItems.removeAll()

                if !convertedFiles.isEmpty {
                    self.dismissFileOptions()
                }
            }
        }
    }

    private func handleDocumentPicked(_ url: URL) {
        guard viewModel.output.selectedFiles.count < 5 else { return }

        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let fileExtension = url.pathExtension.lowercased()

            let fileType: SelectedFile.FileType
            var image: UIImage? = nil

            switch fileExtension {
            case "pdf":
                fileType = .pdf
            case "jpg", "jpeg", "png", "gif":
                fileType = .image
                image = UIImage(data: data)
            default:
                return
            }

            let file = SelectedFile(
                id: UUID(),
                type: fileType,
                image: image,
                data: data,
                fileName: fileName
            )

            viewModel.action(.addSelectedFiles([file]))

        } catch {
            print("파일 읽기 오류: \(error)")
        }
    }
}
