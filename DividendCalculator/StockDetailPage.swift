//
//  StockDetailPage.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/12.
//

//  StockDetailPage.swift
//  DividendCalculator

import SwiftUI
import Charts

struct StockDetailPage: View {
    let symbol: String
    let name: String
    @State private var selectedTab: StockDetailTab = .market
    @State private var selectedTimeRange: String = "當日"
    @State private var stockPrice: Double = 0.0
    @State private var priceChange: Double = 0.0
    @State private var percentageChange: Double = 0.0
    @State private var previousPrice: Double = 0.0
    @State private var volume: Int = 0
    @State private var isLoading = true
    @State private var priceHistory: [(Date, Double)] = []
    @State private var klineData: [KLineData] = []
    @State private var showingAddStockView = false
    @State private var isInWatchlist = false
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]
    @Binding var banks: [Bank]
    
    let bankId: UUID?
    
    private let stockService = LocalStockService()
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    // 標題區域
                    headerSection
                    
                    // 市場資訊卡片
                    MarketInfoCard(
                        price: stockPrice,
                        change: priceChange,
                        changePercentage: percentageChange,
                        high: previousPrice * 1.1,
                        low: previousPrice * 0.9,
                        volume: volume
                    )
                    .padding(.horizontal)
                
                    
                    // 標籤列
                    StockTabBar(selectedTab: $selectedTab)
                    
                    // 時間範圍選擇器
                    TimeRangeSelector(
                        timeRanges: selectedTab.timeRanges,
                        selectedRange: $selectedTimeRange
                    )
                    
                    // 內容區域
                    Group {
                        switch selectedTab {
                        case .market:
                            marketContent
                        case .kline:
                            klineContent
//                        case .analysis:
//                            analysisContent
                        case .news:
                            newsContent
                        case .chip:
                            chipContent
                        case .basic:
                            basicContent
                        case .financial:
                            financialContent
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddStockView = true
                }) {
                    Image(systemName: isInWatchlist ? "star.fill" : "star")
                        .foregroundColor(isInWatchlist ? .yellow : .gray)
                }
            }
        }
        .sheet(isPresented: $showingAddStockView) {
            AddStockView(
                stocks: $stocks,
                watchlist: $watchlist,
                banks: $banks,
                initialSymbol: symbol,
                initialName: name,
                bankId: UUID(),
                isFromBankPortfolio: false
            )
        }
        .task {
            await loadStockData()
            checkWatchlistStatus()
        }
    }
    
    private func checkWatchlistStatus() {
        isInWatchlist = watchlist.contains{ $0.symbol == symbol }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(symbol)
                    .font(.system(size: 24, weight: .bold))
                Text(name)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    private var marketContent: some View {
        VStack(spacing: 12) {
           // 走勢圖
            chartSection
        }
    }
    
    private var chartSection: some View {
        VStack {
            if !priceHistory.isEmpty {
                Chart {
                    ForEach(priceHistory, id: \.0) { item in
                        LineMark(
                            x: .value("Time", item.0),
                            y: .value("Price", item.1)
                        )
                        .foregroundStyle(priceChange >= 0 ? Color.red : Color.green)
                    }
                }
                .frame(height: 250)
                .padding(8)
            } else {
                ProgressView()
                    .frame(height: 250)
            }
        }
        .background(Color(white: 0.1))
        .cornerRadius(10)
    }
    
    private var klineContent: some View {
        VStack(spacing: 12) {
            if let latestData = klineData.last {
                KLineInfoCard(data: latestData)
            }
            
            KLineChartView(
                data: klineData,
                maxPrice: klineData.map { $0.high }.max() ?? 0,
                minPrice: klineData.map { $0.low }.min() ?? 0
            )
        }
    }
    
    private var analysisContent: some View {
        Text("技術分析開發中...")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var newsContent: some View {
        Text("新聞內容開發中...")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var chipContent: some View {
        Text("籌碼資訊開發中...")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var basicContent: some View {
        Text("基本資料開發中...")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    private var financialContent: some View {
        Text("財務資訊開發中...")
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Data Loading
    
    // 在 loadStockData 方法中添加 K 線數據加載
    private func loadKLineData() async {
        let calendar = Calendar.current
        var tempData: [KLineData] = []
        
        // 模擬生成 30 天的 K 線數據
        for day in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            
            if let basePrice = await stockService.getStockPrice(symbol: symbol, date: date) {
                let variation = Double.random(in: -5...5)
                let data = KLineData(
                    date: date,
                    open: basePrice * (1 + Double.random(in: -0.02...0.02)),
                    high: basePrice * (1 + Double.random(in: 0.01...0.03)),
                    low: basePrice * (1 + Double.random(in: -0.03...(-0.01))),
                    close: basePrice * (1 + variation / 100),
                    volume: Int.random(in: 1000000...5000000)
                )
                tempData.append(data)
            }
        }
        
        await MainActor.run {
            klineData = tempData.reversed()
        }
    }
    
    
    
    private func loadStockData() async {
        isLoading = true
        var history: [(Date, Double)] = []
        
        if let currentPrice = await stockService.getStockPrice(symbol: symbol, date: Date()) {
            stockPrice = currentPrice
            
            let calendar = Calendar.current
            if let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: Date()),
               let yesterdayPrice = await stockService.getStockPrice(symbol: symbol, date: yesterdayDate) {
                
                previousPrice = yesterdayPrice
                priceChange = currentPrice - previousPrice
                percentageChange = (priceChange / previousPrice) * 100
                volume = Int.random(in: 10000...50000)
                
                let startOfDay = calendar.startOfDay(for: Date())
                for hour in 9...13 {
                    for minute in stride(from: 0, through: 30, by: 30) {
                        guard let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay),
                              date <= Date() else { continue }
                        
                        if let price = await stockService.getStockPrice(symbol: symbol, date: date) {
                            history.append((date, price))
                        }
                    }
                }
            }
        }
        
        await MainActor.run {
            priceHistory = history.sorted { $0.0 < $1.0 }
            isLoading = false
        }
    }
}
