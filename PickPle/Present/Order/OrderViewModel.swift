//
//  OrderViewModel.swift
//  PickPle
//
//  Created by 정인선 on 8/3/25.
//

import Foundation
import Combine

final class OrderViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    private let orderRepository: OrderRepository
    private var hasInitialized = false
    private var autoRefreshTimer: AnyCancellable?
    
    init(
        orderRepository: OrderRepository
    ) {
        self.orderRepository = orderRepository
        super.init()
        transform()
    }
    
    deinit {
        stopAutoRefresh()
    }
}

// MARK: - Input/Output
extension OrderViewModel {
    struct Input {
        let onAppearTrigger = PassthroughSubject<Void, Never>()
        let onViewWillAppearTrigger = PassthroughSubject<Void, Never>()
        let onDisappearTrigger = PassthroughSubject<Void, Never>()
        let refreshTrigger = PassthroughSubject<Void, Never>()
    }

    struct Output {
        var isOrderList = true
        var currentOrderList = [CurrentOrder]()
        var pastOrderList = [PastOrder]()
    }

    func transform() {
        // 최초 데이터 로딩 (앱 시작시 1회만)
        input.onAppearTrigger
            .sink(with: self) { owner, _ in
                guard !owner.hasInitialized else { return }
                owner.hasInitialized = true
                owner.fetchOrderData()
            }
            .store(in: &cancellables)
        
        // 화면이 나타날 때마다 실행 (타이머 시작)
        input.onViewWillAppearTrigger
            .sink(with: self) { owner, _ in
                owner.startAutoRefresh()
            }
            .store(in: &cancellables)
        
        // 화면이 사라질 때 (타이머 정지)
        input.onDisappearTrigger
            .sink(with: self) { owner, _ in
                owner.stopAutoRefresh()
            }
            .store(in: &cancellables)
        
        // 수동 새로고침
        input.refreshTrigger
            .sink(with: self) { owner, _ in
                owner.fetchOrderData()
                // 새로고침 후 타이머 재시작 (다음 업데이트까지 1분 대기)
                owner.restartAutoRefresh()
            }
            .store(in: &cancellables)
    }
}

extension OrderViewModel {
    private func fetchOrderData() {
        let publish = orderRepository.checkOrderList()
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    owner.output.isOrderList = !success.data.isEmpty
                    (owner.output.currentOrderList, owner.output.pastOrderList) = success.separateOrders()
                case .failure(let error):
                    print("Order fetch error: \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    private func startAutoRefresh() {
        // 기존 타이머가 있다면 정지
        stopAutoRefresh()
        
        // 현재 주문이 있을 때만 자동 새로고침 활성화
        guard !output.currentOrderList.isEmpty else { return }
        
        // 1분마다 자동 새로고침
        autoRefreshTimer = Timer.publish(every: 60.0, on: .main, in: .common)
            .autoconnect()
            .sink(with: self) { owner, _ in
                print("🔄 주문 상태 자동 업데이트")
                owner.fetchOrderData()
            }
    }
    
    private func stopAutoRefresh() {
        autoRefreshTimer?.cancel()
        autoRefreshTimer = nil
    }
    
    private func restartAutoRefresh() {
        stopAutoRefresh()
        startAutoRefresh()
    }
}

// MARK: - Action
extension OrderViewModel {
    enum Action {
        case onAppear          // 최초 데이터 로딩
        case onViewWillAppear  // 화면이 나타날 때마다 (타이머 시작)
        case onDisappear       // 화면이 사라질 때 (타이머 정지)
        case refresh           // 사용자 수동 새로고침
    }

    func action(_ action: Action) {
        switch action {
        case .onAppear:
            input.onAppearTrigger.send(())
        case .onViewWillAppear:
            input.onViewWillAppearTrigger.send(())
        case .onDisappear:
            input.onDisappearTrigger.send(())
        case .refresh:
            input.refreshTrigger.send(())
        }
    }
}
