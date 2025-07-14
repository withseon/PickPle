//
//  CachedImageView.swift
//  PickPle
//
//  Created by 정인선 on 5/23/25.
//

import SwiftUI

struct CachedImageView: View {
    let imagePath: String
    let size: CGSize
    
    @StateObject private var imageLoader = ImageLoader()
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if imageLoader.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ErrorView()
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask(priority: .userInitiated) {
                    await imageLoader.loadImage(from: imagePath, size: size)
                }
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
