//
//  CustomBackButton.swift
//  PickPle
//
//  Created by 정인선 on 10/2/25.
//

import SwiftUI

// MARK: - Custom Back Button
struct BackButton: View {
    let color: Color
    let action: () -> Void

    init(color: Color = .blackSprout, action: @escaping () -> Void) {
        self.color = color
        self.action = action
    }

    var body: some View {
        Image("chevron.left")
            .iconFrame(32)
            .foregroundStyle(color)
            .wrapToButton {
                action()
            }
    }
}

// MARK: - Back Button Modifier
struct BackButtonModifier: ViewModifier {
    let color: Color
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(color: color, action: action)
                }
            }
    }
}

// MARK: - View Extension
extension View {
    func addBackButton(color: Color = .blackSprout, action: @escaping () -> Void) -> some View {
        self.modifier(BackButtonModifier(color: color, action: action))
    }
}

// MARK: - UINavigationController Extension for Swipe Back
//extension UINavigationController: UIGestureRecognizerDelegate {
//    override open func viewDidLoad() {
//        super.viewDidLoad()
//        interactivePopGestureRecognizer?.delegate = self
//    }
//
//    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        return viewControllers.count > 1
//    }
//}
