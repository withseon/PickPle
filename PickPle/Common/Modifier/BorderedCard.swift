//
//  BorderedCard.swift
//  PickPle
//
//  Created by 정인선 on 8/13/25.
//

import SwiftUI

private struct BorderedCard: ViewModifier {
    let cornerRadius: CGFloat
    let borderColor: Color
    let borderWidth: CGFloat
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
}

extension View {
    func borderedCard(
        cornerRadius: CGFloat,
        borderColor: Color = .clear,
        borderWidth: CGFloat = 1,
        backgroundColor: Color = .clear
    ) -> some View {
        modifier(BorderedCard(
            cornerRadius: cornerRadius,
            borderColor: borderColor,
            borderWidth: borderWidth,
            backgroundColor: backgroundColor
        ))
    }
}
