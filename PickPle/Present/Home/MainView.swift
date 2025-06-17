//
//  MainView.swift
//  PickPle
//
//  Created by 정인선 on 5/20/25.
//

import SwiftUI

enum PickFilter: CaseIterable {
    case pickchelin, myPick
    
    var title: String {
        switch self {
        case .pickchelin:
            return "픽슐랭"
        case .myPick:
            return "MY PICK"
        }
    }
}

struct MainView: View {
    @StateObject var viewModel: MainViewModel
    
    var body: some View {
        if let _ = UserDefaultsManager.selectedLocation {
            MainContentView(viewModel: viewModel)
                .task {
                    viewModel.action(.onAppear)
                }
                .onDisappear {
                    viewModel.action(.onDisappear)
                }
        } else {
            InitialLocationSettingView()
        }
    }
}

private struct MainContentView: View {
    @ObservedObject var viewModel: MainViewModel
    @State var searchText = ""
    
    var body: some View {
        VStack(spacing: 8) {
            LocationAndSearchView(viewModel: viewModel)
            StoreListView(viewModel: viewModel)
            .refreshable {
                print("새로고침")
            }
        }
        .background(.brightSprout)
        .sheet(isPresented: $viewModel.output.showMapSheet) {
            MapView(locationManager: viewModel.locationManager) {
                viewModel.action(.selectedLocation)
            }
        }
        .sheet(isPresented: $viewModel.output.showOrderSheet) {
            VStack(alignment: .center) {
                ForEach(StoreOrder.allCases, id: \.self) { item in
                    Text(item.title)
                        .font(.pretendard(.body1))
                        .padding()
                        .foregroundStyle(viewModel.output.selectedOrder == item ? .blackSprout : .gray100)
                        .onTapGesture { _ in
                            viewModel.action(.selectedOrder(item))
                        }
                    if item != StoreOrder.allCases.last {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.gray30)
                            .padding(.horizontal, 20)
                    }
                }
            }
            .presentationDetents([.fraction(0.3)])
        }
    }
}

// MARK: - 위치 & 검색 뷰
private struct LocationAndSearchView: View {
    @ObservedObject var viewModel: MainViewModel
    @State var searchText = ""
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                LocationButton(address: viewModel.output.address)
                    .wrapToButton {
                        viewModel.action(.mapSheet)
                    }
                    .buttonStyle(.plain)
                Spacer()
            }
            SearchTextField("검색어를 입력해주세요", text: $searchText)
            SearchListView(viewModel: viewModel)
                .wrapToButton {
                    // TODO: 검색 결과 이동
                }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
    
    // MARK: - 현재 위치 선택 버튼
    private struct LocationButton: View {
        let address: String
        
        var body: some View {
            HStack {
                Image("location")
                    .iconFrame(24)
                Text(address)
                    .font(.pretendard(.body1))
                Image("detail")
                    .iconFrame(24)
            }
            .foregroundStyle(.black)
        }
    }
    
    // MARK: - 인기검색어 뷰
    private struct SearchListView: View {
        @ObservedObject var viewModel: MainViewModel
        
        var body: some View {
            HStack(spacing: 8) {
                HStack(spacing: 0) {
                    Image("sparkle")
                        .iconFrame(12)
                    Text("인기검색어")
                        .font(.pretendard(.caption1))
                }
                .foregroundStyle(.deepSprout)
                Text(viewModel.output.searchPopular)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.output.searchPopular)

                    .font(.pretendard(.caption1))
                    .foregroundStyle(.blackSprout)
                Spacer()
            }
        }
    }
}

// MARK: - 가게 리스트 뷰
private struct StoreListView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.output.storeSummaries, id: \.storeId) { store in
                    VStack(spacing: 0) {
                        StoreView(viewModel: viewModel, store: store)
                            .padding(20)
                            .onAppear {
                                if !viewModel.output.storeSummaries.isEmpty,
                                   store == viewModel.output.storeSummaries.last {
                                    viewModel.action(.pagination)
                                }
                            }
                        if store != viewModel.output.storeSummaries.last {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(.gray30)
                                .padding(.horizontal, 20)
                        }
                    }
                    .background(.gray15)
                }
            } header: {
                StoreHeaderView(viewModel: viewModel)
            }
            .background(.clear)
            .listRowInsets(.init())
            .listRowSeparator(.hidden)
        }
        .listStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - 헤더 뷰
private struct StoreHeaderView: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                ForEach(StoreCategory.allCases, id: \.self) { category in
                    CategoryButton(viewModel: viewModel, category: category)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            
            VStack {
                if !viewModel.output.popularStores.isEmpty {
                    HStack {
                        Text("실시간 인기 맛집")
                            .font(.pretendard(.body2))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(viewModel.output.popularStores, id: \.storeId) { store in
                                PopularStoreView(viewModel: viewModel, store: store)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .scrollIndicators(.never)
                }
            }
            
            VStack(spacing: 8) {
                HStack(alignment: .center) {
                    Text("픽업 가게")
                        .font(.pretendard(.body2))
                    Spacer()
                    HStack {
                        Text(viewModel.output.selectedOrder.title)
                            .font(.pretendard(.caption1))
                        Image("list")
                            .iconFrame(16)
                    }
                    .foregroundStyle(.blackSprout)
                    .wrapToButton {
                        viewModel.action(.orderSheet)
                    }
                }
                
                HStack(spacing: 12) {
                    ForEach(PickFilter.allCases, id: \.self) { filter in
                        PickStoreFilterButton(viewModel: viewModel, filter: filter)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical)
        .background(.gray15)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                topTrailingRadius: 20
            )
        )
    }
    
    // MARK: - 카데고리 버튼
    private struct CategoryButton: View {
        @ObservedObject var viewModel: MainViewModel
        let category: StoreCategory
        
        var body: some View {
            let isSelected = viewModel.output.selectedCategory == category
            
            VStack(alignment: .center) {
                Image(category.icon)
                    .renderingMode(.original)
                    .frame(width: 56, height: 56)
                    .background(.gray0)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? .blackSprout : .gray30, lineWidth: isSelected ? 1.5 : 1)
                    )
                
                Text(category.title)
                    .font(.pretendard(.body3))
                    .foregroundStyle(isSelected ? .blackSprout : .gray60)
            }
            .frame(maxWidth: .infinity)
            .wrapToButton {
                viewModel.action(.selectedCategory(category))
            }
        }
    }
    
    // MARK: - 픽업 가게 필터 버튼
    struct PickStoreFilterButton: View {
        @ObservedObject var viewModel: MainViewModel
        var filter: PickFilter
        
        var body: some View {
            let isSelected = viewModel.output.selectedPickFilters.contains(filter)
            HStack(spacing: 4) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "checkmark.square")
                Text(filter.title)
                    .font(.pretendard(.caption1))
            }
            .foregroundStyle(isSelected ? .blackSprout : .brightSprout)
            .wrapToButton {
                viewModel.action(.selectedPickFilter(filter))
            }
        }
    }
}

// MARK: - 실시간 인기 가게 셀
private struct PopularStoreView: View {
    @ObservedObject var viewModel: MainViewModel
    let store: PopularStore
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(path: store.mainImageUrl, width: 240, height: 176)
                .clipShape(TopLeftInverseCurveRectangle(cornerRadius: 16))
                .overlay(alignment: .topLeading) {
                    Image(store.isPick ? "like.fill" : "like")
                        .iconFrame(24)
                        .padding(4)
                        .foregroundStyle(store.isPick ? .blackSprout : .gray45)
                        .wrapToButton {
                            viewModel.action(.likeStore(store.storeId, store.isPick))
                        }
                        .buttonStyle(.plain)
                }
                .overlay(alignment: .topTrailing) {
                    if store.isPicchelin {
                        PickChelinTagView()
                            .padding(8)
                    }
                }
            VStack {
                HStack {
                    Text(store.name)
                        .lineLimit(1)
                        .font(.pretendard(.body3))
                    HStack(spacing: 0) {
                        Image("like.fill")
                            .iconFrame(16)
                            .foregroundStyle(.brightForsythia)
                        Text("\(store.pickCount)개")
                            .font(.pretendard(.body3))
                    }
                    Spacer()
                }
                HStack {
                    DetailInfoText(icon: "distance", text: store.distance)
                    DetailInfoText(icon: "time", text: store.close)
                    DetailInfoText(icon: "run", text: store.totalOrderCount)
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
            .frame(width: 240, height: 56)
            .background(.gray0)
        }
        .frame(width: 240, height: 176)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    struct DetailInfoText: View {
        let icon: String
        let text: String
        
        var body: some View {
            HStack(spacing: 0) {
                Image(icon)
                    .iconFrame(16)
                    .foregroundStyle(.blackSprout)
                Text(text)
                    .font(.pretendard(.body3))
                    .foregroundStyle(.gray75)
            }
        }
    }
    
    private struct TopLeftInverseCurveRectangle: Shape {
        var cornerRadius: CGFloat = 0
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            let width = rect.size.width
            let height = rect.size.height
            let corner = cornerRadius
            
            path.move(to: CGPoint(x: 0, y: corner * 2))
            
            // 왼쪽 아래로
            if corner > 0 {
                path.addLine(to: CGPoint(x: 0, y: height - corner * 2))
                path.addQuadCurve(
                    to: CGPoint(x: corner * 2, y: height),
                    control: CGPoint(x: 0, y: height)
                )
            } else {
                path.addLine(to: CGPoint(x: 0, y: height))
            }
            
            // 아래쪽 오른쪽으로
            if corner > 0 {
                path.addLine(to: CGPoint(x: width - corner * 2, y: height))
                path.addQuadCurve(
                    to: CGPoint(x: width, y: height - corner * 2),
                    control: CGPoint(x: width, y: height)
                )
            } else {
                path.addLine(to: CGPoint(x: width, y: height))
            }
            
            // 오른쪽 위로
            if corner > 0 {
                path.addLine(to: CGPoint(x: width, y: corner))
                path.addQuadCurve(
                    to: CGPoint(x: width - corner, y: 0),
                    control: CGPoint(x: width, y: 0)
                )
            } else {
                path.addLine(to: CGPoint(x: width, y: 0))
            }
            
            // 안으로 들어가는 라운드
            if corner > 0 {
                path.addLine(to: CGPoint(x: corner * 3, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: corner * 2, y: corner),
                    control: CGPoint(x: corner * 2, y: 0)
                )
                path.addQuadCurve(
                    to: CGPoint(x: corner, y: corner * 2),
                    control: CGPoint(x: corner * 2, y: corner * 2)
                )
                path.addQuadCurve(
                    to: CGPoint(x: 0, y: corner * 3),
                    control: CGPoint(x: 0, y: corner * 2)
                )
            } else {
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: corner))
            }
            
            return path
        }
    }
}

// MARK: - 가게 리스트 셀
private struct StoreView: View {
    @ObservedObject var viewModel: MainViewModel
    let store: StoreSummary
    
    var body: some View {
        VStack {
            StoreGalleryImageView(
                imageUrls: store.storeImageUrls,
                ratio: 5/2,
                isPickchelin: store.isPicchelin
            )
            .overlay(alignment: .topLeading) {
                Image(store.isPick ? "like.fill" : "like")
                    .iconFrame(24)
                    .padding(8)
                    .foregroundStyle(store.isPick ? .blackSprout : .gray45)
                    .wrapToButton {
                        viewModel.action(.likeStore(store.storeId, store.isPick))
                    }
                    .buttonStyle(.plain)
            }
            VStack {
                HStack {
                    Text(store.name)
                        .lineLimit(1)
                        .font(.pretendard(.body1))
                    MainInfoText(icon: "like.fill", text: "\(store.pickCount)개")
                    MainInfoText(icon: "like.fill", text: store.totalRating, subText: store.totalReviewCount)
                    Spacer()
                }
                HStack {
                    DetailInfoText(icon: "distance", text: store.distance)
                    DetailInfoText(icon: "time", text: store.close)
                    DetailInfoText(icon: "run", text: store.totalOrderCount)
                    Spacer()
                }
            }
            HStack {
                ForEach(store.hashTags, id: \.self) { hasTag in
                    Text(hasTag)
                        .font(.pretendard(.caption1))
                        .foregroundStyle(.gray0)
                        .padding(4)
                        .background(.deepSprout)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
            }
        }
    }
    
    private struct MainInfoText: View {
        let icon: String
        let text: String
        let subText: String?
        
        init(icon: String, text: String, subText: String? = nil) {
            self.icon = icon
            self.text = text
            self.subText = subText
        }
        
        var body: some View {
            HStack(spacing: 0) {
                Image(icon)
                    .iconFrame(20)
                    .foregroundStyle(.brightForsythia)
                Text(text)
                    .font(.pretendard(.body1))
                if let text = subText {
                    Text(text)
                        .font(.pretendard(.body1))
                        .foregroundStyle(.gray60)
                }
            }
        }
    }
    
    private struct DetailInfoText: View {
        let icon: String
        let text: String
        
        var body: some View {
            HStack(spacing: 0) {
                Image(icon)
                    .iconFrame(20)
                    .foregroundStyle(.blackSprout)
                Text(text)
                    .font(.pretendard(.body2))
                    .foregroundStyle(.gray60)
            }
        }
    }
}
