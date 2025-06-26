//
//  CachedAsyncImage.swift
//  PickPle
//
//  Created by 정인선 on 5/23/25.
//

import SwiftUI

// MARK: - Custom Async Image View
struct CachedAsyncImage: View {
    let path: String
    let width: CGFloat
    let height: CGFloat
    
    @StateObject private var imageLoader = ImageLoader()
    
    init(path: String, width: CGFloat, height: CGFloat) {
        self.path = path
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            if imageLoader.isLoading {
                ProgressView()
            } else if let uiImage = imageLoader.image {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ErrorView()
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .onAppear {
            Task {
                await imageLoader.loadImage(from: path, size: CGSize(width: width, height: height))
            }
        }
    }
    
    private struct ErrorView: View {
        var body: some View {
            Color.gray.opacity(0.2)
                .overlay(
                    Image(systemName: "questionmark.circle")
                        .scaledToFit()
                        .foregroundStyle(.gray)
                )
        }
    }
}
