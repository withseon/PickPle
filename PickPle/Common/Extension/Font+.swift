//
//  Font+.swift
//  PickPle
//
//  Created by 정인선 on 5/10/25.
//

import SwiftUI

extension Font {
    enum PretendardWeight {
        case title, body1, body2, body3, caption1, caption2, caption3
    }
    
    enum JalnanGothicStyle {
        case title, body, caption
    }
    
    static func pretendard(_ weight: PretendardWeight) -> Font {
        switch weight {
        case .title:
            return .custom("Pretendard-Bold", size: 22)
        case .body1:
            return .custom("Pretendard-Medium", size: 16)
        case .body2:
            return .custom("Pretendard-Medium", size: 14)
        case .body3:
            return .custom("Pretendard-Medium", size: 13)
        case .caption1:
            return .custom("Pretendard-Regular", size: 12)
        case .caption2:
            return .custom("Pretendard-Regular", size: 10)
        case .caption3:
            return .custom("Pretendard-Regular", size: 8)
        }
    }
    
    static func jalnangothic(_ weight: JalnanGothicStyle) -> Font {
        switch weight {
        case .title:
            return .custom("JalnanGothicTTF", size: 24)
        case .body:
            return .custom("JalnanGothicTTF", size: 20)
        case .caption:
            return .custom("JalnanGothicTTF", size: 14)
        }
    }
}
