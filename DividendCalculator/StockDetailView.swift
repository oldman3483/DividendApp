//
//  StockDetailView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/29.
//

import SwiftUI

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

struct StockDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    
    let stockInfo: WeightedStockInfo
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var selectedStock: Stock?
    @State private var editingShares: String = ""
    @State private var showingSharesAlert = false
    
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
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("買入日期：\(formatDate(stock.purchaseDate))")
                                    .font(.subheadline)
                                
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
                            
                            if isEditing {
                                Menu {
                                    Button(action: {
                                        selectedStock = stock
                                        editingShares = "\(stock.shares)"
                                        showingSharesAlert = true
                                    }) {
                                        Label("修改持股", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        selectedStock = stock
                                        showingDeleteAlert = true
                                    }) {
                                        Label("刪除", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("\(stockInfo.symbol) \(stockInfo.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "完成" : "編輯") {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }
                }
            }
            .alert("刪除持股", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("刪除", role: .destructive) {
                    if let stockToDelete = selectedStock {
                        deleteStock(stockToDelete)
                    }
                }
            } message: {
                Text("確定要刪除這筆持股紀錄嗎？")
            }
            .alert("修改持股數量", isPresented: $showingSharesAlert) {
                TextField("持股數量", text: $editingShares)
                    .keyboardType(.numberPad)
                Button("取消", role: .cancel) {}
                Button("確定") {
                    updateShares()
                }
            } message: {
                Text("請輸入新的持股數量")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
    
    private func deleteStock(_ stock: Stock) {
        stocks.removeAll { $0.id == stock.id }
        if stocks.filter({ $0.symbol == stockInfo.symbol }).isEmpty {
            dismiss()
        }
    }
    
    private func updateShares() {
        guard let stock = selectedStock,
              let newShares = Int(editingShares),
              newShares > 0 else {
            return
        }
        
        if let index = stocks.firstIndex(where: { $0.id == stock.id }) {
            stocks[index].shares = newShares
        }
    }
}
