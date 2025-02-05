//
//  ContentView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import SwiftUI

struct ContentView: View {
    // 狀態變數
    @State private var stocks: [Stock] = []
    @State private var watchlist: [WatchStock] = []
    @State private var searchText: String = ""
    @State private var isEditing = false
    @State private var selectedBankId: UUID = UUID()
    @State private var banks: [Bank] = []
    
    let stockService = LocalStockService()
    
    var body: some View {
        let searchBar = SearchBarView(
            searchText: $searchText,
            stocks: $stocks,
            watchlist: $watchlist,
            bankId: selectedBankId
        )
        
        let mainContent = MainTabView(
            stocks: $stocks,
            watchlist: $watchlist,
            banks: $banks,
            isEditing: $isEditing,
            selectedBankId: $selectedBankId
        )
        
        return ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: -45) {
                searchBar.zIndex(1)
                mainContent
            }
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: stocks) { _ in saveData() }
        .onChange(of: watchlist) { _ in saveData() }
        .onChange(of: banks) { newValue in
            saveData()
            if let firstBank = newValue.first {
                selectedBankId = firstBank.id
            }
        }
    }
    
    private func setupInitialState() {
        setupAppearance()
        loadData()
        if let firstBank = banks.first {
            selectedBankId = firstBank.id
        }
    }
    
    private func setupAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .white
        tabBarAppearance.shadowColor = nil
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = .white
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .white
        navBarAppearance.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "stocks"),
           let decoded = try? JSONDecoder().decode([Stock].self, from: data) {
            stocks = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "watchlist"),
           let decoded = try? JSONDecoder().decode([WatchStock].self, from: data) {
            watchlist = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "banks"),
           let decoded = try? JSONDecoder().decode([Bank].self, from: data) {
            banks = decoded
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(stocks) {
            UserDefaults.standard.set(encoded, forKey: "stocks")
        }
        
        if let encoded = try? JSONEncoder().encode(watchlist) {
            UserDefaults.standard.set(encoded, forKey: "watchlist")
        }
        
        if let encoded = try? JSONEncoder().encode(banks) {
            UserDefaults.standard.set(encoded, forKey: "banks")
        }
    }
}

#Preview {
    ContentView()
}
