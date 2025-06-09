//
//  AsyncImageView.swift
//  PickPle
//
//  Created by 정인선 on 5/23/25.
//

import SwiftUI

struct AsyncImageView: View {
    let url: String
    let width: CGFloat
    let height: CGFloat
    
    init(url: String, width: CGFloat, height: CGFloat) {
        self.url = url
        self.width = width
        self.height = height
    }
    
    var body: some View {
        let imageUrl = URL(string: url)
        
        AsyncImage(url: imageUrl) { data in
            switch data {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure(_):
                errorView()
            @unknown default:
                errorView()
            }
        }
        .frame(width: width, height: height)
        .frame(minWidth: width)
        .clipped()
    }
}

private struct errorView: View {
    var body: some View {
        Color.gray60.opacity(0.2)
            .overlay(
                Image(systemName: "questionmark.circle")
                    .scaledToFit()
                    .foregroundStyle(.gray)
            )
    }
}

#Preview {
    AsyncImageView(url: "https://picsum.photos/id/237/200/300", width: 200, height: 150)
    AsyncImageView(url: "https://picsum.photos/id", width: 200, height: 150)
    AsyncImageView(url: "", width: 200, height: 150)
        .border(.red)
}
