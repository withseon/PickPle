//
//  StoreDetailView.swift
//  PickPle
//
//  Created by 정인선 on 6/1/25.
//

import SwiftUI

struct MenuItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let price: String
    let image: String
    let isRecommended: Bool
    
    init(name: String, description: String, price: String, image: String, isRecommended: Bool = false) {
        self.name = name
        self.description = description
        self.price = price
        self.image = image
        self.isRecommended = isRecommended
    }
}

struct StoreDetailView: View {
    @ObservedObject var viewModel: StoreDetailViewModel
    @State private var selectedCategory = "검색한 메뉴"
    @State private var showNavigationTitle = false
    @State private var scrollOffset: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    
    let categories = ["검색한 메뉴", "인기메뉴", "수제도넛", "수제 젤리"]
    let stickyHeaderHeight: CGFloat = 60
    
    let menuData = [
        "검색한 메뉴": [
            MenuItem(name: "올리브 그린 도넛", description: "깔끔 바삭하고 촉촉한 촉촉하며, 한 입 베어물면 향긋한 허브향이 입 안 가득 퍼집니다.", price: "3,200원", image: "donut1"),
            MenuItem(name: "올리브 츄이스티 도넛", description: "올리브 오일을 듬뿍 사용한 반죽은 고소하면서도, 속으로 들어가는 재미까지 느낄 수 있어요.", price: "3,700원", image: "donut2")
        ],
        "인기메뉴": [
            MenuItem(name: "올리브 그린 도넛", description: "깔끔 바삭하고 촉촉한 촉촉하며, 한 입 베어물면 향긋한 허브향이 입 안 가득 퍼집니다.", price: "3,200원", image: "donut1"),
            MenuItem(name: "레몬 민트 도넛", description: "유기농 레몬 제스트와 민트를 넣은 반죽에, 새콤달콤 더욱 달콤한 전기 안 맛있습니다.", price: "3,600원", image: "donut3")
        ],
        "수제도넛": [
            MenuItem(name: "팥팥 도넛", description: "전통 팥 앙금을 사용한 건강한 도넛", price: "3,800원", image: "donut4"),
            MenuItem(name: "초코 도넛", description: "진한 초콜릿의 달콤함", price: "3,500원", image: "donut5")
        ],
        "수제 젤리": [
            MenuItem(name: "딸기 젤리", description: "상큼한 딸기맛 젤리", price: "2,500원", image: "jelly1"),
            MenuItem(name: "포도 젤리", description: "달콤한 포도맛 젤리", price: "2,500원", image: "jelly2")
        ]
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            HeaderView()
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(key: ScrollOffsetPreferenceKey.self,
                                                        value: geo.frame(in: .named("scroll")).minY)
                                            .onAppear {
                                                headerHeight = geo.size.height
                                            }
                                    }
                                )
                        } header: {
                            EmptyView()
                        }
                        
                        Section {
                            ForEach(categories, id: \.self) { category in
                                MenuSectionView(
                                    category: category,
                                    items: menuData[category] ?? [],
                                    selectedCategory: $selectedCategory,
                                    stickyHeaderHeight: stickyHeaderHeight
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
                                        scrollProxy.scrollTo(category, anchor: UnitPoint(x: 0.5, y: 0.1))
                                    }
                                }
                            )
                            .frame(height: stickyHeaderHeight)
                            .background(Color.white)
                        }
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    // 스크롤이 충분히 되었을 때 네비게이션 타이틀 표시
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showNavigationTitle = value > 100
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .navigationTitle(showNavigationTitle ? "새싹 도넛 가게" : "")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "chevron.left")
                    .iconFrame(32)
                    .foregroundStyle(.gray100)
                    .wrapToButton {
                        print("뒤로가기 버튼 클릭")
                    }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Image("like")
                    .iconFrame(32)
                    .foregroundStyle(.gray100)
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
                .frame(height: 240)
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
    let category: String
    let items: [MenuItem]
    @Binding var selectedCategory: String
    let stickyHeaderHeight: CGFloat
    
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
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            let frame = geo.frame(in: .named("scroll"))
                            if frame.minY <= stickyHeaderHeight + 50 && frame.maxY >= stickyHeaderHeight {
                                DispatchQueue.main.async {
                                    selectedCategory = category
                                }
                            }
                        }
                        .onChange(of: geo.frame(in: .named("scroll")).minY) { minY in
                            if minY <= stickyHeaderHeight + 50 && minY >= -100 {
                                selectedCategory = category
                            }
                        }
                }
            )
            
            ForEach(items) { item in
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

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { }
}

#Preview {
    StoreDetailView(viewModel: StoreDetailViewModel(storeRepository: DefaultStoreRepository(networkManager: NetworkManager()), storeId: "68232afbca81ef0db5a46475"))
}
