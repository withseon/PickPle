//
//  StoreGalleryImageView.swift
//  PickPle
//
//  Created by 정인선 on 5/24/25.
//

import SwiftUI

struct StoreGalleryImageView: View {
    let imageUrls: [String]
    let ratio: CGFloat
    let isPickchelin: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                switch imageUrls.count {
                case 1:
                    singleImageView(
                        urls: imageUrls,
                        geometry: geometry,
                        isPickchelin: isPickchelin
                    )
                case 2:
                    twoImagesView(
                        urls: imageUrls,
                        geometry: geometry,
                        isPickchelin: isPickchelin
                    )
                case 3...:
                    threeImagesView(
                        urls: imageUrls,
                        geometry: geometry,
                        isPickchelin: isPickchelin
                    )
                default:
                    emptyStateView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .aspectRatio(ratio, contentMode: .fit)
    }
    
    // MARK: - 1개 이미지 레이아웃
    private func singleImageView(
        urls: [String],
        geometry: GeometryProxy,
        isPickchelin: Bool
    ) -> some View {
        print(#function)
        return AsyncImageView(url: urls[0], width: geometry.size.width, height: geometry.size.height)
            .cornerRadius(12)
            .overlay(alignment: .topTrailing) {
                PickChelinTagView()
                    .padding(8)
            }
    }
    
    // MARK: - 2개 이미지 레이아웃
    private func twoImagesView(
        urls: [String],
        geometry: GeometryProxy,
        isPickchelin: Bool
    ) -> some View {
        print(#function)
        let width = geometry.size.width - 8
        
        return HStack(spacing: 8) {
            AsyncImageView(url: urls[0], width: width * 0.65, height: geometry.size.height)
                .cornerRadius(12)
                .overlay(alignment: .topTrailing) {
                    if isPickchelin {
                        PickChelinTagView()
                            .padding(8)
                    }
                }
            
            AsyncImageView(url: urls[1], width: width * 0.35, height: geometry.size.height)
                .cornerRadius(12)
        }
    }
    
    // MARK: - 3개 이미지 레이아웃
    private func threeImagesView(
        urls: [String],
        geometry: GeometryProxy,
        isPickchelin: Bool
    ) -> some View {
        print(#function)
        let width = geometry.size.width - 8
        let rightHeight = (geometry.size.height - 8) / 2
        
        return HStack(spacing: 8) {
            AsyncImageView(url: urls[0], width: width * 0.65, height: geometry.size.height)
                .cornerRadius(12)
                .overlay(alignment: .topTrailing) {
                    if isPickchelin {
                        PickChelinTagView()
                            .padding(8)
                    }
                }
            
            VStack(spacing: 8) {
                AsyncImageView(url: urls[1], width: width * 0.35, height: rightHeight)
                    .cornerRadius(12)
                
                AsyncImageView(url: urls[2], width: width * 0.35, height: rightHeight)
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - 이미지 없는 경우
    private func emptyStateView() -> some View {
        print(#function)
        return Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("이미지 준비중입니다.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
            .overlay(alignment: .topTrailing) {
                if isPickchelin {
                    PickChelinTagView()
                        .padding(8)
                }
            }
            .cornerRadius(12)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 8) {
                Text("1개 이미지")
                    .font(.headline)
                StoreGalleryImageView(imageUrls: [
                    "https://picsum.photos/400/300"
                ], ratio: 16/9, isPickchelin: true)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("2개 이미지")
                    .font(.headline)
                StoreGalleryImageView(imageUrls: [
                    "https://picsum.photos/id/1/400/300",
                    "https://picsum.photos/id/2/400/300"
                ], ratio: 16/9, isPickchelin: true)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("3개 이미지")
                    .font(.headline)
                StoreGalleryImageView(imageUrls: [
                    "https://picsum.photos/id/10/400/300",
                    "https://picsum.photos/id/20/400/300",
                    "https://picsum.photos/id/30/400/300"
                ], ratio: 16/9, isPickchelin: true)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("5개 이미지 (처음 3개만 표시)")
                    .font(.headline)
                StoreGalleryImageView(imageUrls: [
                    "https://picsum.photos/id/100/400/300",
                    "https://picsum.photos/id/200/400/300",
                    "https://picsum.photos/id/300/400/300",
                    "https://picsum.photos/id/400/400/300",
                    "https://picsum.photos/id/500/400/300"
                ], ratio: 16/9, isPickchelin: true)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("이미지 없는 경우")
                    .font(.headline)
                StoreGalleryImageView(imageUrls: [], ratio: 16/9, isPickchelin: true)
            }
        }
        .padding()
    }
}
