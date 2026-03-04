//
//  SceneDelegate.swift
//  BookMarker
//
//  Created by Reimos on 9/25/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: scene)
        
        window?.overrideUserInterfaceStyle = .light

        var controllers:[UIViewController] = []
        for tab in TabbarType.allCases {
            let vc = tab.viewController

            vc.tabBarItem = UITabBarItem(title: tab.title, image: UIImage(systemName:tab.imageName), tag: tab.tag)
            let nav = UINavigationController(rootViewController: vc)
            controllers.append(nav)
        }
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = controllers
        tabBarController.selectedIndex = 1 // 홈 화면을 기본으로 설정 (검색 탭 제거 후: realMap=0, home=1, my=2)
        tabBarController.tabBar.tintColor = .black
        tabBarController.tabBar.backgroundColor = .white
        window?.rootViewController = tabBarController

        window?.makeKeyAndVisible()

        // 푸시 알림으로부터 책 상세 화면 열기 옵저버 등록
        setupNotificationObservers()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        print("SceneDelegate: Setting up notification observers...")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenBookDetail(_:)),
            name: Notification.Name("OpenBookDetail"),
            object: nil
        )
        print("SceneDelegate: Observer registered for 'OpenBookDetail'")
    }

    @objc private func handleOpenBookDetail(_ notification: Notification) {
        print("========================================")
        print("SceneDelegate received notification!")

        guard let userInfo = notification.userInfo else {
            print(" userInfo is nil")
            return
        }

        print("userInfo: \(userInfo)")

        guard let isbn = userInfo["isbn"] as? String else {
            print("isbn not found")
            return
        }
        print(" isbn: \(isbn)")

        guard let title = userInfo["title"] as? String else {
            print(" title not found")
            return
        }
        print(" title: \(title)")

        // TabBarController에서 현재 선택된 NavigationController 가져오기
        guard let tabBarController = window?.rootViewController as? UITabBarController else {
            print(" TabBarController not found")
            return
        }
        print(" TabBarController found")

        guard let navigationController = tabBarController.selectedViewController as? UINavigationController else {
            print(" NavigationController not found")
            return
        }
        print("NavigationController found")

        print("Opening book detail for ISBN: \(isbn)")

        // cover 데이터 확인
        let coverURL = userInfo["cover"] as? String
        print(" Cover URL from FCM: \(coverURL ?? "nil")")

        // FCM 페이로드에서 책 정보 생성
        let book = Item(
            title: title,
            link: userInfo["link"] as? String,
            author: userInfo["author"] as? String,
            pubDate: userInfo["pubDate"] as? String,
            description: userInfo["description"] as? String,
            isbn13: isbn,
            itemId: (userInfo["itemId"] as? String).flatMap { Int($0) },
            priceSales: (userInfo["priceSales"] as? String).flatMap { Int($0) },
            priceStandard: (userInfo["priceStandard"] as? String).flatMap { Int($0) },
            cover: userInfo["cover"] as? String,
            categoryId: (userInfo["categoryId"] as? String).flatMap { Int($0) },
            categoryName: userInfo["categoryName"] as? String,
            publisher: userInfo["publisher"] as? String,
            salesPoint: (userInfo["salesPoint"] as? String).flatMap { Int($0) },
            customerReviewRank: (userInfo["customerReviewRank"] as? String).flatMap { Int($0) },
            bestDuration: userInfo["bestDuration"] as? String,
            bestRank: (userInfo["bestRank"] as? String).flatMap { Int($0) }
        )

        // BookDetailViewController로 이동
        print(" Creating BookDetailViewController...")
        print(" Book object created:")
        print("   - title: \(book.title ?? "nil")")
        print("   - author: \(book.author ?? "nil")")
        print("   - publisher: \(book.publisher ?? "nil")")
        print("   - cover: \(book.cover ?? "nil")")
        print("   - description: \(book.description ?? "nil")")
        print("   - customerReviewRank: \(book.customerReviewRank ?? 0)")
        print("   - categoryName: \(book.categoryName ?? "nil")")

        let bookDetailVC = BookDetailViewController(book: book)
        print(" Pushing to navigation controller...")
        navigationController.pushViewController(bookDetailVC, animated: true)
        print(" Push complete!")
        print("========================================")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }


}

