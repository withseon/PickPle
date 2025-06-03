//
//  MainView.swift
//  PickPle
//
//  Created by 정인선 on 5/20/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        if UserDefaults.standard.bool(forKey: "isHaveLocation") {
            Text("위치가 설정되어있다네")
        } else {
            InitialLocationSettingView()
        }
    }
}

#Preview {
    MainView()
}
