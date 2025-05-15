//
//  ButtonWrapper.swift
//  PickPle
//
//  Created by 정인선 on 5/10/25.
//

import SwiftUI

private struct ButtonWrapper: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        Button(action: action, label: { content })
    }
}

extension View {
    func wrapToButton(action: @escaping () -> Void) -> some View {
        modifier(ButtonWrapper(action: action))
    }
}
