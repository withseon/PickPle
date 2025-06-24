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
        let selectCategoryTrigger = PassthroughSubject<Int, Never>()
    }

    struct Output {
        var storeDetailData: StoreDetail =  StoreDetail.empty
        var categories = [String]()
        var selectedCategoryIndex = 0
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
    }
    
    private func fetchStoreDetail() {
        let publisher = storeRepository.storeDetail(storeId)
        publisher
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    let storeDetailData = success.asStoreDetail
                    owner.output.storeDetailData = storeDetailData
                    owner.output.categories = storeDetailData.categoryList.map { $0.title }
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
    }

    func action(_ action: Action) {
        switch action {
        case .onAppear:
            input.onAppearTrigger
                .send(())
        case .selectCategory(let index):
            input.selectCategoryTrigger
                .send(index)
        }
    }
}
