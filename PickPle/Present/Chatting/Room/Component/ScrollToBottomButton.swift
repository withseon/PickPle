//
//  ScrollToBottomButton.swift
//  PickPle
//
//  Created by 정인선 on 8/12/25.
//

import SwiftUI

struct ScrollToBottomButton: View {
    let onTap: () -> Void

    var body: some View {
        Image(systemName: "chevron.down")
            .frame(width: 32, height: 32)
            .foregroundColor(.blackSprout.opacity(0.8))
            .background(.gray0.opacity(0.8))
            .clipShape(Circle())
            .shadow(radius: 4)
            .wrapToButton {
                withAnimation(.easeOut(duration: 0.3)) {
                    onTap()
                }
            }
            .transition(.scale.combined(with: .opacity))
    }
}
