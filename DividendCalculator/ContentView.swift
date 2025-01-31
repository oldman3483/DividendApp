//
//  ContentView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import SwiftUI

struct ContentView: View {
    @State private var stocks: [Stock] = []
    @State private var watchlist: [WatchStock] = []
    @State private var searchText: String = ""
    @State private var isEditing = false
    let stockService = LocalStockService()
    @State private var banks: [Bank] = []  // 新增以保存銀行列表

    
    var body: some View {
        mainView
            .onAppear {
                loadData()
            }
            .onChange(of: stocks) { oldValue, newValue in
                saveData()
            }
            .onChange(of: watchlist) { oldValue, newValue in
                saveData()
            }
            .onChange(of: banks) { oldValue, newValue in
                saveData()
            }
    }
    
    private var mainView: some View {
        ZStack(alignment: .top) {
            SearchBarView(
                searchText: $searchText,
                stocks: $stocks,
                watchlist: $watchlist,
                bankId: UUID()
            )
            .zIndex(1)
            
            TabView {
                NavigationStack{
                    BankListView(banks: $banks, stocks: $stocks)
                }
                .padding(.top, 65)  // 保持原有的 padding
                .tabItem {
                    Label("庫存股", systemImage: "chart.pie.fill")
                }
                
                NavigationStack {
                    WatchlistView(watchlist: $watchlist, isEditing: $isEditing)
                }
                .padding(.top, 65)  // 保持原有的 padding
                .tabItem {
                    Label("觀察清單", systemImage: "star.fill")
                }
                
                NavigationStack {
                    Text("投資總覽")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("投資總覽")
                                    .font(.system(size: 30, weight: .bold))
                            }
                        }
                }
                .padding(.top, 65)
                .tabItem {
                    Label("投資總覽", systemImage: "chart.bar.fill")
                }
            }
            
            .accentColor(.blue)// 微調選中的顏色
        }
    }

    
    // Data persistence methods
    private func saveData() {
        if let encodedStocks = try? JSONEncoder().encode(stocks) {
            UserDefaults.standard.set(encodedStocks, forKey: "stocks")
        }
        
        if let encodedWatchlist = try? JSONEncoder().encode(watchlist) {
            UserDefaults.standard.set(encodedWatchlist, forKey: "watchlist")
            UserDefaults.standard.synchronize()
        }
        if let encodedBanks = try? JSONEncoder().encode(banks) {
            UserDefaults.standard.set(encodedBanks, forKey: "banks")
        }
        
        UserDefaults.standard.synchronize()

    }
    
    private func loadData() {
        if let savedStocks = UserDefaults.standard.data(forKey: "stocks"),
           let decodedStocks = try? JSONDecoder().decode([Stock].self, from: savedStocks) {
            stocks = decodedStocks
        }
        
        if let savedWatchlist = UserDefaults.standard.data(forKey: "watchlist"),
           let decodedWatchlist = try? JSONDecoder().decode([WatchStock].self, from: savedWatchlist) {
            watchlist = decodedWatchlist
        }
        
        if let savedBanks = UserDefaults.standard.data(forKey: "banks"),
           let decodedBanks = try? JSONDecoder().decode([Bank].self, from: savedBanks) {
            banks = decodedBanks
        }
    }
}

#Preview {
    ContentView()
}
