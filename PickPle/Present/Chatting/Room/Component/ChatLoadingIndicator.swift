//
//  ChatLoadingIndicator.swift
//  PickPle
//
//  Created by 정인선 on 8/12/25.
//

import SwiftUI

struct ChatLoadingIndicator: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.8)
            Text("이전 메시지 로드 중...")
                .font(.pretendard(.caption2))
                .foregroundStyle(.gray60)
            Spacer()
        }
        .padding(.vertical, 16)
        .rotationEffect(.degrees(180))
        .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}
