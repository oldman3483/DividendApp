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
        HStack(spacing: 16) {
            if isEditing {
                // 編輯模式時的左側空間
                Color.clear
                    .frame(width: 8)
            }
            
            // 主要內容
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    // 左側：股票信息
                    VStack(alignment: .leading, spacing: 8) {
                        // 股票代號和名稱
                        HStack(spacing: 6) {
                            Text(stock.symbol)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(stock.name)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // 價格和變動
                        if !isLoading {
                            HStack(spacing: 4) {
                                Text("$\(String(format: "%.2f", stockPrice))")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 65, alignment: .leading)
                                
                                HStack(spacing: 2) {
                                    Image(systemName: priceChange >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                                        .font(.system(size: 10))
                                    Text("\(String(format: "%.2f", abs(priceChange)))")
                                    Text("(\(String(format: "%.1f", abs(changePercentage)))%)")
                                }
                                .font(.system(size: 14))
                                .foregroundColor(priceChange >= 0 ? .green : .red)
                            }
                        } else {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .layoutPriority(1)
                    
                    Spacer()
                    
                    // 右側：走勢圖
                    if !isLoading && !isEditing {
                        Chart {
                            ForEach(priceHistory, id: \.0) { item in
                                LineMark(
                                    x: .value("Time", item.0),
                                    y: .value("Price", item.1)
                                )
                                .foregroundStyle(priceChange >= 0 ? Color.green : Color.red)
                            }
                        }
                        .frame(width: 100, height: 40)
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                    }
                }
            }
            .padding(.horizontal, isEditing ? 8 : 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.3))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .task {
            await loadStockData()
        }
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
