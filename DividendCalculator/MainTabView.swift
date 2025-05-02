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
    
    // 讀取離線模式設置
    @AppStorage("offlineMode") private var offlineMode = false
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    
    var body: some View {
        TabView {
            // Tab 1: 總覽
            NavigationStack {
                OverviewView(banks: $banks, stocks: $stocks)
            }
            .padding(.top, 40)
            .tabItem {
                Label("總覽", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            // Tab 2: 觀察清單
            NavigationStack {
                WatchlistView(
                    watchlist: $watchlist,
                    stocks: $stocks,
                    banks: $banks
                )
            }
            .padding(.top, 40)
            .tabItem {
                Label("觀察清單", systemImage: "star.fill")
            }
            
            // Tab 3: 投資總覽
            NavigationStack {
                InvestmentOverviewView(stocks: $stocks)
            }
            .padding(.top, 40)
            .tabItem {
                Label("投資總覽", systemImage: "chart.bar.fill")
            }
            
            // Tab 4: 最新資訊
            NavigationStack {
                NewsView(stocks: $stocks)
            }
            .padding(.top, 40)
            .tabItem {
                Label("最新資訊", systemImage: "newspaper.fill")
            }
            
            // Tab 5: 更多設定
            NavigationStack {
                SettingsView()
            }
            .padding(.top, 40)
            .tabItem {
                Label("更多設定", systemImage: "gearshape.fill")
            }
        }
        // 離線模式指示器只在 TabView 層級添加一次，而不是每個分頁都添加
        .overlay(
            Group {
                if offlineMode {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.white)
                            Text("離線模式")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(15)
                        .padding(.trailing, 10)
                        .padding(.top, 40)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        )
    }
}
