//
//  CommunityView.swift
//  PickPle
//
//  Created by 정인선 on 6/7/25.
//

import SwiftUI

struct CommunityView: View {
    @StateObject var viewModel: CommunityViewModel
    @EnvironmentObject var communityCoordinator: CommunityCoordinator
    @State private var hasInitialLoad = false // 초기 로드 여부 추적
    
    var body: some View {
        MainCommunityView(viewModel: viewModel, communityCoordinator: communityCoordinator)
            .padding(.top, 20)
            .background(.gray15)
            .onAppear {
                // 최초 로드시에만 데이터 페치
                if !hasInitialLoad {
                    viewModel.action(.fetchData)
                    hasInitialLoad = true
                }
            }
            .handleErrors(viewModel: viewModel)
    }
}

struct MainCommunityView: View {
    @ObservedObject var viewModel: CommunityViewModel
    @ObservedObject var communityCoordinator: CommunityCoordinator
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                FixedSearchHeaderView(communityCoordinator: communityCoordinator)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        Section {
                            SliderSectionView(viewModel: viewModel)
                        }

                        Section {
                            if viewModel.output.postSummaries.isEmpty {
                                // 게시글이 없을 때 표시할 뷰
                                CommunityEmptyStateView()
                                    .padding(.top, 80)
                                    .background(.gray15)
                            } else {
                                // 게시글이 있을 때 표시할 리스트
                                ForEach(viewModel.output.postSummaries, id: \.self.postId) { post in
                                    VStack {
                                        CommunityPostView(post: post)
                                            .padding(20)
                                            .background(.gray15)
                                            .onAppear {
                                                if post == viewModel.output.postSummaries.last {
                                                    viewModel.action(.pagination)
                                                }
                                            }

                                        if post != viewModel.output.postSummaries.last {
                                            Rectangle()
                                                .frame(height: 1)
                                                .foregroundStyle(.gray30)
                                                .padding(.horizontal, 20)
                                                .background(.gray15)
                                        }
                                    }
                                }
                            }
                        } header: {
                            if !viewModel.output.postSummaries.isEmpty {
                                TimelineHeaderView()
                            }
                        }
                    }
                }
                .refreshable {
                    viewModel.action(.fetchData)
                }
            }
        }
    }
}

// MARK: - 고정 검색 헤더
struct FixedSearchHeaderView: View {
    @State private var searchText: String = ""
    @ObservedObject var communityCoordinator: CommunityCoordinator
    
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
                communityCoordinator.push(.createPost)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - 슬라이더 섹션
struct SliderSectionView: View {
    @ObservedObject var viewModel: CommunityViewModel

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
                            .foregroundStyle(.deepSprout)
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
                .foregroundStyle(.gray0)
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

    private func storeInfoText(for post: PostSummary) -> String {
        let address = post.geolocation.address
        return address.isEmpty ? post.category : "\(post.category) • \(address)"
    }

    var body: some View {
        NavigationLink(value: CommunityRoute.postDetail(post.postId)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if let profileImage = post.creator.profileImage {
                        CachedImageView(imagePath: profileImage, size: CGSize(width: 32, height: 32))
                            .clipShape (
                                Circle()
                            )
                    } else {
                        Image("empty_profile")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .clipShape(
                                Circle()
                            )
                    }
                    VStack(alignment: .leading) {
                        Text(post.creator.nickname)
                            .font(.pretendard(.caption1))
                            .foregroundStyle(.gray100)
                        Text(post.createdFromNow)
                            .font(.pretendard(.caption2))
                            .foregroundStyle(.gray60)
                    }
                    Spacer()
                    Image(post.isLike ? "like.fill" : "like")
                        .iconFrame(24)
                        .padding(8)
                        .foregroundStyle(true ? .blackSprout : .gray45)
                        .wrapToButton {
                            print("좋아요")
                        }
                        .buttonStyle(.plain)
                }
                
                if !post.files.isEmpty {
                    StoreGalleryImageView(
                        imageUrls: post.files,
                        ratio: 5/3,
                        isPickchelin: false
                    )
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
                    .lineLimit(5)
                
                // MARK: - 가게 정보
                if !post.storeId.isEmpty {
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
                                Text(storeInfoText(for: post))
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
        .buttonStyle(.plain)
    }
}

// MARK: - 게시글 없음 안내 뷰
struct CommunityEmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("근처에 게시글이 없습니다")
                .font(.pretendard(.body1))
                .foregroundStyle(.gray60)
            
            Text("다른 지역을 확인해보거나\n첫 번째 게시글을 작성해보세요!")
                .font(.pretendard(.caption1))
                .foregroundStyle(.gray45)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
