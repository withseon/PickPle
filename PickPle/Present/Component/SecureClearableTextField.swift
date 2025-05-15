//
//  SecureClearableTextField.swift
//  PickPle
//
//  Created by 정인선 on 5/11/25.
//

import SwiftUI

struct SecureClearableTextField: View {
    var placeholder: String
    @Binding var text: String
    @State private var fieldText = ""
    @State private var isSecured: Bool = true
    @FocusState private var isFocused: Bool
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
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
                let noSpacesText = newValue.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
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
//        .overlay(
//            RoundedRectangle(cornerRadius: 8)
//                .stroke(isFocused ? .blackSprout : .gray30, lineWidth: 1)
//        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}


#Preview {
    VStack {
        SecureClearableTextField("플레이스 홀더", text: .constant(""))
    }
    .padding()
}
