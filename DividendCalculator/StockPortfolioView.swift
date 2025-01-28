//
//  StockPortfolioView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/24.
//

import SwiftUI

struct StockPortfolioView: View {
    @Binding var stocks: [Stock]
    @Binding var isEditing: Bool
    @State private var selectedStock: WeightedStockInfo?
    @State private var showingDetail = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }()
    
    // 計算合併後的股票資訊
    private var groupedStocks: [WeightedStockInfo] {
        stocks.calculateWeightedAverage()
    }
    
    // 計算總年化股利
    private var totalAnnualDividend: Double {
        groupedStocks.reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
    }
    
    var body: some View {
        List {
            // 總覽區塊
            Section {
                HStack {
                    Text("總持股數")
                    Spacer()
                    Text("\(groupedStocks.count) 檔")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("預估年化股利")
                    Spacer()
                    Text("$\(String(format: "%.0f", totalAnnualDividend))")
                        .foregroundColor(.green)
                }
            }
            
            // 股票列表區塊
            Section {
                ForEach(groupedStocks) { stockInfo in
                    Button(action: {
                        selectedStock = stockInfo
                        showingDetail = true
                    }) {
                        StockSummaryRow(stockInfo: stockInfo)
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("庫存股")
                    .font(.system(size: 40, weight: .bold))
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let stockInfo = selectedStock {
                StockDetailView(stockInfo: stockInfo)
            }
        }
    }
}

// 股票摘要行
struct StockSummaryRow: View {
    let stockInfo: WeightedStockInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 第一行：股票代號和名稱
            HStack {
                Text(stockInfo.symbol)
                    .font(.headline)
                Text(stockInfo.name)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(stockInfo.totalShares)股")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // 第二行：股利資訊
            HStack {
                VStack(alignment: .leading) {
                    Text("加權股利")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(String(format: "%.2f", stockInfo.weightedDividendPerShare))")
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("年化股利")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(String(format: "%.0f", stockInfo.calculateTotalAnnualDividend()))")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// 股票詳細資訊視圖
struct StockDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let stockInfo: WeightedStockInfo
    
    var body: some View {
        NavigationStack {
            List {
                // 彙總資訊區塊
                Section("彙總資訊") {
                    SummaryRow(title: "總持股數", value: "\(stockInfo.totalShares)股")
                    SummaryRow(
                        title: "加權平均股利",
                        value: "$\(String(format: "%.2f", stockInfo.weightedDividendPerShare))"
                    )
                    if let avgPrice = stockInfo.weightedPurchasePrice {
                        SummaryRow(
                            title: "加權平均成本",
                            value: "$\(String(format: "%.2f", avgPrice))"
                        )
                    }
                    SummaryRow(
                        title: "預估年化股利",
                        value: "$\(String(format: "%.0f", stockInfo.calculateTotalAnnualDividend()))",
                        valueColor: .green
                    )
                    if let totalValue = stockInfo.calculateTotalValue() {
                        SummaryRow(
                            title: "總市值",
                            value: "$\(String(format: "%.0f", totalValue))"
                        )
                    }
                }
                
                // 詳細持股資訊區塊
                Section("詳細持股") {
                    ForEach(stockInfo.details) { stock in
                        StockDetailRow(stock: stock)
                    }
                }
            }
            .navigationTitle("\(stockInfo.symbol) \(stockInfo.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 彙總資訊行元件
struct SummaryRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
        }
    }
}

// 詳細持股資訊行元件
struct StockDetailRow: View {
    let stock: Stock
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("買入日期：\(dateFormatter.string(from: stock.purchaseDate))")
            
            HStack {
                Text("持股數量：\(stock.shares)股")
                Spacer()
                if let price = stock.purchasePrice {
                    Text("價格：$\(String(format: "%.2f", price))")
                }
            }
            
            HStack {
                Text("配息：$\(String(format: "%.2f", stock.dividendPerShare))")
                Spacer()
                Text("年化：$\(String(format: "%.0f", stock.calculateAnnualDividend()))")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
