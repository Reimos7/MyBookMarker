//
//  AppDelegate.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.keyboardDistance = -10 // 키보드와 텍스트 필드 사이 간격 (기본값: 10)
        // Override point for customization after application launch.

        // Realm 데이터베이스 초기화
        setupDatabase()
        // 앱이 처음 실행될때 연결 되어 있어야하기 때문에 AppDelegate에 사용 
        FirebaseApp.configure()
        
        // push에 대한 코드 - 로컬 푸시 상관없이 같은 코드
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { granted, error in
              if let error = error {
                  print("Push notification authorization error: \(error)")
              }
              print("Push notification permission granted: \(granted)")
          }
        )
        // 원격 알림 사용한다는 의미
        application.registerForRemoteNotifications()

        // 파이어베이스가 APNs 대신 메시지를 보낼 수 있게 설정
        Messaging.messaging().delegate = self

        // 현재 등록 토큰 가져오기
        Messaging.messaging().token { token, error in
          if let error = error {
            print("Error fetching FCM registration token: \(error)")
          } else if let token = token {
            print("FCM registration token: \(token)")

          }
        }


        return true
    }

    // MARK: - Database Setup

    // Realm 데이터베이스 초기화
    // 앱 시작 시 데이터베이스를 설정하고 기본 폴더들을 생성
    private func setupDatabase() {
        // Realm 데이터베이스 초기화
        RealmManager.shared.initializeDatabase()
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }



}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // 앱이 Foreground 상태일 때 푸시 알림을 받으면 호출
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Foreground에서도 알림을 표시
        completionHandler([.banner, .sound, .badge])
    }

    // 사용자가 푸시 알림을 탭했을 때 호출
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        // 푸시 알림 탭 처리 로직
        let userInfo = response.notification.request.content.userInfo
        print("Push notification tapped: \(userInfo)")

        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    // 토큰에 대한 정보가 변경이 되면 수신할 수 있는 기능
    // 디바이스 토큰 정보가 변경이 되면 알려줌
    // push는 기기 기반으로 오는게 핵심
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
      print("Firebase registration token: \(String(describing: fcmToken))")

      let dataDict: [String: String] = ["token": fcmToken ?? ""]
      NotificationCenter.default.post(
        name: Notification.Name("FCMToken"),
        object: nil,
        userInfo: dataDict
      )
      // TODO: If necessary send token to application server.
      // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}
