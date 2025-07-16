//
//  SplitBackgroundView.swift
//  PickPle
//
//  Created by 정인선 on 8/15/25.
//

import SwiftUI

// MARK: - 배경 분할 뷰
struct SplitBackgroundView: View {
    let topColor: Color
    let bottomColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 상단 절반
                topColor
                    .frame(height: geometry.size.height / 2)
                
                // 하단 절반
                bottomColor
                    .frame(height: geometry.size.height / 2)
            }
        }
        .ignoresSafeArea()
    }
}
