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
    @EnvironmentObject var homeCoordinator: HomeCoordinator
    @StateObject var viewModel: StoreDetailViewModel
    @StateObject var cartManager: CartManager
    @StateObject var paymentManager: PaymentManager
    @State private var showNavigationTitle = false
    @State private var topSafeArea: CGFloat = 0
    
    let tabViewHeight: CGFloat = 240
    let stickyHeaderHeight: CGFloat = 60
    let scrollCoordinateSpace: String = "storeDetailScroll"
    
    var body: some View {
        GeometryReader { geometry in
            contentView(geometry: geometry)
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
                
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.action(.onAppear)
        }
        .onChange(of: paymentManager.showPaymentView) { isShow in
            if isShow {
                homeCoordinator.presentFullScreenSheet(.payment)
            } else {
                homeCoordinator.dismissCover()
            }
        }
        .handleErrors(viewModel: viewModel)
    }
    
    @ViewBuilder
    private func contentView(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            mainScrollView(geometry: geometry)
            cartView
        }
    }
    
    @ViewBuilder
    private func mainScrollView(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            scrollContent(geometry: geometry)
        }
    }
    
    @ViewBuilder
    private func scrollContent(geometry: GeometryProxy) -> some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                scrollContentBody(scrollProxy: scrollProxy)
            }
            .coordinateSpace(name: scrollCoordinateSpace)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                // 디바운싱 또는 조건부 업데이트 추가
                DispatchQueue.main.async {
                    updateNavigationTitle(with: value)
                }
            }
        }
        .onAppear {
            topSafeArea = geometry.safeAreaInsets.top
        }
        .onChange(of: geometry.safeAreaInsets.top) { newValue in // iOS 17+
            // 값이 실제로 변경되었을 때만 업데이트
            if topSafeArea != newValue {
                topSafeArea = newValue
            }
        }
    }

    @ViewBuilder
    private func scrollContentBody(scrollProxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            headerSection
            menuSection(scrollProxy: scrollProxy)
        }
        .scrollBackground
        .padding(.bottom, !cartManager.isEmpty ? 100 : 0)
    }
    
    @ViewBuilder
    private var headerSection: some View {
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
    }
    
    @ViewBuilder
    private func menuSection(scrollProxy: ScrollViewProxy) -> some View {
        Section {
            menuItems
        } header: {
            categoryHeader(scrollProxy: scrollProxy)
        }
    }
    
    @ViewBuilder
    private var menuItems: some View {
        ForEach(Array(viewModel.output.storeDetailData.categoryList.enumerated()), id: \.offset) { index, category in
            MenuSectionView(
                viewModel: viewModel,
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
    }
    
    @ViewBuilder
    private func categoryHeader(scrollProxy: ScrollViewProxy) -> some View {
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
    
    @ViewBuilder
    private var cartView: some View {
        if viewModel.storeId == cartManager.currentStoreId && !cartManager.isEmpty {
            CartMiniView(
                cartManager: cartManager,
                paymentManager: paymentManager // 추가
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: !cartManager.isEmpty)
            .alert("가격이 변경되었습니다", isPresented: $paymentManager.showPriceChangeAlert) {
                Button("취소", role: .cancel) {
                    paymentManager.cancelPriceChange()
                }
                Button("변경된 가격으로 결제") {
                    paymentManager.proceedWithNewPrice()
                }
            } message: {
                if let result = paymentManager.priceValidationResult {
                    Text("일부 상품의 가격이 변경되었습니다.\n기존: \(result.originalPrice)원 → 현재: \(result.currentPrice)원")
                }
            }
        }
    }
    
    private func updateNavigationTitle(with value: CGFloat) {
        let tabViewDisappearedThreshold = -tabViewHeight + 60
        withAnimation(.easeInOut(duration: 0.2)) {
            showNavigationTitle = value <= tabViewDisappearedThreshold
        }
    }
}

extension View {
    @ViewBuilder
    var scrollBackground: some View {
        self.background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named("storeDetailScroll")).minY
                    )
            }
        )
    }
}

// MARK: - Cart Mini View
extension StoreDetailView {
    struct CartMiniView: View {
        @ObservedObject var cartManager: CartManager
        @ObservedObject var paymentManager: PaymentManager
        
        var body: some View {
            VStack(spacing: 0) {
                Divider()
                cartContent
            }
        }
        
        @ViewBuilder
        private var cartContent: some View {
            HStack {
                priceSection
                Spacer()
                checkoutSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.gray0)
        }
        
        @ViewBuilder
        private var priceSection: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text("상품 합계")
                    .font(.pretendard(.caption1))
                    .foregroundStyle(.gray60)
                Text("\(cartManager.totalPriceText)원")
                    .font(.pretendard(.body1))
                    .fontWeight(.bold)
                    .foregroundStyle(.gray100)
            }
        }
        
        @ViewBuilder
        private var checkoutSection: some View {
            HStack(spacing: 12) {
                quantityBadge
                checkoutText
            }
            .padding(.horizontal, 23)
            .padding(.vertical, 12)
            .background(.blackSprout)
            .cornerRadius(8)
            .wrapToButton {
                print("결제하기 화면으로 이동")
                startPayment()
            }
        }
        
        @ViewBuilder
        private var quantityBadge: some View {
            Text("\(cartManager.totalQuantity)")
                .font(.pretendard(.caption1))
                .fontWeight(.bold)
                .foregroundStyle(.blackSprout)
                .padding(4)
                .background(Circle().fill(.gray0))
        }
        
        @ViewBuilder
        private var checkoutText: some View {
            Text("결제하기")
                .font(.pretendard(.body1))
                .fontWeight(.semibold)
                .foregroundStyle(.gray0)
        }
        
        private func startPayment() {
            print("🔵 [CartMiniView] startPayment 호출됨")
            print("🔵 [CartMiniView] PaymentManager 인스턴스: \(ObjectIdentifier(paymentManager))")
            guard !cartManager.isEmpty else { 
                print("🔴 [CartMiniView] 장바구니가 비어있음")
                return 
            }
            
            print("🔵 [CartMiniView] PaymentManager.startPayment 호출 시작")
            print("🔵 [CartMiniView] storeId: \(cartManager.currentStoreId)")
            print("🔵 [CartMiniView] totalPrice: \(cartManager.totalPrice)")
            
            paymentManager.startPayment(
                storeId: cartManager.currentStoreId,
                menuItems: cartManager.menuList,
                totalPrice: cartManager.totalPrice
            )
            
            print("🔵 [CartMiniView] PaymentManager.startPayment 호출 완료")
        }
    }
}

// MARK: - Header View
extension StoreDetailView {
    struct HeaderView: View {
        @ObservedObject var viewModel: StoreDetailViewModel

        let tabViewHeight: CGFloat
        let topSafeArea: CGFloat

        var body: some View {
            VStack(spacing: 0) {
                ImageCarouselView(
                    imageUrls: viewModel.output.storeDetailData.storeImageUrls,
                    height: tabViewHeight + topSafeArea
                )
                storeInfoContainer
            }
        }
        
        @ViewBuilder
        private var storeInfoContainer: some View {
            VStack(alignment: .leading, spacing: 8) {
                storeNameRow
                storeStatsRow
                storeDetailsBox
                pickupTimeTag
                directionsButton
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
                Divider().background(.deepSprout)
            }
            .padding(.top, -20)
        }
        
        @ViewBuilder
        private var storeNameRow: some View {
            HStack {
                Text(viewModel.output.storeDetailData.name)
                    .font(.pretendard(.title))
                    .foregroundStyle(.gray100)
                if viewModel.output.storeDetailData.isPicchelin {
                    PickChelinTagView()
                }
            }
        }
        
        @ViewBuilder
        private var storeStatsRow: some View {
            HStack(spacing: 12) {
                MainInfoText(
                    icon: "like.fill",
                    text: "\(viewModel.output.storeDetailData.pickCount)개"
                )
                MainInfoText(
                    icon: "star.fill",
                    text: viewModel.output.storeDetailData.totalRating,
                    subText: viewModel.output.storeDetailData.totalReviewCount,
                    subIcon: "chevron.right"
                )
                Spacer()
                orderCountInfo
            }
        }
        
        @ViewBuilder
        private var orderCountInfo: some View {
            HStack {
                Image("sparkle")
                    .iconFrame(16)
                    .foregroundStyle(.gray45)
                Text(viewModel.output.storeDetailData.totalOrderCount)
                    .font(.pretendard(.body3))
                    .foregroundStyle(.gray45)
            }
        }
        
        @ViewBuilder
        private var storeDetailsBox: some View {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    DetailInfoText(
                        title: "가게주소",
                        icon: "distance",
                        text: viewModel.output.storeDetailData.address
                    )
                    DetailInfoText(
                        title: "영업시간",
                        icon: "time",
                        text: viewModel.output.storeDetailData.businessHours
                    )
                    DetailInfoText(
                        title: "주차여부",
                        icon: "parking",
                        text: viewModel.output.storeDetailData.parkinGuide
                    )
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.gray30)
            )
        }
        
        @ViewBuilder
        private var pickupTimeTag: some View {
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
        }
        
        @ViewBuilder
        private var directionsButton: some View {
            PrimaryButton("길찾기") {
                print("길찾기 버튼 클릭")
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
}

// MARK: - Detail Info Text
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

// MARK: - Category Header View
struct CategoryHeaderView: View {
    let categories: [String]
    let selectedCategoryIndex: Int
    let scrollAction: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            categoryContent
        }
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var categoryContent: some View {
        HStack(spacing: 4) {
            searchIcon
            categoryButtons
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var searchIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 48, height: 32)
                .foregroundStyle(.deepSprout)
            Image("search")
                .iconFrame(20)
                .foregroundStyle(.gray0)
        }
    }
    
    @ViewBuilder
    private var categoryButtons: some View {
        ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
            CategoryButton(
                category: category,
                isSelected: selectedCategoryIndex == index,
                action: { scrollAction(index) }
            )
        }
    }
}

private struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Text(category)
            .font(.pretendard(.body2))
            .fontWeight(isSelected ? .bold : .medium)
            .foregroundStyle(isSelected ? .blackSprout : .gray30)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? .blackSprout : .gray30,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .wrapToButton(action: action)
            .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Menu Section View
struct MenuSectionView: View {
    @ObservedObject var viewModel: StoreDetailViewModel
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
            sectionTitle
            menuItemsList
        }
    }
    
    @ViewBuilder
    private var sectionTitle: some View {
        HStack {
            Text(category)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)
            Spacer()
        }
        .background(visibilityTracker)
    }
    
    @ViewBuilder
    private var visibilityTracker: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    checkVisibility(geometry: geometry)
                }
                .onChange(of: geometry.frame(in: .named(scrollCoordinateSpace)).minY) { minY in
                    let adjustedMinY = minY
                    
                    if adjustedMinY <= (topSafeArea + stickyHeaderHeight + 50) &&
                        adjustedMinY >= -(topSafeArea + 100) {
                        onCategoryVisible(categoryIndex)
                    }
                }
        }
    }
    
    @ViewBuilder
    private var menuItemsList: some View {
        ForEach(items, id: \.menuId) { item in
            menuItemRow(item: item)
        }
    }
    
    @ViewBuilder
    private func menuItemRow(item: StoreDetail.CategoryItem.MenuItem) -> some View {
        VStack(spacing: 0) {
            NavigationLink(
                value: HomeRoute.menuDetail(
                    storeId: viewModel.storeId,
                    menu: item.asDetailMenuItem
                )
            ) {
                MenuItemView(menuItem: item)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
            }
            itemSeparator(for: item)
        }
    }
    
    @ViewBuilder
    private func itemSeparator(for item: StoreDetail.CategoryItem.MenuItem) -> some View {
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
    
    private func checkVisibility(geometry: GeometryProxy) {
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
}

// MARK: - Menu Item View
struct MenuItemView: View {
    let menuItem: StoreDetail.CategoryItem.MenuItem
    
    var body: some View {
        VStack(alignment: .leading) {
            tagSection
            contentSection
        }
    }
    
    @ViewBuilder
    private var tagSection: some View {
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
    }
    
    @ViewBuilder
    private var contentSection: some View {
        HStack {
            menuDetails
            Spacer()
            menuImageSection
        }
    }
    
    @ViewBuilder
    private var menuDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(menuItem.name)
                .font(.pretendard(.body1))
                .foregroundStyle(.gray90)
            Text(menuItem.description)
                .font(.pretendard(.caption1))
                .foregroundStyle(.gray60)
            Text(menuItem.priceText)
                .font(.pretendard(.body1))
                .foregroundStyle(.gray90)
        }
    }
    
    @ViewBuilder
    private var menuImageSection: some View {
        ZStack {
            menuImage
            if menuItem.isSoldOut {
                soldOutOverlay
            }
        }
    }
    
    @ViewBuilder
    private var menuImage: some View {
        if let imageUrl = menuItem.menuImageUrl {
            CachedImageView(imagePath: imageUrl, size: CGSize(width: 100, height: 100))
                .cornerRadius(8)
        } else {
            Rectangle()
                .frame(width: 100, height: 100)
                .cornerRadius(8)
                .foregroundStyle(.brightForsythia)
        }
    }
    
    @ViewBuilder
    private var soldOutOverlay: some View {
        Rectangle()
            .frame(width: 100, height: 100)
            .cornerRadius(8)
            .foregroundStyle(.gray100.opacity(0.5))
        
        Text("품절")
            .font(.pretendard(.body1))
            .foregroundStyle(.gray0)
    }
}
