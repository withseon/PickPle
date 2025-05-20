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
                        let noSpacesText = newValue.replacingOccurrences(of: "\\s", with: "", options: .regularExpression).prefix(20)
                        if noSpacesText != newValue {
                            fieldText = String(noSpacesText)
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
    VStack {
        ClearableTextField("플레이스홀더", text: .constant(""))
    }
    .padding()
}
