//
//  ClearableTextField.swift
//  PickPle
//
//  Created by 정인선 on 5/11/25.
//

import SwiftUI

struct ClearableTextField: View {
    var placeholder: String
    @Binding var text: String
    @State private var fieldText = ""
    @FocusState private var isFocused: Bool

    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $fieldText)
                .clearable(text: $fieldText)
                .focused($isFocused)
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
        ClearableTextField("플레이스홀더", text: .constant(""))
    }
    .padding()
}
