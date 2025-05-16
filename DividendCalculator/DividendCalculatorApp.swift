//
//  DividendCalculatorApp.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import SwiftUI

@main
struct DividendCalculatorApp: App {
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(networkMonitor)
//                .environmentObject(adManager) // 添加這行
        }
    }
}
