//
//  ContentView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import SwiftUI

struct ContentView: View {
    // MARK: - 狀態變數
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var stocks: [Stock] = []
    @State private var watchlist: [WatchStock] = []
    @State private var searchText: String = ""
    @State private var isEditing = false
    @State private var selectedBankId: UUID = UUID()
    @State private var banks: [Bank] = []
    @State private var showingLogoutAlert = false
    
    let stockService = LocalStockService()
    
    // MARK: - 視圖
    var body: some View {
        if !isLoggedIn {
            LoginView()
        } else {
            mainContent
        }
    }
    
    // MARK: - 主要內容視圖
    private var mainContent: some View {
        let searchBar = SearchBarView(
            searchText: $searchText,
            stocks: $stocks,
            watchlist: $watchlist,
            banks: $banks,
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
            Color.black.ignoresSafeArea()
            
            VStack(spacing: -45) {
                searchBar.zIndex(1)
                mainContent
            }
        }
        .alert("登出確認", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("登出", role: .destructive) { handleLogout() }
        } message: {
            Text("確定要登出嗎？")
        }
        .onAppear {
            setupInitialState()
        }
        .onChange(of: stocks) { oldValue, newValue in saveData() }
        .onChange(of: watchlist) { oldValue, newValue in saveData() }
        .onChange(of: banks) { oldValue, newValue in
            saveData()
            if let firstBank = newValue.first {
                selectedBankId = firstBank.id
            }
        }
    }
    
    // MARK: - 方法
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
        tabBarAppearance.backgroundColor = .black
        tabBarAppearance.shadowColor = nil
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = .black
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .black
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
    
    private func handleLogout() {
        // 清除登入狀態
        isLoggedIn = false
        
        // 可以選擇是否要清除資料
        // 如果要保留資料，可以不執行以下程式碼
        stocks = []
        watchlist = []
        banks = []
        UserDefaults.standard.removeObject(forKey: "stocks")
        UserDefaults.standard.removeObject(forKey: "watchlist")
        UserDefaults.standard.removeObject(forKey: "banks")
    }
}

#Preview {
    ContentView()
}
