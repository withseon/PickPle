//
//  ClearableModifier.swift
//  PickPle
//
//  Created by 정인선 on 5/10/25.
//

import SwiftUI

private struct ClearableModifier: ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        HStack {
            content
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundColor(.gray45)
                }
                .transition(.scale)
                .animation(.default, value: text)
            }
        }
    }
}

extension TextField {
    func clearable(text: Binding<String>) -> some View {
        self.modifier(ClearableModifier(text: text))
    }
}

extension SecureField {
    func clearable(text: Binding<String>) -> some View {
        self.modifier(ClearableModifier(text: text))
    }
}
