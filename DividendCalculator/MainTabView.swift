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
    @Binding var isEditing: Bool
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
                WatchlistView(watchlist: $watchlist, isEditing: $isEditing)
            }
            .padding(.top, 65)
            .tabItem {
                Label("觀察清單", systemImage: "star.fill")
            }
            
            // Tab 3: 投資總覽
            NavigationStack {
                Text("投資總覽")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("投資總覽")
                                .navigationTitleStyle()
                        }
                    }
            }
            .padding(.top, 65)
            .tabItem {
                Label("投資總覽", systemImage: "chart.bar.fill")
            }
        }
    }
}
