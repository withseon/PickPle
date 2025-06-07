//
//  Image+.swift
//  PickPle
//
//  Created by 정인선 on 5/23/25.
//

import SwiftUI

extension Image {
    func iconFrame(_ size: CGFloat) -> some View {
        self
            .resizable()
            .frame(width: size, height: size)
    }
}

