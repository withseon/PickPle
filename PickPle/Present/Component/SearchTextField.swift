//
//  SearchTextField.swift
//  PickPle
//
//  Created by 정인선 on 5/22/25.
//

import SwiftUI

struct SearchTextField: View {
    private var placeholder: String
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        HStack {
            Image("search")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(.blackSprout)
            TextField(placeholder, text: $text)
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(.gray0)
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.blackSprout)
        }
        .tint(.blackSprout)
    }
}

#Preview {
    VStack {
        SearchTextField("플레이스홀더", text: .constant(""))
    }
    .padding()
    .background(.deepSprout)
}
