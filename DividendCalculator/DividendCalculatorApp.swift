//
//  DividendCalculatorApp.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import SwiftUI

@main
struct DividendCalculatorApp: App {
    // 創建網絡監視器實例作為環境對象
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // 強制使用深色模式
                .environmentObject(networkMonitor) // 將網絡監視器注入環境
        }
    }
}
