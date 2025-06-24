//
//  StoreDetailView.swift
//  PickPle
//
//  Created by 정인선 on 6/1/25.
//

import SwiftUI

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { }
}

struct StoreDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: StoreDetailViewModel
    @State private var showNavigationTitle = false
    @State private var topSafeArea: CGFloat = 0
    
    let tabViewHeight: CGFloat = 240
    let stickyHeaderHeight: CGFloat = 60
    let scrollCoordinateSpace: String = "storeDetailScroll"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            Section {
                                HeaderView(
                                    viewModel: viewModel,
                                    tabViewHeight: tabViewHeight,
                                    topSafeArea: topSafeArea
                                )
                                .ignoresSafeArea(.container, edges: .top)
                                .padding(.top, -topSafeArea)
                            } header: {
                                EmptyView()
                            }
                            
                            Section {
                                ForEach(Array(viewModel.output.storeDetailData.categoryList.enumerated()), id: \.offset) { index, category in
                                    MenuSectionView(
                                        selectedCategoryIndex: viewModel.output.selectedCategoryIndex,
                                        categoryIndex: index,
                                        category: category.title,
                                        items: category.menuList,
                                        stickyHeaderHeight: stickyHeaderHeight,
                                        topSafeArea: topSafeArea,
                                        scrollCoordinateSpace: scrollCoordinateSpace,
                                        onCategoryVisible: { categoryIndex in
                                            viewModel.action(.selectCategory(categoryIndex))
                                        }
                                    )
                                    .id(index)
                                }
                            } header: {
                                CategoryHeaderView(
                                    categories: viewModel.output.storeDetailData.categoryList.map { $0.title },
                                    selectedCategoryIndex: viewModel.output.selectedCategoryIndex,
                                    scrollAction: { index in
                                        viewModel.action(.selectCategory(index))
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            scrollProxy.scrollTo(index, anchor: .top)
                                        }
                                    }
                                )
                                .frame(height: stickyHeaderHeight)
                                .background(.gray0)
                            }
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ScrollOffsetPreferenceKey.self,
                                                value: geo.frame(in: .named(scrollCoordinateSpace)).minY)
                            }
                        )
                    }
                    .coordinateSpace(name: scrollCoordinateSpace)
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        let tabViewDisappearedThreshold = -tabViewHeight + 60
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNavigationTitle = value <= tabViewDisappearedThreshold
                        }
                    }
                }
                .onAppear {
                    topSafeArea = geometry.safeAreaInsets.top
                }
                .onChange(of: geometry.safeAreaInsets.top) { newValue in
                    topSafeArea = newValue
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .navigationTitle(showNavigationTitle ? viewModel.output.storeDetailData.name : "")
            .toolbarBackground(showNavigationTitle ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("chevron.left")
                        .iconFrame(32)
                        .foregroundStyle(showNavigationTitle ? .gray100 : .white)
                        .wrapToButton {
                            dismiss()
                        }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image("like")
                        .iconFrame(32)
                        .foregroundStyle(showNavigationTitle ? .gray100 : .white)
                        .wrapToButton {
                            print("좋아요 버튼 클릭")
                        }
                }
            }
            .task {
                viewModel.action(.onAppear)
            }
        }
    }
    
    struct HeaderView: View {
        @ObservedObject var viewModel: StoreDetailViewModel
        @State private var currentPage = 0
        
        let tabViewHeight: CGFloat
        let topSafeArea: CGFloat
        
        private let screenWidth = UIScreen.main.bounds.width
        
        var body: some View {
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    TabView(selection: $currentPage) {
                        ForEach(viewModel.output.storeDetailData.storeImageUrls.indices, id: \.self) { index in
                            CachedAsyncImage(path: viewModel.output.storeDetailData.storeImageUrls[index], width: screenWidth, height: tabViewHeight + topSafeArea)
                                .tag(index)
                        }
                    }
                    .frame(width: screenWidth, height: tabViewHeight + topSafeArea)
                    .clipped()
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    HStack {
                        ForEach(0..<viewModel.output.storeDetailData.storeImageUrls.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? .gray0 : .gray45)
                                .frame(width: currentPage == index ? 8 : 4, height: currentPage == index ? 8 : 4)
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // 가게 정보
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.output.storeDetailData.name)
                            .font(.pretendard(.title))
                            .foregroundStyle(.gray100)
                        if viewModel.output.storeDetailData.isPicchelin {
                            PickChelinTagView()
                        }
                    }
                    HStack(spacing: 12) {
                        MainInfoText(icon: "like.fill", text: "\(viewModel.output.storeDetailData.pickCount)개")
                        MainInfoText(icon: "star.fill", text: viewModel.output.storeDetailData.totalRating, subText: viewModel.output.storeDetailData.totalReviewCount, subIcon: "chevron.right")
                        Spacer()
                        HStack {
                            Image("sparkle")
                                .iconFrame(16)
                                .foregroundStyle(.gray45)
                            Text(viewModel.output.storeDetailData.totalOrderCount)
                                .font(.pretendard(.body3))
                                .foregroundStyle(.gray45)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            DetailInfoText(title: "가게주소", icon: "distance", text: viewModel.output.storeDetailData.address)
                            DetailInfoText(title: "영업시간", icon: "time", text: viewModel.output.storeDetailData.businessHours)
                            DetailInfoText(title: "주차여부", icon: "parking", text: viewModel.output.storeDetailData.parkinGuide)
                        }
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.gray30)
                    )
                    
                    HStack {
                        Image("run")
                            .iconFrame(16)
                        Text(viewModel.output.storeDetailData.estimatedPickupTime)
                            .font(.pretendard(.body3))
                    }
                    .foregroundStyle(.deepSprout)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(.gray0)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.gray30)
                    )
                    PrimaryButton("길찾기") {
                        print("길찾기 버튼 클릭")
                    }
                }
                .padding(.top, 24)
                .padding([.horizontal, .bottom], 20)
                .background(.gray15)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        topTrailingRadius: 20
                    )
                )
                .overlay(alignment: .bottom) {
                    Divider()
                        .background(.deepSprout)
                }
                .padding(.top, -20)
            }
        }
        
        private struct MainInfoText: View {
            let icon: String
            let text: String
            let subText: String?
            let subIcon: String?
            
            init(icon: String, text: String, subText: String? = nil, subIcon: String? = nil) {
                self.icon = icon
                self.text = text
                self.subText = subText
                self.subIcon = subIcon
            }
            
            var body: some View {
                HStack(spacing: 2) {
                    Image(icon)
                        .iconFrame(20)
                        .foregroundStyle(.brightForsythia)
                    Text(text)
                        .font(.pretendard(.body1))
                        .foregroundStyle(.gray90)
                    if let text = subText {
                        Text(text)
                            .font(.pretendard(.body1))
                            .foregroundStyle(.gray60)
                    }
                    if let icon = subIcon {
                        Image(icon)
                            .iconFrame(16)
                            .foregroundStyle(.gray60)
                    }
                }
            }
        }
    }
    
    private struct DetailInfoText: View {
        let title: String
        let icon: String
        let text: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .font(.pretendard(.body2))
                    .foregroundStyle(.gray60)
                HStack(alignment: .top, spacing: 4) {
                    Image(icon)
                        .iconFrame(20)
                        .foregroundStyle(.deepSprout)
                    Text(text)
                        .font(.pretendard(.body2))
                        .foregroundStyle(.gray60)
                }
            }
        }
    }
}

struct CategoryHeaderView: View {
    let categories: [String]
    let selectedCategoryIndex: Int
    let scrollAction: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .frame(width: 48, height: 32)
                        .foregroundStyle(.deepSprout)
                    Image("search")
                        .iconFrame(20)
                        .foregroundStyle(.gray0)
                }
                
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    Text(category)
                        .font(.pretendard(.body2))
                        .fontWeight(selectedCategoryIndex == index ? .bold : .medium)
                        .foregroundColor(selectedCategoryIndex == index ? .blackSprout : .gray30)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedCategoryIndex == index ? .blackSprout : .gray30,
                                        lineWidth: selectedCategoryIndex == index ? 1.5 : 1)
                        )
                        .wrapToButton {
                            scrollAction(index)
                        }
                        .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
    }
}

struct MenuSectionView: View {
    let selectedCategoryIndex: Int
    let categoryIndex: Int
    let category: String
    let items: [StoreDetail.CategoryItem.MenuItem]
    let stickyHeaderHeight: CGFloat
    let topSafeArea: CGFloat
    let scrollCoordinateSpace: String
    let onCategoryVisible: (Int) -> Void
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(category)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                Spacer()
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            let frame = geometry.frame(in: .named(scrollCoordinateSpace))
                            let adjustedMinY = frame.minY
                            let adjustedMaxY = frame.maxY
                            
                            if adjustedMinY <= (topSafeArea + stickyHeaderHeight + 50) &&
                                adjustedMaxY >= (topSafeArea + stickyHeaderHeight) {
                                DispatchQueue.main.async {
                                    onCategoryVisible(categoryIndex)
                                }
                            }
                        }
                        .onChange(of: geometry.frame(in: .named(scrollCoordinateSpace)).minY) { minY in
                            let adjustedMinY = minY
                            
                            if adjustedMinY <= (topSafeArea + stickyHeaderHeight + 50) &&
                                adjustedMinY >= -(topSafeArea + 100) {
                                onCategoryVisible(categoryIndex)
                            }
                        }
                }
            )
            
            ForEach(items, id: \.menuId) { item in
                VStack(spacing: 0) {
                    MenuItemView(menuItem: item)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                    if item != items.last {
                        Divider()
                            .padding(.vertical, 5)
                            .padding(.horizontal, 20)
                    } else {
                        Rectangle()
                            .frame(height: 12)
                            .foregroundStyle(.gray15)
                    }
                }
            }
        }
    }
}

struct MenuItemView: View {
    let menuItem: StoreDetail.CategoryItem.MenuItem
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                ForEach(menuItem.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.pretendard(.caption2))
                        .foregroundStyle(.blackSprout)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.brightSprout)
                        .cornerRadius(4)
                }
            }
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(menuItem.name)
                        .font(.pretendard(.body1))
                        .foregroundStyle(.gray90)
                    Text(menuItem.description)
                        .font(.pretendard(.caption1))
                        .foregroundStyle(.gray60)
                    Text(menuItem.price)
                        .font(.pretendard(.body1))
                        .foregroundStyle(.gray90)
                }
                Spacer()
                ZStack {
                    if let imageUrl = menuItem.menuImageUrl {
                        CachedAsyncImage(path: imageUrl, width: 100, height: 100)
                            .cornerRadius(8)
                    } else {
                        Rectangle()
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                            .foregroundStyle(.brightForsythia)
                    }
                    if menuItem.isSoldOut {
                        Rectangle()
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                            .foregroundStyle(.gray100.opacity(0.5))
                        
                        Text("품절")
                            .font(.pretendard(.body1))
                            .foregroundStyle(.gray0)
                    }
                }
            }
        }
    }
}
