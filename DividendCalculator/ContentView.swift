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
    

    
    
    var body: some View {
        ZStack(alignment: .top) {
            SearchBarView(searchText: $searchText, stocks: $stocks)
                .zIndex(1)
            
            TabView {
                // 第一頁：庫存股
                NavigationStack {
                    StockPortfolioView(stocks: $stocks, isEditing: $isEditing)
                }
                .padding(.top, 65)
                .tabItem {
                    Label("庫存股", systemImage: "chart.pie.fill")
                }
                
                // 第二頁：觀察清單
                NavigationStack {
                    WatchlistView(watchlist: $watchlist, isEditing: $isEditing)
                }
                .padding(.top, 65)
                .tabItem {
                    Label("觀察清單", systemImage: "star.fill")
                }
                
                // 第三頁：投資總覽
                NavigationStack {
                    Text("投資總覽")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("投資總覽")
                                    .font(.system(size: 40, weight: .bold))
                            }
                        }
                }
                .padding(.top, 65)
                .tabItem {
                    Label("投資總覽", systemImage: "chart.bar.fill")
                }
            }
        }
        .onAppear{
            loadData()
        }
        .onChange(of: stocks) { oldValue, newValue in
            saveData()
        }
        .onChange(of: watchlist) { oldValue, newValue in
            saveData()
        }
    }
    // 資料儲存和讀取的方法放在這裡
    private func saveData() {
        if let encodedStocks = try? JSONEncoder().encode(stocks) {
            UserDefaults.standard.set(encodedStocks, forKey: "stocks")
        }
        
        if let encodedWatchlist = try? JSONEncoder().encode(watchlist) {
            UserDefaults.standard.set(encodedWatchlist, forKey: "watchlist")
        }
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
    }
}

#Preview {
    ContentView()
}
