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
    }

    struct Output {
        var showMapSheet = false
        var address = ""
    }

    func transform() {
        input.onAppearTrigger
            .sink(with: self) { owner, _ in
                owner.output.address = owner.setAddress()
//                owner.fetchStoreData()
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
                // TODO: 가게 리스트 refresh
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
        print(#function)
        let publish = storeRepository.storeList(storeListParam)
        publish
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    dump(success)
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchPopularStoreData() {
        let publish = storeRepository.popularStore(storeListParam.category)
        publish
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    dump(success)
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Action
extension MainViewModel {
    enum Action {
        case onAppear
        case mapSheet
        case selectedLocation
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
        }
    }
}


