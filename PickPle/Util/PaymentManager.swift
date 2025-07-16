//
//  PaymentManager.swift
//  PickPle
//
//  Created by 정인선 on 8/9/25.
//

import Foundation
import Combine

// MARK: - Payment Domain Models (Entity)
struct PaymentRequest {
    let storeId: String
    let menuItems: [CartMenuItem]
    let totalPrice: Int
    let orderCode: String
}

struct PriceValidationResult {
    let isValid: Bool
    let currentPrice: Int
    let originalPrice: Int
    let changedItems: [String]
}

enum PaymentError: Error {
    case orderCreationFailed
    case paymentFailed(String)
    case validationFailed
    case priceChanged(PriceValidationResult)
    case unknown(Error)
}

// MARK: - Payment Manager
final class PaymentManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPaymentView = false
    @Published var showPriceChangeAlert = false
    @Published var priceValidationResult: PriceValidationResult?
    
    private let orderRepository: OrderRepository
    private let paymentRepository: PaymentRepository
    private let storeRepository: StoreRepository
    private let cartManager: CartManager
    private var currentPaymentRequest: PaymentRequest?
    private var cancellables = Set<AnyCancellable>()
    
    // 결제 성공 시 호출될 콜백
    var onPaymentSuccess: (() -> Void)?
    
    init(orderRepository: OrderRepository, paymentRepository: PaymentRepository, storeRepository: StoreRepository, cartManager: CartManager) {
        self.orderRepository = orderRepository
        self.paymentRepository = paymentRepository
        self.storeRepository = storeRepository
        self.cartManager = cartManager
    }
    
    // MARK: - Public Methods
    
    /// 결제 프로세스 시작 (가격 검증 포함)
    func startPayment(storeId: String, menuItems: [CartMenuItem], totalPrice: Int) {
        print("🟡 [PaymentManager] startPayment 시작")
        print("🟡 [PaymentManager] storeId: \(storeId), totalPrice: \(totalPrice)")
        
        isLoading = true
        errorMessage = nil
        
        print("🟡 [PaymentManager] 가격 검증 시작")
        // 1. 먼저 가격 검증
        validateCurrentPrices(storeId: storeId, menuItems: menuItems, originalTotalPrice: totalPrice)
    }
    
    /// 가격 변경 확인 후 결제 진행
    func proceedWithNewPrice() {
        guard let validationResult = priceValidationResult else { return }
        
        showPriceChangeAlert = false
        
        // 새로운 가격으로 결제 진행
        if let request = currentPaymentRequest {
            let updatedRequest = PaymentRequest(
                storeId: request.storeId,
                menuItems: request.menuItems,
                totalPrice: validationResult.currentPrice,
                orderCode: request.orderCode
            )
            proceedToOrder(with: updatedRequest)
        }
    }
    
    /// 가격 변경 취소
    func cancelPriceChange() {
        showPriceChangeAlert = false
        priceValidationResult = nil
        currentPaymentRequest = nil
        isLoading = false
    }
    
    /// PG 결제 완료 후 검증
    func validatePayment(impUid: String) {
        guard currentPaymentRequest != nil else { return }
        
        isLoading = true
        
        // ReceiptOrderRequest는 impUid만 필요 (merchantUid는 사용하지 않음)
        let request = ReceiptOrderRequest(impUid: impUid)
        
        paymentRepository.validationReceipt(request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isLoading = false
                switch result {
                case .success(let response):
                    self?.handlePaymentSuccess(response)
                case .failure(let error):
                    self?.handleError(PaymentError.validationFailed)
                }
            }
            .store(in: &cancellables)
    }
    
    /// 결제 취소
    func cancelPayment() {
        print("🟡 [PaymentManager] cancelPayment 호출됨")
        // ✅ 완전 초기화
        currentPaymentRequest = nil
        errorMessage = nil
        priceValidationResult = nil
        showPriceChangeAlert = false
        isLoading = false
        
        // ✅ 콜백으로 결제 화면 닫기
        print("🟡 [PaymentManager] 콜백으로 결제 화면 닫기")
        showPaymentView = false
        
        // ✅ 현재 결제 관련 구독만 취소 (전체 구독은 유지)
        // cancellables.removeAll() // ← 이것이 문제! 전체 구독 취소하면 안됨
        print("🟡 [PaymentManager] cancelPayment 완료")
    }
    
    // MARK: - Private Methods
    
    /// 현재 서버 가격과 비교 검증
    private func validateCurrentPrices(storeId: String, menuItems: [CartMenuItem], originalTotalPrice: Int) {
        storeRepository.storeDetail(storeId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }
                
                switch result {
                case .success(let storeDetailResponse):
                    self.processStoreDetailForPriceValidation(
                        storeDetail: storeDetailResponse.asStoreDetail,
                        menuItems: menuItems,
                        originalTotalPrice: originalTotalPrice,
                        storeId: storeId
                    )
                case .failure(let error):
                    // ✅ 상태 변경 최소화
                    if self.isLoading {
                        self.isLoading = false
                    }
                    self.handleError(PaymentError.unknown(error))
                }
            }
            .store(in: &cancellables)
    }
    
    /// 스토어 상세 정보로 가격 검증 처리
    private func processStoreDetailForPriceValidation(
        storeDetail: StoreDetail,
        menuItems: [CartMenuItem],
        originalTotalPrice: Int,
        storeId: String
    ) {
        var currentTotalPrice = 0
        var changedItems: [String] = []
        
        // 각 메뉴의 현재 가격 확인
        for cartItem in menuItems {
            if let currentMenu = findMenuInStoreDetail(menuId: cartItem.menuId, storeDetail: storeDetail) {
                let currentItemTotal = currentMenu.price * cartItem.quantity
                currentTotalPrice += currentItemTotal
                
                let originalItemTotal = cartItem.price * cartItem.quantity
                if currentItemTotal != originalItemTotal {
                    changedItems.append(cartItem.name)
                }
            } else {
                // 메뉴를 찾을 수 없는 경우 (삭제된 메뉴)
                isLoading = false
                errorMessage = "일부 상품이 더 이상 판매되지 않습니다."
                return
            }
        }
        
        let validationResult = PriceValidationResult(
            isValid: currentTotalPrice == originalTotalPrice,
            currentPrice: currentTotalPrice,
            originalPrice: originalTotalPrice,
            changedItems: changedItems
        )
        
        if validationResult.isValid {
            // 가격이 동일하면 바로 주문 생성
            createOrderAndProceed(storeId: storeId, menuItems: menuItems, totalPrice: originalTotalPrice)
        } else {
            // ✅ 상태 변경 최소화 및 순서 조정
            DispatchQueue.main.async {
                if self.isLoading {
                    self.isLoading = false
                }
                self.priceValidationResult = validationResult
                self.showPriceChangeAlert = true
            }
        }
    }
    
    /// 스토어 상세에서 메뉴 찾기
    private func findMenuInStoreDetail(menuId: String, storeDetail: StoreDetail) -> StoreDetail.CategoryItem.MenuItem? {
        for category in storeDetail.categoryList {
            if let menu = category.menuList.first(where: { $0.menuId == menuId }) {
                return menu
            }
        }
        return nil
    }
    
    /// 주문 생성 및 결제 진행
    private func createOrderAndProceed(storeId: String, menuItems: [CartMenuItem], totalPrice: Int) {
        let orderMenuList = menuItems.map { cartItem in
            OrderCreateRequest.OrderMenuRequest(
                menuId: cartItem.menuId,
                quantity: cartItem.quantity
            )
        }
        
        let orderRequest = OrderCreateRequest(
            storeId: storeId,
            orderMenuList: orderMenuList,
            totalPrice: totalPrice
        )
        
        orderRepository.createOrder(orderRequest)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                switch result {
                case .success(let response):
                    let paymentRequest = PaymentRequest(
                        storeId: storeId,
                        menuItems: menuItems,
                        totalPrice: totalPrice,
                        orderCode: response.orderCode
                    )
                    self?.proceedToOrder(with: paymentRequest)
                case .failure:
                    self?.isLoading = false
                    self?.handleError(PaymentError.orderCreationFailed)
                }
            }
            .store(in: &cancellables)
    }
    
    /// 주문 정보 저장 및 결제 화면 표시
    private func proceedToOrder(with paymentRequest: PaymentRequest) {
        print("🟡 [PaymentManager] proceedToOrder 호출됨")
        print("🟡 [PaymentManager] orderCode: \(paymentRequest.orderCode)")
        print("🟡 [PaymentManager] 현재 스레드: \(Thread.isMainThread ? "Main" : "Background")")
        
        self.currentPaymentRequest = paymentRequest
        self.isLoading = false
        showPaymentView = true
    }
    
    private func handlePaymentSuccess(_ response: ReceiptOrderResponse) {
        print("🟡 [PaymentManager] handlePaymentSuccess 호출됨")
        currentPaymentRequest = nil
        priceValidationResult = nil
        
        // 결제 성공 처리 - ReceiptOrderResponse를 화면용 모델로 변환할 수 있음
        print("결제 성공: 주문코드 \(response.orderItem.orderCode), 결제금액 \(response.orderItem.totalPrice)원")
        
        // ✅ 카트 비우기
        cartManager.clearCart()
        print("🛒 [PaymentManager] 카트가 비워졌습니다")
        
        // ✅ 콜백으로 결제 화면 닫기
        print("🟡 [PaymentManager] 콜백으로 결제 화면 닫기")
        showPaymentView = false
        
        // ✅ 결제 성공 콜백 호출 (네비게이션은 상위에서 처리)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            print("📱 [PaymentManager] 결제 성공 콜백 호출")
            self.onPaymentSuccess?()
        }
    }
    
    private func handleError(_ error: PaymentError) {
        print("🔴 [PaymentManager] handleError 호출됨: \(error)")
        
        switch error {
        case .orderCreationFailed:
            print("🔴 [PaymentManager] 주문 생성 실패")
            errorMessage = "주문 생성에 실패했습니다."
        case .paymentFailed(let message):
            print("🔴 [PaymentManager] 결제 실패: \(message)")
            errorMessage = "결제에 실패했습니다: \(message)"
        case .validationFailed:
            print("🔴 [PaymentManager] 결제 검증 실패")
            errorMessage = "결제 검증에 실패했습니다."
        case .priceChanged:
            print("🔴 [PaymentManager] 가격 변경됨")
            // 가격 변경은 별도 alert로 처리
            break
        case .unknown(let error):
            print("🔴 [PaymentManager] 알 수 없는 오류: \(error)")
            errorMessage = "알 수 없는 오류가 발생했습니다."
        }
        
        print("🔴 [PaymentManager] errorMessage 설정됨: \(String(describing: errorMessage))")
    }
    
    // MARK: - Payment View Properties
    
    var paymentRequest: PaymentRequest? {
        currentPaymentRequest
    }
}
