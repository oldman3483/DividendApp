//
//  WatchStockCard.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/11.
//
import SwiftUI
import Charts

struct WatchStockCard: View {
    let stock: WatchStock
    let stockService = LocalStockService()
    
    @State private var stockPrice: Double = 0.0
    @State private var previousPrice: Double = 0.0
    @State private var priceHistory: [(Date, Double)] = []
    @State private var isLoading = true
    @Environment(\.editMode) private var editMode
    
    private var priceChange: Double {
        stockPrice - previousPrice
    }
    
    private var changePercentage: Double {
        guard previousPrice != 0 else { return 0 }
        return (priceChange / previousPrice) * 100
    }
    
    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }
    
    var body: some View {
        NavigationLink {
            StockDetailPage(symbol: stock.symbol, name: stock.name)
        } label: {
            contentView
        }
        .disabled(isEditing)
        .task {
            await loadStockData()
        }
    }
    
    private var contentView: some View {
        HStack(spacing: 16) {
            if isEditing {
                Color.clear
                    .frame(width: 8)
            }
            
            // 左側：股票名稱和代號
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                
                Text(stock.symbol)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .frame(width: 70, alignment: .leading)
            
            if !isLoading && !isEditing {
                // 中間：走勢圖
                Chart {
                    ForEach(priceHistory, id: \.0) { item in
                        LineMark(
                            x: .value("Time", item.0),
                            y: .value("Price", item.1)
                        )
                        .foregroundStyle(priceChange >= 0 ? Color.red : Color.green)
                    }
                }
                .frame(width: 70, height: 25)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
            }
            
            Spacer()
            
            // 右側：價格區域
            if !isLoading {
                HStack(alignment: .center, spacing: 8) {
                    Text(String(format: "%.2f", stockPrice))
                        .heading3Style()
                        .frame(width: 70, alignment: .trailing)
                        .foregroundStyle(priceChange >= 0 ? Color.red : Color.green)
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text(String(format: "%+.2f", priceChange))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(priceChange >= 0 ? Color.red : Color.green)
                            )
                            .frame(minWidth: 70)
                        
                        Text(String(format: "%+.2f%%", changePercentage))
                            .font(.system(size: 12))
                            .foregroundStyle(priceChange >= 0 ? Color.red : Color.green)
                        
                    }
                }
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .frame(height: 40)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func loadStockData() async {
        isLoading = true
        
        // 載入當前價格
        if let currentPrice = await stockService.getStockPrice(symbol: stock.symbol, date: Date()) {
            await MainActor.run {
                stockPrice = currentPrice
            }
        }
        
        // 載入昨日價格
        let calendar = Calendar.current
        if let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: Date()),
           let yesterdayPrice = await stockService.getStockPrice(symbol: stock.symbol, date: yesterdayDate) {
            await MainActor.run {
                previousPrice = yesterdayPrice
            }
        }
        
        // 生成價格歷史
        var history: [(Date, Double)] = []
        let startOfDay = calendar.startOfDay(for: Date())
        
        // 生成交易時段的價格歷史（9:00-13:30）
        for hour in 9...13 {
            for minute in stride(from: 0, through: 30, by: 30) {
                guard let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startOfDay),
                      date <= Date() else { continue }
                
                if let price = await stockService.getStockPrice(symbol: stock.symbol, date: date) {
                    history.append((date, price))
                }
            }
        }
        
        await MainActor.run {
            priceHistory = history.sorted { $0.0 < $1.0 }
            isLoading = false
        }
    }
}
