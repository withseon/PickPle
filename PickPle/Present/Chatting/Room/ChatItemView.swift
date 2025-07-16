//
//  ChatItemView.swift
//  PickPle
//
//  Created by 정인선 on 8/12/25.
//

import SwiftUI
import PhotosUI

// MARK: - 채팅 아이템 뷰
struct ChatItemView: View {
    let item: ChatItem
    let isLastInTimeGroup: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if let dateSeparator = item.dateSeparator {
                DateSeparatorView(dateString: dateSeparator)
            }
            
            if !item.message.files.isEmpty {
                FileDisplayView(
                    message: item.message,
                    showTime: isLastInTimeGroup
                )
            } else {
                MessageBubble(message: item.message, showTime: isLastInTimeGroup)
            }
        }
    }
}

// MARK: - 날짜 구분선 뷰
struct DateSeparatorView: View {
    let dateString: String
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(.gray30)
                .frame(height: 1)
            
            Text(dateString)
                .font(.pretendard(.caption2))
                .foregroundStyle(.gray75)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            
            Rectangle()
                .fill(.gray30)
                .frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}


// MARK: - 메시지 버블 컴포넌트
struct MessageBubble: View {
    let message: ChatMessage
    let showTime: Bool
    
    var body: some View {
        HStack {
            if message.sender.userId == UserDefaultsManager.userId {
                Spacer(minLength: 60)
                
                HStack(alignment: .bottom, spacing: 4) {
                    if showTime {
                        Text(message.createdAt)
                            .font(.pretendard(.caption2))
                            .foregroundStyle(.gray75)
                            .padding(.bottom, 2)
                    }
                    
                    Text(message.content)
                        .font(.pretendard(.body3))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.blackSprout)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(message.content)
                        .font(.pretendard(.body3))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.gray0)
                        .foregroundStyle(.gray100)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .gray100.opacity(0.1), radius: 1, x: 0, y: 1)
                    
                    if showTime {
                        Text(message.createdAt)
                            .font(.pretendard(.caption2))
                            .foregroundStyle(.gray75)
                            .padding(.bottom, 2)
                    }
                }
                
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - 메시지 입력 바 컴포넌트
struct MessageInputBar: View {
    @Binding var newMessage: String
    @FocusState.Binding var isTextFieldFocused: Bool
    let showFileOptions: Bool
    let hasSelectedFiles: Bool
    let selectedFiles: [SelectedFile]
    let onSend: () -> Void
    let onPlusButtonTapped: () -> Void
    let onTextFieldTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if !hasSelectedFiles {
                Divider()
            }
            
            HStack(spacing: 12) {
                // 파일 전송 버튼
                ZStack {
                    Image(systemName: "plus")
                        .iconFrame(20)
                        .foregroundStyle(.gray60)
                        .wrapToButton {
                            onPlusButtonTapped()
                        }
                        .opacity(showFileOptions ? 0 : 1)
                    
                    Image(systemName: "xmark")
                        .iconFrame(20)
                        .foregroundStyle(.gray60)
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
                
                // 전송 버튼 - 파일이 있거나 텍스트가 있으면 활성화
                Image(systemName: "arrow.up.circle.fill")
                    .iconFrame(20)
                    .foregroundStyle(
                        (!selectedFiles.isEmpty || !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        ? .blackSprout
                        : .gray60
                    )
                .wrapToButton {
                    onSend()
                }
                .disabled(selectedFiles.isEmpty && newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.gray30)
        }
        .animation(.easeOut(duration: 0.25), value: isTextFieldFocused)
    }
}

// MARK: - 파일 옵션 뷰
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

// MARK: - 파일 옵션 버튼
struct FileOptionButton: View {
    let icon: String
    let title: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            if let action = action {
                Button(action: action) {
                    buttonContent
                }
            } else {
                buttonContent
            }
            
            Text(title)
                .font(.pretendard(.caption1))
                .foregroundStyle(.gray100)
        }
    }
    
    private var buttonContent: some View {
        Image(systemName: icon)
            .frame(width: 50, height: 50)
            .foregroundStyle(.blackSprout)
            .background(.gray0)
            .clipShape(Circle())
            .shadow(color: .gray100.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 파일 미리보기 뷰
struct FilePreviewView: View {
    @Binding var selectedFiles: [SelectedFile]
    let onSendFiles: () -> Void
    let onRemoveFile: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(selectedFiles.enumerated()), id: \.element.id) { index, file in
                        FilePreviewItem(
                            file: file,
                            onRemove: {
                                onRemoveFile(index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .padding(.vertical, 8)
            .background(.gray30)
        }
    }
}

// MARK: - 개별 파일 미리보기 아이템
struct FilePreviewItem: View {
    let file: SelectedFile
    let onRemove: () -> Void
    
    var body: some View {
        Group {
            if file.type == .image, let image = file.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray0)
                    .overlay {
                        VStack {
                            Image(systemName: "doc.fill")
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.gray60)
                            Text(file.fileName)
                                .padding(.horizontal, 4)
                                .lineLimit(1)
                                .font(.pretendard(.caption3))
                        }
                    }
                    .frame(width: 60, height: 60)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .iconFrame(12)
                    .foregroundStyle(.gray100.opacity(0.5))
                    .background(.gray0)
                    .clipShape(Circle())
            }
            .padding(2)
        }
    }
}
