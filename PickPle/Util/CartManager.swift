//
//  CartManager.swift
//  PickPle
//
//  Created by 정인선 on 8/4/25.
//

import Foundation

// MARK: - Models
struct CartMenuItem: Equatable {
    let menuId: String
    let name: String
    var quantity: Int
    let price: Int
    let priceText: String
}

// MARK: - Cart Manager
final class CartManager: ObservableObject {
    @Published var currentStoreId: String = ""
    @Published var menuList: [CartMenuItem] = []
    @Published var shouldShowStoreChangeAlert: Bool = false
    @Published var isOrderProcessing: Bool = false
    
    var totalQuantity: Int {
        menuList.reduce(0) { $0 + $1.quantity }
    }
    
    var totalPrice: Int {
        menuList.reduce(0) { $0 + ($1.price * $1.quantity) }
    }
    
    var totalPriceText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: totalPrice)) ?? "0"
    }
    
    var isEmpty: Bool {
        menuList.isEmpty
    }
    
    private var pendingMenuItem: CartMenuItem?
    private var pendingStoreId: String?
    
    func addToCart(storeId: String, menu: DetailMenuItem, quantity: Int) {
        let newMenuItem = CartMenuItem(
            menuId: menu.menuId,
            name: menu.name,
            quantity: quantity,
            price: menu.price,
            priceText: menu.priceText
        )
        
        // 현재 스토어와 다른 경우
        if !currentStoreId.isEmpty && currentStoreId != storeId {
            pendingMenuItem = newMenuItem
            pendingStoreId = storeId
            shouldShowStoreChangeAlert = true
            return
        }
        
        // 현재 스토어이거나 첫 번째 추가인 경우
        currentStoreId = storeId
        addMenuItemToList(newMenuItem)
    }
    
    // 스토어 변경 확인 후 메뉴 추가
    func confirmStoreChange() {
        guard let newMenuItem = pendingMenuItem,
              let newStoreId = pendingStoreId else { return }
        
        currentStoreId = newStoreId
        menuList.removeAll()
        addMenuItemToList(newMenuItem)
        
        clearPendingData()
    }
    
    // 스토어 변경 취소
    func cancelStoreChange() {
        clearPendingData()
    }
    
    // 카트에서 메뉴 삭제
    func removeFromCart(menuId: String) {
        menuList.removeAll { $0.menuId == menuId }
        
        // 카트가 비었으면 스토어 ID 초기화
        if menuList.isEmpty {
            currentStoreId = ""
        }
    }
    
    // 특정 메뉴 수량 증가
    /// - Parameter menuId: 메뉴 ID
    func increaseQuantity(menuId: String) {
        if let index = menuList.firstIndex(where: { $0.menuId == menuId }) {
            menuList[index].quantity += 1
        }
    }
    
    // 특정 메뉴 수량 감소
    func decreaseQuantity(menuId: String) {
        if let index = menuList.firstIndex(where: { $0.menuId == menuId }) {
            let currentQuantity = menuList[index].quantity
            if currentQuantity > 1 {
                menuList[index].quantity -= 1
            } else {
                removeFromCart(menuId: menuId)
            }
        }
    }
    
    // 카트 비우기
    func clearCart() {
        menuList.removeAll()
        currentStoreId = ""
    }
}

// MARK: - Private Methods
extension CartManager {
    // 메뉴 리스트에 아이템 추가
    private func addMenuItemToList(_ newMenuItem: CartMenuItem) {
        if let index = menuList.firstIndex(where: { $0.menuId == newMenuItem.menuId }) {
            // 이미 존재하는 메뉴 수량 추가
            menuList[index].quantity += newMenuItem.quantity
        } else {
            // 새로운 메뉴 추가
            menuList.append(newMenuItem)
        }
    }
    
    // 대기 중인 데이터 초기화
    private func clearPendingData() {
        pendingMenuItem = nil
        pendingStoreId = nil
        shouldShowStoreChangeAlert = false
    }
}
