//
//  AppearanceManager.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/3.
//

import SwiftUI

struct AppearanceManager {
    static func setupAppearance() {
        setupTabBarAppearance()
        setupTableViewAppearance()
        setupNavigationBarAppearance()
    }
    
    private static func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = nil
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private static func setupTableViewAppearance() {
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = .white
    }
    
    private static func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
}
