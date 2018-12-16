//
//  AppDelegate.swift
//  PathDraw
//
//  Created by Alexander Bollbach on 11/18/18.
//  Copyright © 2018 Alexander Bollbach. All rights reserved.
//

import UIKit

import ReSwift
import RxSwift

var store: Store<UndoState>!

var dispatchObserver: AnyObserver<Action> = AnyObserver.init { event in
    
    switch event {
    case .next(let element):
        store.dispatch(element)
    default:
        fatalError()
    }
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        store = Store(
            reducer: undoReducer(reducer: rootReducer),
            state: UndoContainer.init(past: [], future: [], present: AppState())
        )
        
        window = UIWindow.init(frame: UIScreen.main.bounds)
        
        window?.rootViewController = ViewController()
        
        window?.makeKeyAndVisible()
        
        return true
    }
}

