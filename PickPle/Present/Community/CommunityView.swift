//
//  CommunityView.swift
//  PickPle
//
//  Created by 정인선 on 6/7/25.
//

import SwiftUI

struct CommunityView: View {
    @StateObject var viewModel: CommunityViewModel
    
    var body: some View {
        MainCommunityView(viewModel: viewModel)
        .padding(.top, 20)
        .background(.gray15)
        .task {
            viewModel.action(.fetchData)
        }
        // TODO: sheet
    }
}

struct MainCommunityView: View {
    @ObservedObject var viewModel: CommunityViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                FixedSearchHeaderView()
                
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            SliderSectionView(viewModel: viewModel)
                        }
                        
                        Section {
                            ForEach(viewModel.output.postSummaries, id: \.postId) { post in
                                VStack {
                                    CommunityPostView(post: post)
                                        .padding(20)
                                        .background(.gray15)
                                    
                                    if post != viewModel.output.postSummaries.last {
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundStyle(.gray30)
                                            .padding(.horizontal, 20)
                                            .background(.gray15)
                                    }
                                }
                            }
                        } header: {
                            TimelineHeaderView()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 고정 검색 헤더
struct FixedSearchHeaderView: View {
    @State private var searchText: String = ""
    
    var body: some View {
        HStack(spacing: 10) {
            SearchTextField("검색어를 입력해주세요.", text: $searchText)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.deepSprout)
                    .frame(width: 40, height: 40)
                Image("write")
                    .iconFrame(28)
                    .foregroundStyle(.gray0)
            }
            .wrapToButton {
                print("글 작성하기")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - 슬라이더 섹션
struct SliderSectionView: View {
    @StateObject var viewModel: CommunityViewModel
    
    var body: some View {
        CustomSliderTrack(
            distance: viewModel.output.distance,
            range: viewModel.output.distanceRange,
            onDistanceChange: { newDistance in
                viewModel.action(.updateDistance(newDistance))
            }
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Custom Slider Track
private struct CustomSliderTrack: View {
    @State var distance: Double
    let range: ClosedRange<Double>
    let onDistanceChange: (Double) -> Void
    
    private let segmentCount = 20
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            let stepSize = (range.upperBound - range.lowerBound) / Double(segmentCount)
            let currentSegment = Int(distance / stepSize)
            let sliderWidth = geometry.size.width - 88
            let progress = distance / range.upperBound
            let indicatorPosition = progress * sliderWidth
            
            ZStack(alignment: .top) {
                VStack {
                    Spacer()
                        .frame(height: 20)
                    HStack(spacing: 8) {
                        Text("Distance")
                            .font(.pretendard(.body3))
                            .foregroundColor(.deepSprout)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(.deepSprout)
                                    .background(.brightSprout)
                            )
                        
                        HStack(spacing: 4) {
                            ForEach(0..<segmentCount, id: \.self) { index in
                                let isActive = index < currentSegment
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isActive ? .blackSprout : .brightSprout)
                                    .frame(height: 20)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            distance = Double((index + 1)) * stepSize
                                            onDistanceChange(distance)
                                        }
                                    }
                            }
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    isDragging = true
                                    let segmentWidth = sliderWidth / CGFloat(segmentCount)
                                    let position = gesture.location.x
                                    let segmentIndex = Int(position / segmentWidth)
                                    let clampedIndex = max(0, min(segmentIndex, segmentCount - 1))
                                    
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        distance = Double(clampedIndex + 1) * stepSize
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isDragging = false
                                    }
                                    onDistanceChange(distance)
                                }
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.gray45)
                    )
                }
                
                HStack {
                    Spacer()
                        .frame(width: 80)
                    
                    HStack {
                        // 첫 번째 세그먼트일 때 왼쪽 정렬
                        if currentSegment <= 1 {
                            DistanceDetailView(distance: distance)
                            Spacer()
                        }
                        // 마지막 세그먼트일 때 오른쪽 정렬
                        else if currentSegment >= segmentCount - 1 {
                            HStack {
                                Spacer()
                                DistanceDetailView(distance: distance)
                            }
                        }
                        // 중간일 때 슬라이더 위치를 부드럽게 따라가며 가장자리에서는 조정
                        else {
                            let labelWidth: CGFloat = 80
                            let safeMargin: CGFloat = 20
                            let targetPosition = indicatorPosition - labelWidth/2
                            
                            let minPosition: CGFloat = safeMargin
                            let maxPosition = sliderWidth - labelWidth - safeMargin
                            let finalPosition = max(minPosition, min(maxPosition, targetPosition))
                            
                            HStack(spacing: 0) {
                                Spacer()
                                    .frame(width: finalPosition)
                                DistanceDetailView(distance: distance)
                                Spacer()
                                    .frame(width: sliderWidth - finalPosition - labelWidth)
                            }
                        }
                    }
                    .frame(width: sliderWidth)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(height: 60)
    }
    
    private struct DistanceDetailView: View {
        let distance: Double
        
        var body: some View {
            Text(distance >= 1000 ? String(format: "%.1fKM", distance/1000).replacingOccurrences(of: ".0", with: "") : "\(Int(distance))M")
                .font(.pretendard(.caption2))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.blackSprout)
                )
        }
    }
}


// MARK: - 스티키 타임라인 헤더
struct TimelineHeaderView: View {
    var body: some View {
        HStack(alignment: .center) {
            Text("타임라인")
                .font(.pretendard(.body2))
            Spacer()
            HStack {
                Text("최신순")
                    .font(.pretendard(.caption1))
                Image("list")
                    .iconFrame(16)
            }
            .foregroundStyle(.blackSprout)
            .wrapToButton {
                print("정렬")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.gray15)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray30)
                .padding(.horizontal, 20),
            alignment: .bottom
        )
    }
}

// MARK: - 커뮤니티 포스트
struct CommunityPostView: View {
    let post: PostSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Rectangle()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading) {
                    Text(post.creator.nickname)
                        .font(.pretendard(.caption1))
                        .foregroundStyle(.gray100)
                    Text(post.createdFromNow)
                        .font(.pretendard(.caption2))
                        .foregroundStyle(.gray60)
                }
                Spacer()
            }
            
            StoreGalleryImageView(
                imageUrls: post.files,
                ratio: 5/3,
                isPickchelin: false
            )
            .overlay(alignment: .topLeading) {
                Image(post.isLike ? "like.fill" : "like")
                    .iconFrame(24)
                    .padding(8)
                    .foregroundStyle(true ? .blackSprout : .gray45)
                    .wrapToButton {
                        print("좋아요")
                    }
                    .buttonStyle(.plain)
            }
            
            HStack(spacing: 8) {
                Text(post.title)
                    .font(.pretendard(.body1))
                    .foregroundStyle(.gray100)
                    .lineLimit(1)
                HStack(spacing: 2) {
                    Image("like.fill")
                        .iconFrame(20)
                        .foregroundStyle(.brightForsythia)
                    Text("\(post.likeCount)개")
                        .font(.pretendard(.body1))
                        .foregroundStyle(.gray100)
                }
                HStack(spacing: 2) {
                    Image("distance")
                        .iconFrame(20)
                        .foregroundStyle(.deepSprout)
                    Text("\(post.distance)")
                        .font(.pretendard(.body1))
                        .foregroundStyle(.gray100)
                }
            }
            Text(post.content)
                .font(.pretendard(.caption1))
                .foregroundStyle(.gray60)
            
            HStack(spacing: 0) {
                CachedImageView(imagePath: post.storeImageUrl ?? "", size: CGSize(width: 60, height: 60))
                Rectangle()
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .foregroundStyle(.deepSprout)
                    .padding(.trailing, 10)
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.storeName)
                            .font(.pretendard(.body3))
                            .foregroundStyle(.blackSprout)
                        Text(post.storeInfo)
                            .font(.pretendard(.caption1))
                            .foregroundStyle(.deepSprout)
                    }
                    Spacer()
                }
            }
            .background(.brightSprout)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.deepSprout)
            )
        }
    }
}
