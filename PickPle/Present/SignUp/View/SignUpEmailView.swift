//
//  SignUpEmailView.swift
//  PickPle
//
//  Created by 정인선 on 5/11/25.
//

import SwiftUI

struct SignUpEmailView: View {
    @ObservedObject var viewModel: SignUpViewModel
    @State var email = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            VStack(spacing: 20) {
                HStack {
                    Text("로그인에 사용할\n이메일을 입력해주세요.")
                        .font(.pretendard(.title))
                    Spacer()
                }
                VStack(alignment: .leading) {
                    Text("이메일(아이디)")
                        .font(.pretendard(.body1))
                    EmailTextField(
                        "이메일을 입력해주세요",
                        text: $email,
                        strokeColor: viewModel.output.emailErrorMessage.isEmpty ? .gray30 : .errorRed,
                        errorMessage: viewModel.output.emailErrorMessage
                    )
                    .focused($isFocused)
                    .onChange(of: email) { newValue in
                        viewModel.action(.validateEmail(newValue))
                    }
                }
            }
            Spacer()
            PrimaryButton(
                "다음",
                backgroundColor: .gray100,
                foregroundColor: .gray0
            ) {
                viewModel.action(.emailDone)
            }
            .disabled(viewModel.output.emailDoneButtonDisable)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = false
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
