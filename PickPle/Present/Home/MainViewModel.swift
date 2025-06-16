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
        let likeStoreTrigger = PassthroughSubject<(id: String, isPick: Bool), Never>()
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
                owner.fetchStoreData()
                owner.fetchPopularStoreData()
            }
            .store(in: &cancellables)
        
        input.selectedCategoryTrigger
            .sink(with: self) { owner, category in
                if owner.output.selectedCategory == category {
                    owner.output.selectedCategory = nil
                    owner.storeListParam.category = nil
                } else {
                    owner.output.selectedCategory = category
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
        
        input.likeStoreTrigger
            .sink(with: self) { owner, storeInfo in
                owner.updatePopularStorePick(storeInfo.id)
                owner.updateSummaryStorePick(storeInfo.id)
            }
            .store(in: &cancellables)
        
        input.likeStoreTrigger
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink(with: self) { owner, storeInfo in
                owner.likeStore(id: storeInfo.id, isPick: !storeInfo.isPick)
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
    
    private func likeStore(id: String, isPick: Bool) {
        let publish = storeRepository.likeStore(id, isPick)
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    owner.updatePopularStorePick(id)
                    owner.updateSummaryStorePick(id)
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updatePopularStorePick(_ storeId: String) {
        guard let index = allPopularStoreData.firstIndex(where: { $0.storeId == storeId }) else { return }
        allPopularStoreData[index].isPick.toggle()
        let temp = allPopularStoreData[index].isPick ? 1 : -1
        allPopularStoreData[index].pickCount += temp
        
        output.popularStores[index].isPick.toggle()
        output.popularStores[index].pickCount += temp
    }
    
    private func updateSummaryStorePick(_ storeId: String) {
        guard let index = allStoreData.firstIndex(where: { $0.storeId == storeId }) else { return }
        allStoreData[index].isPick.toggle()
        let temp = allStoreData[index].isPick ? 1 : -1
        allStoreData[index].pickCount += temp
        
        filterStoreData()
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
        case likeStore(_ id: String, _ isPick: Bool)
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
        case .likeStore(let id, let isPick):
            input.likeStoreTrigger
                .send((id, isPick))
        }
    }
}


