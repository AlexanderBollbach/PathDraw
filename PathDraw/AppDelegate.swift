//
//  AppDelegate.swift
//  PathDraw
//
//  Created by Alexander Bollbach on 11/18/18.
//  Copyright © 2018 Alexander Bollbach. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let appState = AppState()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow.init(frame: UIScreen.main.bounds)
        
        window?.rootViewController = ViewController(appState: appState)
        
        window?.makeKeyAndVisible()
        
        return true
    }
}

