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
    @State private var showingAddSheet = false
    let stockService = LocalStockService()
    
    var body: some View {
        mainView
            .sheet(isPresented: $showingAddSheet) {
                AddStockView(stocks: $stocks, watchlist: $watchlist)
            }
            .onAppear {
                loadData()
            }
            .onChange(of: stocks) { oldValue, newValue in
                saveData()
            }
            .onChange(of: watchlist) { oldValue, newValue in
                saveData()
            }
    }
    
    private var mainView: some View {
        ZStack(alignment: .top) {
            SearchBarView(
                searchText: $searchText,
                stocks: $stocks,
                watchlist: $watchlist
            )
                .zIndex(1)
            
            TabView {
                portfolioTab
                watchlistTab
                overviewTab
            }
        }
    }
    
    private var portfolioTab: some View {
        NavigationStack {
            StockPortfolioView(stocks: $stocks, isEditing: $isEditing)
        }
        .padding(.top, 65)
        .tabItem {
            Label("庫存股", systemImage: "chart.pie.fill")
        }
    }
    
    private var watchlistTab: some View {
        NavigationStack {
            WatchlistView(watchlist: $watchlist, isEditing: $isEditing)
        }
        .padding(.top, 65)
        .tabItem {
            Label("觀察清單", systemImage: "star.fill")
        }
    }
    
    private var overviewTab: some View {
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
    
    // Data persistence methods
    private func saveData() {
        if let encodedStocks = try? JSONEncoder().encode(stocks) {
            UserDefaults.standard.set(encodedStocks, forKey: "stocks")
        }
        
        if let encodedWatchlist = try? JSONEncoder().encode(watchlist) {
            UserDefaults.standard.set(encodedWatchlist, forKey: "watchlist")
            UserDefaults.standard.synchronize()
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
