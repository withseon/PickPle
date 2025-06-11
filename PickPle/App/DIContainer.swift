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
        let interceptor = APIRequestInterceptor()
        self.networkManager = NetworkManager(interceptor: interceptor)
        self.userRepository = DefaultUserRepository(networkManager: networkManager)
        self.storeRepository = DefaultStoreRepository(networkManager: networkManager)
        interceptor.userRepository = userRepository
    }
}
