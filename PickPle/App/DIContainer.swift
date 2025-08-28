//
//  DIContainer.swift
//  PickPle
//
//  Created by 정인선 on 5/25/25.
//

import Foundation

final class DIContainer: ObservableObject {
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

    // Production용 (기존 코드 호환)
    convenience init() {
        let networkManager = NetworkManager()
        self.init(
            userRepository: DefaultUserRepository(networkManager: networkManager),
            storeRepository: DefaultStoreRepository(networkManager: networkManager),
            postRepository: DefaultPostRepository(networkManager: networkManager),
            chatRepository: DefaultChatRepository(networkManager: networkManager),
            realmRepository: DefaultRealmRepository(),
            bannerRepository: DefaultBannerRepository(networkManager: networkManager),
            orderRepository: DefaultOrderRepository(networkManager: networkManager),
            paymentRepository: DefaultPaymentRepository(networkManager: networkManager)
        )
    }

    // Testing용 (Mock 주입 가능)
    init(
        userRepository: UserRepository,
        storeRepository: StoreRepository,
        postRepository: PostRepository,
        chatRepository: ChatRepository,
        realmRepository: RealmRepository,
        bannerRepository: BannerRepository,
        orderRepository: OrderRepository,
        paymentRepository: PaymentRepository
    ) {
        self.userRepository = userRepository
        self.storeRepository = storeRepository
        self.postRepository = postRepository
        self.chatRepository = chatRepository
        self.realmRepository = realmRepository
        self.bannerRepository = bannerRepository
        self.orderRepository = orderRepository
        self.paymentRepository = paymentRepository

        self.cartManager = CartManager()
        self.paymentManager = PaymentManager(
            orderRepository: orderRepository,
            paymentRepository: paymentRepository,
            storeRepository: storeRepository,
            cartManager: cartManager
        )
    }
}
