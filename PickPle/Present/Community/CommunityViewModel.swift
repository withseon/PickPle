//
//  CommunityViewModel.swift
//  PickPle
//
//  Created by 정인선 on 6/7/25.
//

import Foundation
import Combine

final class CommunityViewModel: BaseViewModel, ViewModelType {
    var input = Input()
    @Published var output = Output()
    var cancellables = Set<AnyCancellable>()
    
    private let postRepository: PostRepository
    private var postListParam = PostListParam.empty
    
    private var isPaginationEnabled = false

    init(postRepository: PostRepository) {
        self.postRepository = postRepository
        super.init()
        transform()
    }
}

// MARK: - Input/Output
extension CommunityViewModel {
    struct Input {
        let fetchDataTrigger = PassthroughSubject<Void, Never>()
        let updateDistanceTrigger = PassthroughSubject<Double, Never>()
        let selectedOrderTigger = PassthroughSubject<PostOrder, Never>()
        let orderSheetTrigger = PassthroughSubject<Void, Never>()
        let likePostTrigger = PassthroughSubject<(id: String, isPick: Bool), Never>()
        let dataPagingTrigger = PassthroughSubject<Void, Never>()
    }

    struct Output {
        var distance: Double = 500
        var distanceRange: ClosedRange<Double> = 0...1000
        var postSummaries = [PostSummary]()
        var showOrderSheet = false
        var selectedOrder: PostOrder = .createdAt
    }

    func transform() {
        input.fetchDataTrigger
            .sink(with: self) { owner, _ in
                owner.fetchPostData()
            }
            .store(in: &cancellables)
        
        input.updateDistanceTrigger
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink(with: self) { owner, distance in
                if owner.output.distance != distance {
                    owner.output.distance = distance
                    owner.postListParam.distance = Int(distance)
                    owner.postListParam.next = nil
                    owner.fetchPostData()
                }
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
                    owner.postListParam.orderBy = order
                    owner.postListParam.next = nil
                    owner.fetchPostData()
                }
                owner.output.showOrderSheet = false
            }
            .store(in: &cancellables)
    }
    
    private func fetchPostData() {
        let publish = postRepository.postList(postListParam)
        publish
            .receive(on: DispatchQueue.main)
            .sink(with: self) { owner, result in
                switch result {
                case .success(let success):
                    owner.output.postSummaries = success.data.map { $0.asPostSummary }
                    owner.postListParam.next = success.nextCursor
                    if let limit = owner.postListParam.limit {
                        owner.isPaginationEnabled = success.data.count >= limit
                    }
                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Action
extension CommunityViewModel {
    enum Action {
        case fetchData
        case updateDistance(_ distance: Double)
        case orderSheet
        case selectedOrder(_ order: PostOrder)
        case likePost(_ id: String, _ isPick: Bool)
        case pagination
    }

    func action(_ action: Action) {
        switch action {
        case .fetchData:
            input.fetchDataTrigger
                .send(())
        case .updateDistance(let distance):
            input.updateDistanceTrigger
                .send(distance)
        case .orderSheet:
            input.orderSheetTrigger
                .send(())
        case .selectedOrder(let order):
            input.selectedOrderTigger
                .send(order)
        case .likePost(let id, let isPick):
            input.likePostTrigger
                .send((id, isPick))
        case .pagination:
            input.dataPagingTrigger
                .send(())
        }
    }
}

