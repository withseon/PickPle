//
//  MenuDetailView.swift
//  PickPle
//
//  Created by 정인선 on 8/3/25.
//

import SwiftUI

struct MenuDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var cartManager: CartManager
    @State private var quantity: Int = 1
    let storeId: String
    let menuItem: DetailMenuItem
    
    private var hasImage: Bool {
        menuItem.menuImageUrl != nil
    }
    
    private var totalPrice: Int {
        menuItem.price * quantity
    }
    
    private var formattedTotalPrice: String {
        totalPrice.formatted()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 메인 콘텐츠
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // 이미지 (있는 경우에만, 네비게이션 영역까지 확장)
                        if hasImage {
                            CachedImageView(
                                imagePath: menuItem.menuImageUrl!,
                                size: CGSize(
                                    width: geometry.size.width,
                                    height: geometry.size.width * 0.8
                                )
                            )
                        }
                        
                        // 상품 정보
                        productInfoView
                    }
                }
                .ignoresSafeArea(edges: hasImage ? .top : [])
                
                // 하단 고정 버튼
                bottomButtonView
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image("chevron.left")
                    .iconFrame(32)
                    .foregroundStyle(hasImage ? .white : .gray100)
                    .wrapToButton {
                        dismiss()
                    }
            }
        }
        .background(.gray0)
        .alert("장바구니에는 같은 가게의 메뉴만 담을 수 있습니다.", isPresented: $cartManager.shouldShowStoreChangeAlert) {
            Button("취소", role: .cancel) {
                cartManager.cancelStoreChange()
            }
            Button("담기") {
                cartManager.confirmStoreChange()
                dismiss()
            }
        } message: {
            Text("선택하신 메뉴를 장바구니에 담을 경우 이전에 담은 메뉴가 삭제됩니다.")
        }
    }
    
    // MARK: - Subviews
    private var productInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 상품명
            Text(menuItem.name)
                .font(.pretendard(.title))
                .foregroundStyle(.gray100)
            
            // 상품 설명
            Text(menuItem.description)
                .font(.pretendard(.body1))
                .foregroundStyle(.gray60)
            
            // 가격
            HStack {
                Text("가격")
                    .font(.pretendard(.body1))
                    .foregroundStyle(.gray100)
                Spacer()
                Text("\(menuItem.price)원")
                    .font(.pretendard(.body1))
                    .foregroundStyle(.gray100)
            }
            
            // 수량 선택
            quantitySelectionView
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 120)
    }
    
    private var quantitySelectionView: some View {
        HStack {
            Text("수량")
                .font(.pretendard(.body1))
                .foregroundStyle(.gray100)
            Spacer()
            HStack(spacing: 0) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(menuItem.isSoldOut ? .gray60 : .gray75)
                    .frame(width: 44, height: 44)
                    .wrapToButton {
                        if quantity > 1 {
                            quantity -= 1
                        }
                    }
                    .disabled(quantity <= 1 || menuItem.isSoldOut)
                
                Text("\(quantity)개")
                    .font(.pretendard(.body1))
                    .foregroundStyle(menuItem.isSoldOut ? .gray60 : .gray100)
                    .frame(minWidth: 60)
                
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(menuItem.isSoldOut ? .gray60 : .gray75)
                    .frame(width: 44, height: 44)
                    .wrapToButton {
                        if quantity < 10 {
                            quantity += 1
                        }
                    }
                    .disabled(quantity >= 10 || menuItem.isSoldOut)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var bottomButtonView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            PrimaryButton(menuItem.isSoldOut ? "품절" : "\(formattedTotalPrice)원 담기") {
                if !menuItem.isSoldOut {
                    cartManager.addToCart(storeId: storeId, menu: menuItem, quantity: quantity)
                }
                if cartManager.currentStoreId == storeId {
                    dismiss()
                }
            }
            .disabled(menuItem.isSoldOut)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
        }
    }
}
