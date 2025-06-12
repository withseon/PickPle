//
//  MainViewModel.swift
//  PickPle
//
//  Created by 정인선 on 5/21/25.
//

import Foundation
import Combine

final class MainViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    let locationManager = LocationManager()
    
    private let storeRepository: StoreRepository
    private var storeListParam = StoreListParam.empty
    
    private var allPopularStoreData = [PopularStore]()
    private var allStoreData = [StoreSummary]()

    init(storeRepository: StoreRepository) {
        self.storeRepository = storeRepository
        super.init()
        transform()
    }
}

// MARK: - Input/Output
extension MainViewModel {
    struct Input {
        let onAppearTrigger = PassthroughSubject<Void, Never>()
        let mapSheetTrigger = PassthroughSubject<Void, Never>()
        let selectedLocationTrigger = PassthroughSubject<Void, Never>()
        let selectedCategoryTrigger = PassthroughSubject<StoreCategory, Never>()
        let orderSheetTrigger = PassthroughSubject<Void, Never>()
        let selectedOrderTigger = PassthroughSubject<StoreOrder, Never>()
        let selectedPickFilterTrigger = PassthroughSubject<PickFilter, Never>()
    }

    struct Output {
        var showMapSheet = false
        var address = ""
        var popularStores = [PopularStore]()
        var storeSummaries = [StoreSummary]()
        var selectedCategory: StoreCategory? = nil
        var showOrderSheet = false
        var selectedOrder: StoreOrder = .distance
        var selectedPickFilters: Set<PickFilter> = []
    }

    func transform() {
        input.onAppearTrigger
            .sink(with: self) { owner, _ in
                owner.output.address = owner.setAddress()
                owner.fetchStoreData()
                owner.fetchPopularStoreData()
            }
            .store(in: &cancellables)
        
        input.mapSheetTrigger
            .sink(with: self) { owner, _ in
                owner.output.showMapSheet = true
            }
            .store(in: &cancellables)
        
        input.selectedLocationTrigger
            .sink(with: self) { owner, _ in
                owner.output.address = owner.setAddress()
                
                // TODO: 서버통신
            }
            .store(in: &cancellables)
        
        input.selectedCategoryTrigger
            .sink(with: self) { owner, category in
                if owner.output.selectedCategory == category {
                    owner.output.selectedCategory = nil
                    owner.storeListParam.category = nil
                    owner.storeListParam.category = nil
                } else {
                    owner.output.selectedCategory = category
                    owner.storeListParam.category = category
                    owner.storeListParam.category = category
                }
                owner.fetchStoreData()
                owner.fetchPopularStoreData()
            }
            .store(in: &cancellables)
        
        input.orderSheetTrigger
            .sink(with: self) { owner, _ in
                owner.output.showOrderSheet = true
            }
            .store(in: &cancellables)
        
        input.selectedOrderTigger
            .sink(with: self) { owner, order in
                if owner.output.selectedOrder != order {
                    owner.output.selectedOrder = order
                    owner.storeListParam.orderBy = order
                    owner.fetchStoreData()
                }
                owner.output.showOrderSheet = false
            }
            .store(in: &cancellables)
        
        input.selectedPickFilterTrigger
            .sink(with: self) { owner, filter in
                if owner.output.selectedPickFilters.contains(filter) {
                    owner.output.selectedPickFilters.remove(filter)
                } else {
                    owner.output.selectedPickFilters.insert(filter)
                }
                owner.filterStoreData()
            }
            .store(in: &cancellables)
    }
    
    private func setAddress() -> String {
        if let address = UserDefaultsManager.selectedLocation?.address {
            return address
        } else {
            return "위치를 다시 설정해주세요."
        }
    }
    
    private func fetchStoreData() {
        let publish = storeRepository.storeList(storeListParam)
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    owner.allStoreData = success.data.map { $0.asStoreSummary }
                    owner.filterStoreData()
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchPopularStoreData() {
        let publish = storeRepository.popularStore(storeListParam.category)
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    owner.allPopularStoreData = success.data.map { $0.asPopularStore }
                    owner.output.popularStores = owner.allPopularStoreData
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func filterStoreData() {
        output.storeSummaries = allStoreData.filter { store in
            var isInclude = true
            
            if output.selectedPickFilters.contains(.pickchelin) {
                isInclude = isInclude && store.isPicchelin
            }
            if output.selectedPickFilters.contains(.myPick) {
                isInclude = isInclude && store.isPick
            }
            
            return isInclude
        }
    }
}

// MARK: - Action
extension MainViewModel {
    enum Action {
        case onAppear
        case mapSheet
        case selectedLocation
        case selectedCategory(_ category: StoreCategory)
        case orderSheet
        case selectedOrder(_ order: StoreOrder)
        case selectedPickFilter(_ filter: PickFilter)
    }

    func action(_ action: Action) {
        switch action {
        case .onAppear:
            input.onAppearTrigger
                .send(())
        case .mapSheet:
            input.mapSheetTrigger
                .send(())
        case .selectedLocation:
            input.selectedLocationTrigger
                .send(())
        case .selectedCategory(let category):
            input.selectedCategoryTrigger
                .send(category)
        case .orderSheet:
            input.orderSheetTrigger
                .send(())
        case .selectedOrder(let order):
            input.selectedOrderTigger
                .send(order)
        case .selectedPickFilter(let filter):
            input.selectedPickFilterTrigger
                .send(filter)
        }
    }
}


