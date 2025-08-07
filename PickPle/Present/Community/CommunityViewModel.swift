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
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
                owner.postListParam.next = nil
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
        
        input.dataPagingTrigger
            .sink(with: self) { owner, _ in
                if owner.isPaginationEnabled {
                    owner.fetchPostData()
                }
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
                    let startIndex: Int
                    if let _ = owner.postListParam.next {
                        startIndex = owner.output.postSummaries.count
                        owner.output.postSummaries.append(contentsOf: success.data.map { $0.asPostSummary })
                    } else {
                        startIndex = 0
                        owner.output.postSummaries = success.data.map { $0.asPostSummary }
                    }
                    owner.postListParam.next = success.nextCursor
                    owner.isPaginationEnabled = success.data.count >= owner.postListParam.limit

                    // ✅ 백그라운드에서 주소 로드
                    owner.loadStoreAddresses(startIndex: startIndex)

                case .failure(let error):
                    print(error)
                }
            }
            .store(in: &cancellables)
    }

    /// GeocodingService를 사용하여 매장 주소 로드
    private func loadStoreAddresses(startIndex: Int) {
        let endIndex = output.postSummaries.count

        for index in startIndex..<endIndex {
            let post = output.postSummaries[index]

            // 매장이 없거나 이미 주소가 있으면 스킵
            guard !post.storeId.isEmpty, post.geolocation.address.isEmpty else {
                continue
            }

            GeocodingService.shared.convertToAddress(
                latitude: post.geolocation.latitude,
                longitude: post.geolocation.longitude
            ) { [weak self] result in
                guard let self else { return }

                if case .success(let address) = result {
                    DispatchQueue.main.async {
                        // 인덱스 범위 체크
                        guard index < self.output.postSummaries.count,
                              self.output.postSummaries[index].postId == post.postId else {
                            return
                        }

                        // Location 업데이트
                        var updatedLocation = self.output.postSummaries[index].geolocation
                        updatedLocation = Location(
                            latitude: updatedLocation.latitude,
                            longitude: updatedLocation.longitude,
                            address: address
                        )
                        self.output.postSummaries[index].geolocation = updatedLocation
                    }
                }
            }
        }
    }
    
    // MARK: - NotificationCenter Setup
    private func setupNotificationObservers() {
        // 게시글 생성 알림
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostCreated),
            name: Notification.Name("PostCreated"),
            object: nil
        )
        
        // 게시글 수정 알림
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostUpdated(_:)),
            name: Notification.Name("PostUpdated"),
            object: nil
        )
        
        // 게시글 삭제 알림
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostDeleted(_:)),
            name: Notification.Name("PostDeleted"),
            object: nil
        )
        
        // 위치 변경 알림
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationChanged),
            name: Notification.Name("LocationChanged"),
            object: nil
        )
    }
    
    @objc private func handlePostCreated() {
        print("📝 [CommunityViewModel] 새 게시글 생성됨 - 리스트 새로고침")
        DispatchQueue.main.async { [weak self] in
            self?.action(.fetchData)
        }
    }
    
    @objc private func handlePostUpdated(_ notification: Notification) {
        guard let postId = notification.object as? String else { return }
        print("📝 [CommunityViewModel] 게시글 수정됨 (ID: \(postId)) - 리스트 새로고침")
        DispatchQueue.main.async { [weak self] in
            self?.action(.fetchData)
        }
    }
    
    @objc private func handlePostDeleted(_ notification: Notification) {
        guard let postId = notification.object as? String else { return }
        print("📝 [CommunityViewModel] 게시글 삭제됨 (ID: \(postId)) - 로컬에서 제거")
        DispatchQueue.main.async { [weak self] in
            // 로컬에서 해당 게시글 제거 (더 빠른 UI 업데이트)
            self?.output.postSummaries.removeAll { $0.postId == postId }
            // 전체 새로고침도 수행 (서버 동기화)
            self?.action(.fetchData)
        }
    }
    
    @objc private func handleLocationChanged() {
        print("📍 [CommunityViewModel] 위치 변경됨 - 게시글 목록 새로고침")
        DispatchQueue.main.async { [weak self] in
            self?.action(.fetchData)
        }
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

