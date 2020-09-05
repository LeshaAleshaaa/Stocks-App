//
//  SceneDelegate.swift
//  Smitskiy A.D. (Stocks)
//
//  Created by Алексей Смицкий on 28.08.2020.
//  Copyright © 2020 Смицкий А.Д. All rights reserved.
//

import UIKit

// MARK: - SceneDelegate

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // MARK: - Public properties

    var window: UIWindow?
    
    // MARK: - Public methods
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

}
