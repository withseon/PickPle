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
    @ObservedObject var viewModel: StoreDetailViewModel
    @State private var selectedCategory = "검색한 메뉴"
    @State private var showNavigationTitle = false
    @State private var topSafeArea: CGFloat = 0
    
    let categories = ["검색한 메뉴", "인기메뉴", "수제도넛", "수제 젤리"]
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
                                HeaderView(tabViewHeight: tabViewHeight, topSafeArea: topSafeArea)
                                    .ignoresSafeArea(.container, edges: .top)
                                    .padding(.top, -topSafeArea)
                            } header: {
                                EmptyView()
                            }
                            
                            Section {
                                ForEach(viewModel.output.storeDetailData.menuCategory, id: \.self) { category in
                                    MenuSectionView(
                                        selectedCategory: $selectedCategory,
                                        category: category,
                                        items: StoreDetail.sampleData.MenuList,
                                        stickyHeaderHeight: stickyHeaderHeight,
                                        topSafeArea: topSafeArea,
                                        scrollCoordinateSpace: scrollCoordinateSpace
                                    )
                                    .id(category)
                                }
                            } header: {
                                CategoryHeaderView(
                                    categories: categories,
                                    selectedCategory: $selectedCategory,
                                    scrollAction: { category in
                                        selectedCategory = category
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            scrollProxy.scrollTo(category, anchor: .top)
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .navigationTitle(showNavigationTitle ? "새싹 도넛 가게" : "")
            .toolbarBackground(showNavigationTitle ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("chevron.left")
                        .iconFrame(32)
                        .foregroundStyle(showNavigationTitle ? .gray100 : .white)
                        .wrapToButton {
                            print("뒤로가기 버튼 클릭")
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
        @State private var currentPage = 0
        
        let tabViewHeight: CGFloat
        let topSafeArea: CGFloat
        
        var body: some View {
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    TabView(selection: $currentPage) {
                        ForEach(0..<3) { index in
                            // TODO: CachedAsyncImage
                            if index == 1 {
                                Rectangle()
                                    .foregroundStyle(.red)
                            } else {
                                Rectangle()
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .frame(height: tabViewHeight + topSafeArea)
                    .frame(maxWidth: .infinity)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    HStack {
                        ForEach(0..<3, id: \.self) { index in
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
                        Text("새싹 도넛 가게")
                            .font(.pretendard(.title))
                            .foregroundStyle(.gray100)
                        PickChelinTagView()
                    }
                    HStack {
                        MainInfoText(icon: "like.fill", text: "202개")
                        MainInfoText(icon: "star.fill", text: "4.8", subText: "(211)", subIcon: "chevron.right")
                        Spacer()
                        HStack {
                            Image("sparkle")
                                .iconFrame(16)
                                .foregroundStyle(.gray45)
                            Text("누적 주문 135회")
                                .font(.pretendard(.body3))
                                .foregroundStyle(.gray45)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            DetailInfoText(title: "가게주소", icon: "distance", text: "서울 영등포구 선유로9길 30 106동")
                            DetailInfoText(title: "영업시간", icon: "time", text: "매일 10:00 AM ~ 7:00 PM")
                            DetailInfoText(title: "주차여부", icon: "parking", text: "매장 앞 평행 주차 가능")
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
                        Text("예상 소요시간 30분 (3.2km)")
                            .font(.pretendard(.body3))
                    }
                    .foregroundStyle(.deepSprout)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(.gray0)
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
            HStack(spacing: 0) {
                Text(title)
                    .font(.pretendard(.body2))
                    .foregroundStyle(.gray60)
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

struct CategoryHeaderView: View {
    let categories: [String]
    @Binding var selectedCategory: String
    let scrollAction: (String) -> Void
    
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
                
                ForEach(categories, id: \.self) { category in
                    Text(category)
                        .font(.pretendard(.body2))
                        .fontWeight(selectedCategory == category ? .bold : .medium)
                        .foregroundColor(selectedCategory == category ? .blackSprout : .gray30)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedCategory == category ? .blackSprout : .gray30,
                                        lineWidth: selectedCategory == category ? 1.5 : 1)
                        )
                        .wrapToButton {
                            scrollAction(category)
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
    @Binding var selectedCategory: String
    
    let category: String
    let items: [StoreDetail.Menu]
    let stickyHeaderHeight: CGFloat
    let topSafeArea: CGFloat
    let scrollCoordinateSpace: String
    
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
                                    selectedCategory = category
                                }
                            }
                        }
                        .onChange(of: geometry.frame(in: .named(scrollCoordinateSpace)).minY) { minY in
                            let adjustedMinY = minY
                            
                            if adjustedMinY <= (topSafeArea + stickyHeaderHeight + 50) &&
                               adjustedMinY >= -(topSafeArea + 100) {
                                selectedCategory = category
                            }
                        }
                }
            )

            ForEach(items, id: \.menuId) { item in
                VStack(spacing: 0) {
                    MenuItemView()
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
    var body: some View {
        VStack(alignment: .leading) {
            Text("인기 1위")
                .font(.pretendard(.caption2))
                .foregroundStyle(.blackSprout)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.brightSprout)
                .cornerRadius(4)
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("올리브 그린 도넛")
                        .font(.pretendard(.body1))
                        .foregroundStyle(.gray90)
                    Text("겉은 바삭하고 속은 촉촉하며, 한 입 베어물면 향긋한 허브향이 입 안 가득 퍼집니다.")
                        .font(.pretendard(.caption1))
                        .foregroundStyle(.gray60)
                        .lineLimit(2)
                    Text("3,200원")
                        .font(.pretendard(.body1))
                        .foregroundStyle(.gray90)
                }
                Spacer()
                ZStack {
                    // TODO: CachedAsyncImage
                    Rectangle()
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                        .foregroundStyle(.yellow)
                    // TODO: 품절 처리
                    if true {
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
