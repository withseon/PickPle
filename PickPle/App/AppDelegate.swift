//
//  AppDelegate.swift
//  PickPle
//
//  Created by 정인선 on 5/17/25.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import iamport_ios

class AppDelegate: NSObject, UIApplicationDelegate {
    var appCoordinator: AppCoordinator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 앱 최초 실행 시 키체인 토큰 초기화
        UserDefaultsManager.resetKeychainIfNeeded()
        
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
        
        // UpdateAppBadge 알림 관찰자 추가
        setupBadgeUpdateObserver()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) { }
    
    // ✅ 앱이 활성화될 때 모든 알림 삭제 + 배지 설정 (기존 로직 유지)
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("📱 앱이 활성화됨")
        Task {
            await MainActor.run {
                let totalUnreadCount = appCoordinator?.diContainer.realmRepository.getAllUnreadCount() ?? 0
                application.applicationIconBadgeNumber = totalUnreadCount
                print("📱 앱 배지 설정: \(totalUnreadCount)")
                
                // ✅ 탭바 배지 업데이트 (기존 앱 배지 로직은 유지)
                appCoordinator?.updateTotalUnreadCount()
            }
        }
        clearAllNotifications()
    }
}

extension AppDelegate: MessagingDelegate {
    // 토큰 갱신 모니터링
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("✅✅✅ FCM 등록 토큰: \(String(describing: fcmToken))")
        
        if let apnsToken = Messaging.messaging().apnsToken {
            let tokenString = apnsToken.map { String(format: "%02.2hhx", $0) }.joined()
            print("📦 APNs 토큰: \(tokenString)")
        } else {
            print("❗️아직 APNs 토큰이 설정되지 않음")
        }
        
        if DeviceToken.value != fcmToken {
            DeviceToken.value = fcmToken
            Task {
                do {
                    try await appCoordinator?.diContainer.userRepository.deviceToken()
                } catch {
                    print("❗️❗️❗️디바이스 토큰 갱신 실패 - \(error)")
                }
            }
        } else {
            print("✅ 기존 디바이스 토큰 사용 중")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // 포그라운드 상황에서도 알림 띄우기
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("📱 포그라운드 알림: \(userInfo)")
        
        if let roomId = userInfo["room_id"] as? String {
            print("채팅방 ID: \(roomId)")
            
            // 현재 해당 채팅방에 있으면 알림 차단
            if ChatStateManager.shared.isCurrentChatRoom(roomId) {
                print("❗️ 현재 채팅방(\(roomId))에 있어서 알림 차단")
                completionHandler([]) // 알림 표시하지 않음
                return
            }
            
            // 포그라운드에서 알림을 받으면 안 읽은 메시지 개수 업데이트
            updateUnreadCountFromNotification(roomId: roomId)
        }
        
        completionHandler([.list, .banner])
    }
    
    // 백그라운드에서 알림 수신
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("📱 백그라운드 알림 수신: \(userInfo)")
        
        if let roomId = userInfo["room_id"] as? String {
            // 백그라운드에서도 안 읽은 메시지 개수 업데이트
            // 현재 해당 채팅방에 있지 않다면 개수 증가
            if !ChatStateManager.shared.isCurrentChatRoom(roomId) {
                updateUnreadCountFromNotification(roomId: roomId)
            }
        }
        
        completionHandler(.newData)
    }
    
    // 알림 탭 했을 때
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // 모든 알림 삭제
        clearAllNotifications()
        handleFCMNavigation(userInfo, fromLaunch: false)
        
        completionHandler()
    }
    
    // 모든 알림 삭제 (private → internal로 변경)
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🗑️ 모든 푸시 알림 삭제됨")
    }
    
    private func setupBadgeUpdateObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBadgeUpdate),
            name: NSNotification.Name("UpdateAppBadge"),
            object: nil
        )
    }
    
    @objc private func handleBadgeUpdate() {
        Task {
            await MainActor.run {
                let totalUnreadCount = appCoordinator?.diContainer.realmRepository.getAllUnreadCount() ?? 0
                UIApplication.shared.applicationIconBadgeNumber = totalUnreadCount
                print("📱 앱 배지 업데이트: \(totalUnreadCount)")
                
                // ✅ 탭바 배지도 업데이트
                appCoordinator?.updateTotalUnreadCount()
            }
        }
    }

    // 알림에서 안 읽은 메시지 개수 업데이트 (기존 로직 유지)
    private func updateUnreadCountFromNotification(roomId: String) {
        print("📊 안 읽은 메시지 개수 업데이트: \(roomId)")
        
        Task {
            await MainActor.run {
                // 특정 채팅방의 안 읽은 메시지 수 증가
                appCoordinator?.diContainer.realmRepository.incrementUnreadCount(roomId: roomId)
                
                // 앱 배지 업데이트
                let totalUnreadCount = appCoordinator?.diContainer.realmRepository.getAllUnreadCount() ?? 0
                UIApplication.shared.applicationIconBadgeNumber = totalUnreadCount
                print("📱 앱 배지 업데이트: \(totalUnreadCount)")
                
                // UI 업데이트를 위해 알림 전송 (기존과 동일)
                NotificationCenter.default.post(
                    name: NSNotification.Name("UpdateUnreadCount"),
                    object: nil,
                    userInfo: ["roomId": roomId]
                )
                
                // ✅ 탭바 배지 업데이트도 추가
                appCoordinator?.updateTotalUnreadCount()
            }
        }
    }
}

extension AppDelegate {
    private func handleFCMNavigation(_ userInfo: [AnyHashable: Any], fromLaunch: Bool) {
        guard let roomId = userInfo["room_id"] as? String else {
            print("❗️ room_id 없음")
            return
        }
        
        var senderNick = "알 수 없음"
        if let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: Any],
           let subtitle = alert["subtitle"] as? String {
            senderNick = subtitle
        }

        // 앱 실행 시에는 약간의 지연 후 처리 (앱 초기화 대기)
        if fromLaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.navigateToChatRoom(roomId: roomId, nick: senderNick)
            }
        } else {
            // 이미 실행 중인 앱에서는 즉시 처리
            DispatchQueue.main.async {
                self.navigateToChatRoom(roomId: roomId, nick: senderNick)
            }
        }
    }
    
    // 📱 채팅방으로 이동
    private func navigateToChatRoom(roomId: String, nick: String) {
        guard let appCoordinator else {
            print("❌ AppCoordinator가 설정되지 않았습니다")
            return
        }
        
        print("🎯 채팅방 이동 실행: \(roomId)")
        appCoordinator.navigateToChatRoom(roomId: roomId, nick: nick)
    }

}

// MARK: - Iamport
extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        Iamport.shared.receivedURL(url)
        return true
    }
}
