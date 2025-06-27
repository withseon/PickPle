//
//  DIContainer.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import Foundation

final class DIContainer: ObservableObject {
    @Published var locationManager: LocationManager
    
    private let networkManager: NetworkManager
    
    let userRepository: UserRepository
    let storeRepository: StoreRepository
    let postRepository: PostRepository
    
    init() {
        self.locationManager = LocationManager()
        self.networkManager = NetworkManager()
        self.userRepository = DefaultUserRepository(networkManager: networkManager)
        self.storeRepository = DefaultStoreRepository(networkManager: networkManager)
        self.postRepository = DefaultPostRepository(networkManager: networkManager)
    }
}
