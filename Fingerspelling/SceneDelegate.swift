import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
    // Modify initial state for testing/screenshots
    #if DEBUG
      if isUITesting() {
        let game = SystemServices.game
        let settings = SystemServices.settings
        for _ in 0 ..< 27 {
          game.receptiveCompletedWords.append(CompletedWord("abcde", speed: 4.0))
        }
        game.receptiveCompletedWords.append(CompletedWord("turkey", speed: 8.0))
        for _ in 0 ..< 12 {
          game.expressiveCompletedWords.append("abcde")
        }
        settings.speed = 3.0
      }
    #endif

    let contentView = AppView()
      .modifier(SystemServices())

    // Use a UIHostingController as window root view controller.
    if let windowScene = scene as? UIWindowScene {
      let window = UIWindow(windowScene: windowScene)
      window.rootViewController = UIHostingController(rootView: contentView)
      self.window = window
      window.makeKeyAndVisible()
    }
  }

  func sceneDidDisconnect(_: UIScene) {}

  func sceneDidBecomeActive(_: UIScene) {}

  func sceneWillResignActive(_: UIScene) {}

  func sceneWillEnterForeground(_: UIScene) {}

  func sceneDidEnterBackground(_: UIScene) {}
}
