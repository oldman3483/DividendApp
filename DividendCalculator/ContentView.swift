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
    @State private var banks: [Bank] = []
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 10) {
                SearchBarView(
                    searchText: $searchText,
                    stocks: $stocks,
                    watchlist: $watchlist,
                    banks: $banks
                )
                .zIndex(1)
                
                MainTabView(
                    stocks: $stocks,
                    watchlist: $watchlist,
                    banks: $banks
                )
            }
        }
        .onAppear {
            AppearanceManager.setupAppearance()
            loadData()
        }
        .onChange(of: stocks) { _, _ in
            DataManager.shared.saveStocks(stocks)
        }
        .onChange(of: watchlist) { _, _ in
            DataManager.shared.saveWatchlist(watchlist)
        }
        .onChange(of: banks) { _, _ in
            DataManager.shared.saveBanks(banks)
        }
    }
    
    private func loadData() {
        stocks = DataManager.shared.loadStocks()
        watchlist = DataManager.shared.loadWatchlist()
        banks = DataManager.shared.loadBanks()
    }
}

#Preview {
    ContentView()
}
