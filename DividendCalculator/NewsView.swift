//
//  NewsView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/7.
//  Updated with category selector

import SwiftUI

struct NewsView: View {
    // 添加新的狀態變數來追蹤當前選擇的類別
    @State private var selectedCategory: NewsCategory = .all
    // 連接使用者擁有的股票
    @Binding var stocks: [Stock]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 添加新的類別選擇器
                newsCategorySelector
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                
                // 新聞列表
                List {
                    Section {
                        // 根據選擇的類別篩選新聞
                        ForEach(getFilteredNews()) { news in
                            NewsCard(
                                title: news.title,
                                description: news.description,
                                date: news.date,
                                type: news.type,
                                relatedSymbol: news.shouldShowRelatedSymbol ? news.relatedSymbol : nil
                            )
                        }
                    }
                    .listRowBackground(Color.black)
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("最新資訊")
                        .navigationTitleStyle()
                }
            }
        }
        .padding(.top, 10)
    }
    
    // 新聞類別選擇器
    private var newsCategorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                    }) {
                        Text(category.displayName)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color.clear)
    }
    
    // 獲取篩選後的新聞列表
    private func getFilteredNews() -> [NewsItem] {
        switch selectedCategory {
        case .all:
            return sampleNews
        case .myStocks:
            // 篩選出使用者持有的股票相關的新聞
            let userStockSymbols = stocks.map { $0.symbol }
            return sampleNews.filter { news in
                // 檢查新聞是否與用戶持有的任何股票相關
                return userStockSymbols.contains(news.relatedSymbol)
            }
        default:
            return sampleNews.filter { $0.category == selectedCategory }
        }
    }
}

// 定義新聞類別
enum NewsCategory: String, CaseIterable {
    case all = "全部"
    case myStocks = "關於我"  // 改名為更清晰的myStocks，但顯示名稱仍為"關於我"
    case dividend = "股利"
    case company = "公司動態"
    case financial = "財報"
    
    var displayName: String {
        return self.rawValue
    }
}

// 新增新聞項目結構
struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let date: String
    let type: String
    let category: NewsCategory
    let relatedSymbol: String // 新增關聯股票代號
    
    // 判斷是否顯示相關股票
    var shouldShowRelatedSymbol: Bool {
        return !relatedSymbol.isEmpty
    }
}

// 範例新聞數據
let sampleNews = [
    NewsItem(
        title: "台積電宣布發放季度股利",
        description: "台積電董事會通過每股配發2.75元股利",
        date: "2025/02/07",
        type: "股利發放",
        category: .dividend,
        relatedSymbol: "2330"
    ),
    NewsItem(
        title: "鴻海併購案獲准",
        description: "鴻海集團併購案已獲得主管機關核准",
        date: "2025/02/06",
        type: "公司新聞",
        category: .company,
        relatedSymbol: "2317"
    ),
    NewsItem(
        title: "聯發科營收創新高",
        description: "聯發科公布第四季營收，創下歷史新高",
        date: "2025/02/05",
        type: "財報公告",
        category: .financial,
        relatedSymbol: "2454"
    ),
    NewsItem(
        title: "股息計算器更新公告",
        description: "股息計算器App推出最新版本，新增多項實用功能",
        date: "2025/02/04",
        type: "App公告",
        category: .myStocks,
        relatedSymbol: ""  // 不特定關聯某股票
    ),
    NewsItem(
        title: "台灣50指數ETF宣布分配股利",
        description: "台灣50指數ETF宣布每單位配發1.8元股利",
        date: "2025/02/03",
        type: "股利發放",
        category: .dividend,
        relatedSymbol: "0050"
    ),
    NewsItem(
        title: "台塑化第一季財報出爐",
        description: "台塑化公布第一季財報，EPS達2.3元",
        date: "2025/02/02",
        type: "財報公告",
        category: .financial,
        relatedSymbol: "6505"
    ),
    NewsItem(
        title: "富邦金控股利政策調整",
        description: "富邦金控宣布調整股利政策，未來將提高現金股利比例",
        date: "2025/02/01",
        type: "公司公告",
        category: .dividend,
        relatedSymbol: "2881"
    ),
    NewsItem(
        title: "台積電供應鏈趨勢分析",
        description: "分析師報告：台積電供應鏈未來展望樂觀，相關企業將受益",
        date: "2025/01/30",
        type: "市場分析",
        category: .company,
        relatedSymbol: "2330"
    )
]

struct NewsCard: View {
    let title: String
    let description: String
    let date: String
    let type: String
    var relatedSymbol: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(type)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(4)
                
                if let symbol = relatedSymbol, !symbol.isEmpty {
                    Text(symbol)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.3))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text(date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .cardBackground()
    }
}

