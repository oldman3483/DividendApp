//
//  StockDetailView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/29.
//

import SwiftUI

// MARK: - 輔助視圖元件
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

// MARK: - 股票詳細信息視圖
struct StockDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    
    let stockInfo: WeightedStockInfo
    
    var body: some View {
        NavigationStack {
            List {
                // 彙總資訊區塊
                Section("彙總資訊") {
                    SummaryRow(title: "總持股數", value: "\(stockInfo.totalShares)股")
                    SummaryRow(
                        title: "平均股利",
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
                
                // 詳細持股區塊
                Section("詳細持股") {
                    ForEach(stockInfo.details) { stock in
                        StockDetailRow(stock: stock)
                    }
                }
            }
            EditButton(action: {
                showingEditSheet = true
            })
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
            
            .sheet(isPresented: $showingEditSheet) {
                Text("編輯持股")
            }
        }
    }

