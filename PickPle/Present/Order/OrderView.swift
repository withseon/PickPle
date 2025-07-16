//
//  OrderView.swift
//  PickPle
//
//  Created by 정인선 on 8/3/25.
//

import SwiftUI

struct OrderView: View {
    @StateObject var viewModel: OrderViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            
            if viewModel.output.isOrderList {
                Divider()
                ZStack {
                    // 배경을 반으로 나누는 뷰
                    SplitBackgroundView(topColor: .gray15, bottomColor: .gray0)
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            OrderStatusView(currentOrders: viewModel.output.currentOrderList)
                            Divider()
                            OrderHistoryView(pastOrders: viewModel.output.pastOrderList)
                        }
                    }
                }
                .refreshable {
                    viewModel.action(.refresh)
                }
            } else {
                OrderEmptyView()
            }
        }
        .onAppear {
            viewModel.action(.onAppear)
            viewModel.action(.onViewWillAppear)
        }
        .onDisappear {
            viewModel.action(.onDisappear)
        }
        .handleErrors(viewModel: viewModel)
    }
}

struct HeaderView: View {
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Text("픽업")
                    .foregroundStyle(.blackSprout)
                Text("을 하실 때는")
                    .foregroundStyle(.deepSprout)
                Text("주문번호")
                    .foregroundStyle(.blackSprout)
                Text("를 꼭 말씀해주세요!")
                    .foregroundStyle(.deepSprout)
            }
            .font(.pretendard(.body1))
            .fontWeight(.bold)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .borderedCard(
                cornerRadius: 8,
                borderColor: .deepSprout,
                backgroundColor: .brightSprout
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .padding(20)
        }
    }
}

struct OrderEmptyView: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .center) {
                Image("sesac")
                    .iconFrame(62)
                Text("PICKPLE을 시작해보세요.")
                    .font(.pretendard(.title))
                Text("건강한 픽업 생활의 시작, PICKPLE")
                    .font(.pretendard(.body3))
            }
            .foregroundStyle(.brightSprout)
            Spacer()
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - 주문현황 뷰
struct OrderStatusView: View {
    let currentOrders: [CurrentOrder]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("주문현황")
                    .font(.pretendard(.body2))
                    .foregroundStyle(.gray60)
                Spacer()
            }
            .padding(20)
            
            if currentOrders.isEmpty {
                VStack {
                    Text("진행중인 주문이 없습니다")
                        .font(.pretendard(.body3))
                        .foregroundStyle(.gray60)
                        .padding(.top, 40)
                        .padding(.bottom, 60)
                }
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(currentOrders, id: \.orderId) { order in
                        CurrentOrderCard(order: order)
                    }
                }
                .padding([.horizontal, .bottom], 20)
            }
        }
        .background(.gray15)
    }
}

// MARK: - 현재 주문 카드
struct CurrentOrderCard: View {
    let order: CurrentOrder
    
    var body: some View {
        VStack(spacing: 8) {
            // 메인 정보 카드
            NavigationLink(value: OrderRoute.storeDetail(order.storeId)) {
                MainOrderInfoCard(order: order)
            }
            .buttonStyle(.plain)
            // 주문 요약 카드
            OrderSummaryCard(order: order)
        }
    }
}

// MARK: - 메인 주문 정보 카드
struct MainOrderInfoCard: View {
    let order: CurrentOrder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("주문번호")
                        .font(.pretendard(.body3))
                        .fontWeight(.bold)
                        .foregroundStyle(.gray45)
                    
                    Text(order.orderCode)
                        .font(.pretendard(.body3))
                        .fontWeight(.bold)
                        .foregroundStyle(.gray60)
                }
                
                Text(order.storeName)
                    .font(.pretendard(.body1))
                    .fontWeight(.heavy)
                    .foregroundStyle(.blackSprout)
                
                Text(order.orderDate)
                    .font(.pretendard(.caption2))
                    .foregroundStyle(.deepSprout)
                
                Spacer()
            }
            
            Spacer()
            ProgressTimelineView(statusTimeline: order.statusTimeline)
        }
        .padding(20)
        .borderedCard(
            cornerRadius: 16,
            borderColor: .brightSprout,
            backgroundColor: .gray0
        )
    }
}

// MARK: - 진행 상황 타임라인
struct ProgressTimelineView: View {
    let statusTimeline: [CurrentOrder.OrderStatusItem]
    
    // 색상 설정
    let completedColor = Color.blackSprout
    let pendingColor = Color.gray30
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(statusTimeline.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    // 왼쪽 타임라인 부분
                    VStack(spacing: 0) {
                        // 원형 아이콘
                        ZStack {
                            Circle()
                                .fill(item.isCompleted ? completedColor : pendingColor)
                                .frame(width: 16, height: 16)
                            
                            if item.isCompleted {
                                Image("check")
                                    .iconFrame(10)
                                    .foregroundStyle(.gray0)
                            } else {
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundStyle(.gray0)
                            }
                        }
                        
                        // 연결선 (마지막 아이템이 아닌 경우)
                        if index < statusTimeline.count - 1 {
                            Rectangle()
                                .fill(statusTimeline[index + 1].isCompleted ? completedColor : pendingColor)
                                .frame(width: 4, height: 20)
                        }
                    }
                    
                    // 오른쪽 텍스트 부분
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(item.status.displayName)
                                .font(.pretendard(.caption2))
                                .fontWeight(.semibold)
                                .foregroundStyle(.gray100)
                            Text(item.timeText)
                                .font(.pretendard(.caption2))
                                .fontWeight(.medium)
                                .foregroundStyle(.gray60)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray15)
        }
    }
}

// MARK: - 주문 요약 카드
struct OrderSummaryCard: View {
    let order: CurrentOrder
    
    var body: some View {
        VStack(spacing: 16) {
            // 메뉴 아이템들
            VStack(spacing: 12) {
                ForEach(order.menuItems, id: \.name) { menuItem in
                    OrderMenuItemView(menuItem: menuItem)
                }
            }
            
            // 결제 금액
            HStack {
                Text("결제금액")
                    .font(.pretendard(.body2))
                    .foregroundStyle(.gray60)
                
                Spacer()
                
                Text(order.totalQuantity)
                    .font(.pretendard(.body2))
                    .foregroundStyle(.gray60)
                
                Text(order.totalPrice)
                    .font(.pretendard(.body2))
                    .foregroundStyle(.gray100)
            }
        }
        .padding(20)
        .borderedCard(
            cornerRadius: 16,
            borderColor: .brightSprout,
            backgroundColor: .gray0
        )
    }
}

// MARK: - 주문 메뉴 아이템 뷰
struct OrderMenuItemView: View {
    let menuItem: CurrentOrder.OrderMenuItem
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                CachedImageView(
                    imagePath: menuItem.imageUrl ?? "",
                    size: CGSize(width: 84, height: 52)
                )
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(menuItem.name)
                        .font(.pretendard(.body2))
                        .foregroundStyle(.gray100)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text(menuItem.price)
                            .font(.pretendard(.body2))
                            .foregroundStyle(.gray75)
                        Text(menuItem.quantity)
                            .font(.pretendard(.body2))
                            .foregroundStyle(.gray60)
                        Spacer()
                    }
                }
            }
            
            Divider()
        }
    }
}

// MARK: - 이전 주문내역
struct OrderHistoryView: View {
    let pastOrders: [PastOrder]
    
    var body: some View {
        VStack {
            HStack {
                Text("이전주문 내역")
                    .font(.pretendard(.body2))
                    .foregroundStyle(.gray60)
                Spacer()
            }
            .padding(20)
            
            if pastOrders.isEmpty {
                VStack {
                    Text("이전 주문 내역이 없습니다")
                        .font(.pretendard(.body3))
                        .foregroundStyle(.gray60)
                        .padding(.top, 40)
                        .padding(.bottom, 60)
                }
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(pastOrders, id: \.orderId) { order in
                        PastOrderCard(order: order)
                    }
                }
                .padding([.horizontal, .bottom], 20)
            }
        }
        .background(.gray0)
    }
}

// MARK: - 과거 주문 카드
struct PastOrderCard: View {
    let order: PastOrder
    
    var body: some View {
        VStack(spacing: 12) {
            // 메인 카드 영역 - NavigationLink 사용 (가게 상세로 이동)
            NavigationLink(value: OrderRoute.storeDetail(order.storeId)) {
                HStack(spacing: 12) {
                    // 텍스트 영역
                    VStack(alignment: .leading, spacing: 8) {
                        // 제목
                        Text(order.storeName)
                            .font(.pretendard(.title))
                            .foregroundStyle(.gray75)
                            .lineLimit(2)
                        
                        // 주문번호와 날짜
                        HStack(spacing: 12) {
                            Text(order.orderCode)
                                .font(.pretendard(.caption1))
                                .foregroundStyle(.gray60)
                            
                            Text(order.orderDate)
                                .font(.pretendard(.caption2))
                                .foregroundStyle(.gray45)
                                .lineLimit(1)
                        }
                        
                        // 설명과 가격
                        HStack(spacing: 12) {
                            Text(order.menuSummary)
                                .font(.pretendard(.body3))
                                .foregroundStyle(.gray60)
                                .lineLimit(1)
                            
                            HStack(spacing: 0) {
                                Text(order.totalPrice)
                                    .font(.pretendard(.body3))
                                    .foregroundStyle(.blackSprout)
                                
                                Image("chevron.right")
                                    .iconFrame(16)
                                    .foregroundStyle(.blackSprout)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // 가게 이미지
                    CachedImageView(
                        imagePath: order.storeImageUrl ?? "",
                        size: CGSize(width: 80, height: 80)
                    )
                    .cornerRadius(8)
                }
            }
            
            // 리뷰 섹션
            reviewSection(for: order)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .borderedCard(
            cornerRadius: 16,
            borderColor: .gray30,
            backgroundColor: .gray0
        )
    }
    
    @ViewBuilder
    private func reviewSection(for order: PastOrder) -> some View {
        Group {
            if order.hasReview {
                // TODO: 리뷰 상세 뷰 이동
                HStack(spacing: 10) {
                    Image("star.fill")
                        .iconFrame(20)
                        .foregroundStyle(.brightForsythia)
                    
                    Text(order.reviewRating)
                        .font(.pretendard(.body1))
                        .foregroundStyle(.gray75)
                }
            } else {
                // TODO: 리뷰 작성 뷰 이동
                Text("리뷰 작성")
                    .font(.pretendard(.body1))
                    .foregroundStyle(.gray60)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity)
        .borderedCard(cornerRadius: 8, borderColor: .gray30, backgroundColor: .gray0)
    }
}
