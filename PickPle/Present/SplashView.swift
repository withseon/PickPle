//
//  SplashView.swift
//  PickPle
//
//  Created by 정인선 on 5/10/25.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(Resource.appLogoWhite)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(.deepSprout)
    }
}

#Preview {
    SplashView()
}
