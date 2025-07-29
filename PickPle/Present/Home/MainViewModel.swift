//
//  MainViewModel.swift
//  PickPle
//

import Foundation
import Combine

final class MainViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    private let storeRepository: StoreRepository
    private let bannerRepository: BannerRepository
    private var storeListParam = StoreListParam.empty
    
    private var hasInitialized = false

    private var allPopularStoreData = [PopularStore]()
    private var allStoreData = [StoreSummary]()  // 서버에서 받은 원본 데이터
    private var searchPopularData = [String]()
    private var currentSearchPopular = 0
    private var searchTimerCancellable: AnyCancellable?
    private var isPaginationEnabled = false

    init(
        storeRepository: StoreRepository,
        bannerRepository: BannerRepository
    ) {
        self.storeRepository = storeRepository
        self.bannerRepository = bannerRepository
        super.init()
        transform()
    }

    // MARK: - Input/Output
    struct Input {
        let onAppearTrigger = PassthroughSubject<Void, Never>()
        let onViewWillAppearTrigger = PassthroughSubject<Void, Never>()
        let onDisappearTrigger = PassthroughSubject<Void, Never>()
        let refreshTrigger = PassthroughSubject<Void, Never>()
        let selectedLocationTrigger = PassthroughSubject<Void, Never>()
        let selectedCategoryTrigger = PassthroughSubject<StoreCategory, Never>()
        let selectedOrderTigger = PassthroughSubject<StoreOrder, Never>()
        let selectedPickFilterTrigger = PassthroughSubject<PickFilter, Never>()
        let likeStoreTrigger = PassthroughSubject<(id: String, isPick: Bool), Never>()
        let dataPagingTrigger = PassthroughSubject<Void, Never>()
        let selectedBannerTrigger = PassthroughSubject<URL, Never>()
    }

    struct Output {
        var address = ""
        var popularStores = [PopularStore]()
        var storeSummaries = [StoreSummary]()  // 필터링된 결과
        var bannerItems = [BannerItem]()
        var searchPopular = ""
        var selectedCategory: StoreCategory? = nil
        var selectedOrder: StoreOrder = .distance
        var selectedPickFilters: Set<PickFilter> = []
        var selectedBannerURL = URL(fileURLWithPath: "")
        
        // 새로 추가: 서버 데이터 존재 여부 확인용
        var hasServerData: Bool = false  // 서버에서 받은 원본 데이터가 있는지
    }

    func transform() {
        NotificationCenter.default
            .publisher(for: NSNotification.Name("AttendanceCompleted"))
            .sink(with: self) { owner, notification in
                print("출석 완료 알림 수신!")
            }
            .store(in: &cancellables)

        // 최초 데이터 로딩
        input.onAppearTrigger
            .sink(with: self) { owner, _ in
                guard !owner.hasInitialized else { return }
                owner.hasInitialized = true
                
                owner.output.address = owner.setAddress()
                owner.fetchStoreData()
                owner.fetchPopularStoreData()
                owner.fetchSearchPopularData()
                owner.fetchBannerData()
            }
            .store(in: &cancellables)
        
        input.onViewWillAppearTrigger
            .sink(with: self) { owner, _ in
                owner.startSearchTimer()
            }
            .store(in: &cancellables)
        
        input.onDisappearTrigger
            .sink(with: self) { owner, _ in
                owner.stopSearchTimer()
            }
            .store(in: &cancellables)
        
        input.refreshTrigger
            .sink(with: self) { owner, _ in
                owner.storeListParam.next = nil
                owner.fetchStoreData()
                owner.fetchPopularStoreData()
            }
            .store(in: &cancellables)

        input.selectedLocationTrigger
            .sink(with: self) { owner, _ in
                owner.output.address = owner.setAddress()
                owner.storeListParam.next = nil
                owner.fetchStoreData()
                owner.fetchPopularStoreData()
                
                // 위치 변경 알림 전송 (CommunityView가 게시글 목록을 새로고침하도록)
                NotificationCenter.default.post(name: Notification.Name("LocationChanged"), object: nil)
            }
            .store(in: &cancellables)
        
        input.selectedCategoryTrigger
            .sink(with: self) { owner, category in
                if owner.output.selectedCategory == category {
                    owner.output.selectedCategory = nil
                    owner.storeListParam.category = nil
                    owner.storeListParam.next = nil
                } else {
                    owner.output.selectedCategory = category
                    owner.storeListParam.category = category
                    owner.storeListParam.next = nil
                }
                owner.fetchStoreData()
                owner.fetchPopularStoreData()
            }
            .store(in: &cancellables)
        
        input.selectedOrderTigger
            .sink(with: self) { owner, order in
                if owner.output.selectedOrder != order {
                    owner.output.selectedOrder = order
                    owner.storeListParam.orderBy = order
                    owner.storeListParam.next = nil
                    owner.fetchStoreData()
                }
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
        
        input.dataPagingTrigger
            .sink(with: self) { owner, _ in
                if owner.isPaginationEnabled {
                    owner.fetchStoreData()
                }
            }
            .store(in: &cancellables)
        
        input.selectedBannerTrigger
            .sink(with: self) { owner, url in
                owner.output.selectedBannerURL = url
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
                    if let _ = owner.storeListParam.next {
                        owner.allStoreData.append(contentsOf: success.data.map { $0.asStoreSummary })
                    } else {
                        owner.allStoreData = success.data.map { $0.asStoreSummary }
                    }
                    
                    // 서버 데이터 존재 여부 업데이트
                    owner.output.hasServerData = !owner.allStoreData.isEmpty
                    
                    owner.storeListParam.next = success.nextCursor
                    owner.filterStoreData()
                    if let limit = owner.storeListParam.limit {
                        owner.isPaginationEnabled = success.data.count >= limit
                    }
                case .failure(let error):
                    owner.output.hasServerData = false
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
    
    private func fetchSearchPopularData() {
        let publish = storeRepository.searchPopular()
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    owner.searchPopularData = success.data
                    owner.startSearchTimer()
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchBannerData() {
        let publish = bannerRepository.banner()
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    owner.output.bannerItems = success.data.map { $0.asBannerItem }
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func startSearchTimer() {
        guard !searchPopularData.isEmpty else { return }
        output.searchPopular = "1 \(searchPopularData[currentSearchPopular])"
        
        searchTimerCancellable = Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink(with: self) { owner, _ in
                owner.currentSearchPopular = (owner.currentSearchPopular + 1) % owner.searchPopularData.count
                owner.output.searchPopular = "\(owner.currentSearchPopular + 1) \(owner.searchPopularData[owner.currentSearchPopular])"
            }
    }
    
    private func stopSearchTimer() {
        searchTimerCancellable?.cancel()
        searchTimerCancellable = nil
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

    // MARK: - Action
    enum Action {
        case onAppear
        case onViewWillAppear
        case onDisappear
        case refresh
        case selectedLocation
        case selectedCategory(_ category: StoreCategory)
        case selectedOrder(_ order: StoreOrder)
        case selectedPickFilter(_ filter: PickFilter)
        case likeStore(_ id: String, _ isPick: Bool)
        case pagination
        case selectedBanner(_ url: URL)
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
        case .selectedLocation:
            input.selectedLocationTrigger.send(())
        case .selectedCategory(let category):
            input.selectedCategoryTrigger.send(category)
        case .selectedOrder(let order):
            input.selectedOrderTigger.send(order)
        case .selectedPickFilter(let filter):
            input.selectedPickFilterTrigger.send(filter)
        case .likeStore(let id, let isPick):
            input.likeStoreTrigger.send((id, isPick))
        case .pagination:
            input.dataPagingTrigger.send(())
        case .selectedBanner(let url):
            input.selectedBannerTrigger.send(url)
        }
    }
}
