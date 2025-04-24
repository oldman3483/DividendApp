//
//  AppDelegate.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/4/24.
//

import UIKit
import Firebase
import AuthenticationServices

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
