//
//  PickChelinTagView.swift
//  PickPle
//
//  Created by 정인선 on 5/23/25.
//

import SwiftUI

struct PickChelinTagView: View {
    var body: some View {
        Image("pickchelinTag")
            .overlay {
                HStack(spacing: 0) {
                    Image("pick.fill")
                        .resizable()
                        .frame(width: 12, height: 12)
                    Text("픽슐랭")
                        .font(.pretendard(.caption2))
                }
                .foregroundStyle(.white)
            }
    }
}
