//
//  ImageCarouselView.swift
//  PickPle
//
//  Created by 정인선 on 6/2/25.
//

import SwiftUI

struct ImageCarouselView: View {
    // 필수 파라미터
    let imageUrls: [String]
    let width: CGFloat?
    let height: CGFloat

    // 페이지 인디케이터 설정
    let showPageIndicator: Bool
    let indicatorBottomPadding: CGFloat

    // 전체 화면 뷰어 활성화
    let enableImageViewer: Bool

    @State private var currentPage = 0

    init(
        imageUrls: [String],
        width: CGFloat? = nil,
        height: CGFloat,
        showPageIndicator: Bool = true,
        indicatorBottomPadding: CGFloat = 40,
        enableImageViewer: Bool = true
    ) {
        self.imageUrls = imageUrls
        self.width = width
        self.height = height
        self.showPageIndicator = showPageIndicator
        self.indicatorBottomPadding = indicatorBottomPadding
        self.enableImageViewer = enableImageViewer
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            imageTabView
            if showPageIndicator {
                pageIndicators
            }
        }
    }

    @ViewBuilder
    private var imageTabView: some View {
        GeometryReader { geometry in
            TabView(selection: $currentPage) {
                ForEach(imageUrls.indices, id: \.self) { index in
                    CachedImageView(
                        imagePath: imageUrls[index],
                        size: CGSize(width: width ?? geometry.size.width, height: height),
                        contentMode: .fill,
                        imageUrls: enableImageViewer ? imageUrls : [],
                        currentIndex: index
                    )
                    .tag(index)
                }
            }
            .frame(width: width ?? geometry.size.width, height: height)
            .clipped()
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .frame(height: height)
    }

    @ViewBuilder
    private var pageIndicators: some View {
        HStack(spacing: 4) {
            ForEach(imageUrls.indices, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.gray0 : Color.gray45)
                    .frame(
                        width: currentPage == index ? 8 : 4,
                        height: currentPage == index ? 8 : 4
                    )
            }
        }
        .padding(.bottom, indicatorBottomPadding)
    }
}
