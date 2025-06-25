//
//  CommunityView.swift
//  PickPle
//
//  Created by 정인선 on 6/7/25.
//

import SwiftUI

struct CommunityView: View {
    
    var body: some View {
        Section {
            ForEach(0..<10) { _ in
                CommunityPostView()
            }
        } header: {
            CommunityHeaderView()
        }

    }
}

struct CommunityHeaderView: View {
    @State private var distance: Double = 300
    @State private var searchText: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 10) {
                SearchTextField("검색어를 입력해주세요.", text: $searchText)
                Image("write")
                    .iconFrame(28)
                    .foregroundStyle(.gray0)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.deepSprout)
                            .frame(width: 40, height: 40)
                    )
                    .wrapToButton {
                        print("글 작성하기")
                    }
            }
            .padding(.horizontal, 20)
            
            CustomSliderTrack(value: $distance, range: 0...1000)
                .padding(.horizontal, 20)
            
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
                    print("정렬ㄴ")
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private struct CustomSliderTrack: View {
        @Binding var value: Double
        let range: ClosedRange<Double>
        
        private let segmentCount = 20
        @State private var isDragging = false
        
        var body: some View {
            GeometryReader { geometry in
                let stepSize = (range.upperBound - range.lowerBound) / Double(segmentCount)
                let currentSegment = Int(value / stepSize)
                let sliderWidth = geometry.size.width - 88
                let progress = value / range.upperBound
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
                                                value = Double((index + 1)) * stepSize
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
                                            value = Double(clampedIndex + 1) * stepSize
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isDragging = false
                                        }
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
                                DistanceDetailView(distance: value)
                                Spacer()
                            }
                            // 마지막 세그먼트일 때 오른쪽 정렬
                            else if currentSegment >= segmentCount - 1 {
                                HStack {
                                    Spacer()
                                    DistanceDetailView(distance: value)
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
                                    DistanceDetailView(distance: value)
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
                Text(distance >= 1000 ? String(format: "%.1fkm", distance/1000).replacingOccurrences(of: ".0", with: "") : "\(Int(distance))M")
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
}

struct CommunityPostView: View {
    var body: some View {
        Text("example")
    }
}

#Preview {
    CommunityView()
}
