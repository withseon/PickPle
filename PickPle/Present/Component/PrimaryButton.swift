//
//  PrimaryButton.swift
//  PickPle
//
//  Created by 정인선 on 5/10/25.
//

import SwiftUI

struct PrimaryButton: View {
    private let title: String
    private let backgroundColor: Color
    private let foregroundColor: Color
    private let action: () -> Void
    
    @Environment(\.isEnabled) private var isEnabled
    
    init(
        _ title: String,
        backgroundColor: Color = .deepSprout,
        foregroundColor: Color = .white,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Text(title)
            .font(.pretendard(.title))
            .foregroundColor(isEnabled ? foregroundColor : .gray0)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isEnabled ? backgroundColor : .gray30)
            .cornerRadius(8)
            .wrapToButton {
                action()
            }
    }
}

#Preview {
    VStack {
        PrimaryButton("길찾기") {
            print("map")
        }
        PrimaryButton("로그인") {
            print("login")
        }
    }
    .padding()
}
