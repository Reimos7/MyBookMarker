//
//  AppDelegate.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import UIKit
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.keyboardDistance = -10 // 키보드와 텍스트 필드 사이 간격 (기본값: 10)
        // Override point for customization after application launch.

        // Realm 데이터베이스 초기화
        setupDatabase()

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

