//
//  MainTabView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/5.
//

import SwiftUI

struct MainTabView: View {
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]
    @Binding var banks: [Bank]
    @Binding var selectedBankId: UUID
    
    var body: some View {
        TabView {
            // Tab 1: 我的庫存
            NavigationStack {
                BankListView(banks: $banks, stocks: $stocks)
            }
            .padding(.top, 65)
            .tabItem {
                Label("我的庫存", systemImage: "chart.pie.fill")
            }
            
            // Tab 2: 觀察清單
            NavigationStack {
                WatchlistView(watchlist: $watchlist)
            }
            .padding(.top, 65)
            .tabItem {
                Label("觀察清單", systemImage: "star.fill")
            }
            
            // Tab 3: 投資總覽
            NavigationStack {
                InvestmentOverviewView(stocks: $stocks)
            }
            .padding(.top, 65)
            .tabItem {
                Label("投資總覽", systemImage: "chart.bar.fill")
            }
            // Tab 4: 最新資訊
            NavigationStack {
                NewsView()
            }
            .padding(.top, 65)
            .tabItem {
                Label("最新資訊", systemImage: "newspaper.fill")
            }
            // Tab 5: 更多設定
            NavigationStack {
                SettingsView()
            }
            .padding(.top, 65)
            .tabItem {
                Label("更多設定", systemImage: "gearshape.fill")
            }
        }
    }
}

#Preview {
    ContentView()
}

