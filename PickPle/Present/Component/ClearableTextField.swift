//
//  ClearableTextField.swift
//  PickPle
//
//  Created by 정인선 on 5/11/25.
//

import SwiftUI

struct ClearableTextField: View {
    private var placeholder: String
    @Binding var text: String
    private var strokeColor: Color
    private var errorMessage: String
    private let limit: Int?
    
    @State private var fieldText = ""
    @FocusState private var isFocused: Bool
    
    init(
        _ placeholder: String,
        text: Binding<String>,
        strokeColor: Color = .gray30,
        errorMessage: String = "",
        limit: Int? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.strokeColor = strokeColor
        self.errorMessage = errorMessage
        self.limit = limit
        
        // ✅ 초기화 시점에 fieldText를 외부 text 값으로 설정
        _fieldText = State(initialValue: text.wrappedValue)
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
                        var noSpacesText = ""
                        if let limit {
                            noSpacesText = String(newValue.replacingOccurrences(of: "\\s", with: "", options: .regularExpression).prefix(limit))
                        } else {
                            noSpacesText = newValue.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
                        }
                        if noSpacesText != newValue {
                            fieldText = noSpacesText
                        }
                        text = fieldText
                    }
                    // ✅ 외부 text 값이 변경될 때 fieldText 동기화
                    .onChange(of: text) { newValue in
                        if fieldText != newValue {
                            fieldText = newValue
                        }
                    }
                    // ✅ 뷰가 나타날 때도 동기화 (추가 보장)
                    .onAppear {
                        if fieldText != text {
                            fieldText = text
                        }
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
    VStack {
        ClearableTextField("플레이스홀더", text: .constant("초기값 테스트"))
        ClearableTextField("빈 값", text: .constant(""))
    }
    .padding()
}
