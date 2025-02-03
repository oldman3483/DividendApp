//
//  MainTabView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/3.
//

import SwiftUI

struct MainTabView: View {
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]
    @Binding var banks: [Bank]
    @State private var isEditing = false
    
    var body: some View {
        TabView {
            NavigationStack {
                BankListView(banks: $banks, stocks: $stocks)
                    .padding(.top, 65)
            }
            .tabItem {
                Label("庫存股", systemImage: "chart.pie.fill")
            }
            
            NavigationStack {
                WatchlistView(watchlist: $watchlist, isEditing: $isEditing)
                    .padding(.top, 65)
            }
            .tabItem {
                Label("觀察清單", systemImage: "star.fill")
            }
            
            NavigationStack {
                Text("投資總覽")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("投資總覽")
                                .navigationTitleStyle()
                        }
                    }
                    .padding(.top, 65)
            }
            .tabItem {
                Label("投資總覽", systemImage: "chart.bar.fill")
            }
        }
    }
}

#Preview {
    ContentView()
}
