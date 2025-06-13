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
    
    let userRepository: DefaultUserRepository
    let storeRepository: DefaultStoreRepository
    
    init() {
        self.locationManager = LocationManager()
        self.networkManager = NetworkManager()
        self.userRepository = DefaultUserRepository(networkManager: networkManager)
        self.storeRepository = DefaultStoreRepository(networkManager: networkManager)
    }
}
