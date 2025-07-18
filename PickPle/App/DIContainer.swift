//
//  DIContainer.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import Foundation

final class DIContainer: ObservableObject {
    private let networkManager: NetworkManager
    
    let userRepository: UserRepository
    let storeRepository: StoreRepository
    let postRepository: PostRepository
    let chatRepository: ChatRepository
    let realmRepository: RealmRepository
    let bannerRepository: BannerRepository
    let orderRepository: OrderRepository
    let paymentRepository: PaymentRepository
    
    let cartManager: CartManager
    let paymentManager: PaymentManager

    init() {
        self.networkManager = NetworkManager()
        self.userRepository = DefaultUserRepository(networkManager: networkManager)
        self.storeRepository = DefaultStoreRepository(networkManager: networkManager)
        self.postRepository = DefaultPostRepository(networkManager: networkManager)
        self.chatRepository = DefaultChatRepository(networkManager: networkManager)
        self.realmRepository = DefaultRealmRepository()
        self.bannerRepository = DefaultBannerRepository(networkManager: networkManager)
        self.orderRepository = DefaultOrderRepository(networkManager: networkManager)
        self.paymentRepository = DefaultPaymentRepository(networkManager: networkManager)

        self.cartManager = CartManager()
        self.paymentManager = PaymentManager(
            orderRepository: orderRepository,
            paymentRepository: paymentRepository,
            storeRepository: storeRepository,
            cartManager: cartManager
        )
    }
}
