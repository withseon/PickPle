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
    private let storeId: String

    init(storeRepository: StoreRepository, storeId: String) {
        self.storeRepository = storeRepository
        self.storeId = storeId
        super.init()
        transform()
    }

}

// MARK: - Input/Output
extension StoreDetailViewModel {
    struct Input {
        let onAppearTrigger = PassthroughSubject<Void, Never>()
    }

    struct Output {
        var storeDetailData: StoreDetail =  StoreDetail.empty
    }

    func transform() {
        input.onAppearTrigger
            .sink(with: self) { owner, _ in
                owner.fetchStoreDetail()
            }
            .store(in: &cancellables)
    }
    
    private func fetchStoreDetail() {
        let publisher = storeRepository.storeDetail(storeId)
        publisher
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    owner.output.storeDetailData = success.asStoreDetail
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
    }

    func action(_ action: Action) {
        switch action {
        case .onAppear:
            input.onAppearTrigger
                .send(())
        }
    }
}
