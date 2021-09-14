//
//  AppDelegate.swift
//  InstagramDownload
//
//  Created by JinGu's iMac on 2021/09/14.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var mainCon : MainViewController?
    var naviCon : UINavigationController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
        
        mainCon = MainViewController()
        naviCon = UINavigationController(rootViewController: mainCon!)
        naviCon?.isNavigationBarHidden = true
        
        window?.rootViewController = naviCon
        
        window?.makeKeyAndVisible()
        
        
        
        return true
    }

}

