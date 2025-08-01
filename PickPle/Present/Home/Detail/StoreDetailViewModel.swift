//
//  StoreDetailViewModel.swift
//  PickPle
//
//  Created by 정인선 on 6/4/25.
//

import Foundation
import Combine

final class StoreDetailViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    private let storeRepository: StoreRepository
    private let orderRepository: OrderRepository
    let storeId: String

    init(storeRepository: StoreRepository, orderRepository: OrderRepository, storeId: String) {
        print("🥶 [StoreDetailViewModel] Init")
        self.storeRepository = storeRepository
        self.orderRepository = orderRepository
        self.storeId = storeId
        super.init()
        transform()
    }
    
    deinit {
        print("🥶 [StoreDetailViewModel] DeInit")
    }
}

// MARK: - Input/Output
extension StoreDetailViewModel {
    struct Input {
        let onAppearTrigger = PassthroughSubject<Void, Never>()
        let selectCategoryTrigger = PassthroughSubject<Int, Never>()
        let processOrderTrigger = PassthroughSubject<CartManager, Never>()
    }

    struct Output {
        var storeDetailData: StoreDetail = StoreDetail.empty
        var categories = [String]()
        var selectedCategoryIndex = 0
        var isOrderProcessing = false
    }

    func transform() {
        input.onAppearTrigger
            .sink(with: self) { owner, _ in
                owner.fetchStoreDetail()
            }
            .store(in: &cancellables)
        
        input.selectCategoryTrigger
            .sink(with: self) { owner, index in
                owner.output.selectedCategoryIndex = index
            }
            .store(in: &cancellables)
        
        input.processOrderTrigger
            .sink(with: self) { owner, cartManager in
                owner.processOrder(cartManager: cartManager)
            }
            .store(in: &cancellables)
    }
    
    private func fetchStoreDetail() {
        print("🟡 [StoreDetailViewModel] fetchStoreDetail 시작 - storeId: \(storeId)")
        print("🟡 [StoreDetailViewModel] storeRepository 인스턴스: \(storeRepository)")
        print("🟡 [StoreDetailViewModel] cancellables 개수: \(cancellables.count)")
        let publisher = storeRepository.storeDetail(storeId)
        print("🟡 [StoreDetailViewModel] storeRepository.storeDetail() 호출됨 - publisher 생성 완료")
        print("🟡 [StoreDetailViewModel] sink 구독 시작")
        publisher
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                print("🟡 [StoreDetailViewModel] storeDetail 응답 받음")
                switch result {
                case .success(let success):
                    print("✅ [StoreDetailViewModel] storeDetail 성공")
                    let storeDetailData = success.asStoreDetail
                    owner.output.storeDetailData = storeDetailData
                    owner.output.categories = storeDetailData.categoryList.map { $0.title }
                case .failure(let error):
                    print("❌ [StoreDetailViewModel] storeDetail 실패: \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    private func processOrder(cartManager: CartManager) {
        guard !cartManager.isEmpty else { return }
        
        output.isOrderProcessing = true
        
        // CartManager에서 필요한 데이터만 추출
        processOrder(
            storeId: cartManager.currentStoreId,
            menuItems: cartManager.menuList,
            totalPrice: cartManager.totalPrice
        )
    }
    
    private func processOrder(storeId: String, menuItems: [CartMenuItem], totalPrice: Int) {
        // OrderCreateRequest 생성
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
        
        let publisher = orderRepository.createOrder(orderRequest)
        publisher
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                owner.output.isOrderProcessing = false
                
                switch result {
                case .success(let response):
                    // TODO: 결제 요청
                    break
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Action
extension StoreDetailViewModel {
    enum Action {
        case onAppear
        case selectCategory(_ index: Int)
        case processOrder(storeId: String, menuItems: [CartMenuItem], totalPrice: Int)
    }

    func action(_ action: Action) {
        print("🟡 [StoreDetailViewModel] action 호출됨: \(action)")
        switch action {
        case .onAppear:
            print("🟡 [StoreDetailViewModel] onAppear 액션 처리")
            input.onAppearTrigger.send(())
        case .selectCategory(let index):
            input.selectCategoryTrigger.send(index)
        case .processOrder(let storeId, let menuItems, let totalPrice):
            processOrder(storeId: storeId, menuItems: menuItems, totalPrice: totalPrice)
        }
    }
}
