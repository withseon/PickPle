//
//  SecureClearableTextField.swift
//  PickPle
//
//  Created by 정인선 on 5/11/25.
//

import SwiftUI

struct SecureClearableTextField: View {
    private var placeholder: String
    @Binding var text: String
    private var strokeColor: Color
    private var errorMessage: String
    private let limit: Int?
    
    @State private var fieldText = ""
    @State private var isSecured: Bool = true
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
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Group {
                    if isSecured {
                        SecureField(placeholder, text: $fieldText)
                            .clearable(text: $fieldText)
                            .focused($isFocused)
                    } else {
                        TextField(placeholder, text: $fieldText)
                            .clearable(text: $fieldText)
                            .focused($isFocused)
                    }
                }
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
                
                Image(systemName: isSecured ? "eye" : "eye.slash")
                    .foregroundColor(.gray45)
                    .wrapToButton {
                        isSecured.toggle()
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
        SecureClearableTextField("플레이스 홀더", text: .constant(""))
    }
    .padding()
}
