//
//  SignUpInfoView.swift
//  PickPle
//
//  Created by 정인선 on 5/12/25.
//

import SwiftUI

struct SignUpInfoView: View {
    @StateObject var viewModel: SignUpInfoViewModel
    @State var nickname = ""
    @State var phoneNum = ""
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 100)
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("회원 정보를 입력해주세요.")
                            .font(.pretendard(.title))
                        Text("닉네임은 특수문자(.,?*-@) 한 글자로 구성할 수 없습니다.")
                            .font(.pretendard(.caption1))
                    }
                    Spacer()
                }
                VStack(alignment: .leading) {
                    Text("닉네임(필수)")
                        .font(.pretendard(.body1))
                    ClearableTextField(
                        "닉네임을 입력해주세요",
                        text: $nickname,
                        strokeColor: viewModel.output.nicknameErrorMassage.isEmpty ? .gray30 : .errorRed,
                        errorMessage: viewModel.output.nicknameErrorMassage,
                        limit: 15
                    )
                    .onChange(of: nickname) { newValue in
                        viewModel.input.nickname = newValue
                        viewModel.action(.validateNickname)
                    }
                }
                VStack(alignment: .leading) {
                    Text("휴대폰 번호")
                        .font(.pretendard(.body1))
                    PhoneNumberTextField(
                        "휴대폰 번호를 입력해주세요",
                        text: $phoneNum,
                        strokeColor: viewModel.output.phoneNumErrorMessage.isEmpty ? .gray30 : .errorRed,
                        errorMessage: viewModel.output.phoneNumErrorMessage
                    )
                    .onChange(of: phoneNum) { newValue in
                        viewModel.input.phoneNum = newValue
                        viewModel.action(.validatePhoneNum)
                    }
                }
                Spacer()
                PrimaryButton(
                    "완료",
                    backgroundColor: .gray100,
                    foregroundColor: .gray0
                ) {
                    
                }
                .disabled(viewModel.output.nextButtonDisable)
            }
            .padding(20)
        }
    }
}

private struct PhoneNumberTextField: View {
    private var placeholder: String
    @Binding var text: String
    private var strokeColor: Color
    private var errorMessage: String
    
    @State private var fieldText = ""
    @FocusState private var isFocused: Bool
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        strokeColor: Color = .gray30,
        errorMessage: String = ""
    ) {
        self.placeholder = placeholder
        self._text = text
        self.strokeColor = strokeColor
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                TextField(placeholder, text: $fieldText)
                    .clearable(text: $fieldText)
                    .focused($isFocused)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .tint(Color(.label))
                    .onChange(of: fieldText) { newValue in
                        let numbersOnlyText = newValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression).prefix(11)
                        if numbersOnlyText != newValue {
                            fieldText = String(numbersOnlyText)
                        }
                        text = fieldText
                    }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? strokeColor : .gray30, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            Text(errorMessage)
                .font(.pretendard(.caption1))
                .foregroundStyle(strokeColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    SignUpInfoView(viewModel: SignUpInfoViewModel())
}
