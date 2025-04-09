//
//  HoldingDetailViews.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/19.
//

import SwiftUI

// MARK: - 一般持股詳細頁面
struct NormalStockDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    let symbol: String
    let bankId: UUID
    
    private var normalStocks: [Stock] {
        stocks.filter { $0.symbol == symbol && $0.bankId == bankId && $0.regularInvestment == nil }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本資訊卡片
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        // 股票基本資訊
                        HStack {
                            Text(symbol)
                                .font(.title2)
                                .bold()
                            Text(normalStocks.first?.name ?? "")
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 5)
                        
                        // 彙總持股資訊
                        let totalShares = normalStocks.reduce(0) { $0 + $1.shares }
                        DetailRow(title: "總持股數量", value: "\(totalShares) 股")
                        
                        if let avgCost = calculateAverageCost() {
                            DetailRow(title: "平均成本", value: String(format: "$ %.2f", avgCost))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 股利資訊卡片
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("股利資訊")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        let stock = normalStocks.first
                        DetailRow(
                            title: "每股股利",
                            value: String(format: "$ %.2f", stock?.dividendPerShare ?? 0)
                        )
                        DetailRow(
                            title: "發放頻率",
                            value: getFrequencyText(stock?.frequency ?? 1)
                        )
                        DetailRow(
                            title: "年化股利",
                            value: String(format: "$ %.0f", calculateTotalAnnualDividend()),
                            valueColor: .green
                        )
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 績效分析卡片
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("績效分析")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        let totalInvestment = normalStocks.reduce(0.0) {
                            $0 + (Double($1.shares) * ($1.purchasePrice ?? 0))
                        }
                        
                        DetailRow(
                            title: "總投資成本",
                            value: String(format: "$ %.0f", totalInvestment)
                        )
                        
                        DetailRow(
                            title: "殖利率",
                            value: String(format: "%.2f%%", calculateDividendYield()),
                            valueColor: .green
                        )
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                
                // 購買明細區塊
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("購買明細")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ForEach(normalStocks.sorted(by: { $0.purchaseDate > $1.purchaseDate }), id: \.id) { stock in
                            purchaseDetailRow(for: stock)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                
            }
            .padding()
        }
        .navigationTitle("一般持股詳細資訊")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }
    
    private func purchaseDetailRow(for stock: Stock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("購買日期：\(formatDate(stock.purchaseDate))")
                        .font(.subheadline)
                    Text("股數：\(stock.shares)股")
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let price = stock.purchasePrice {
                        Text("股價：$\(String(format: "%.2f", price))")
                            .font(.subheadline)
                        Text("總成本：$\(String(format: "%.0f", Double(stock.shares) * price))")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.vertical, 8)
            
            Divider()
                .background(Color.gray.opacity(0.3))
        }
    }
    
    private func calculateAverageCost() -> Double? {
        let totalInvestment = normalStocks.reduce(0.0) {
            $0 + (Double($1.shares) * ($1.purchasePrice ?? 0))
        }
        let totalShares = normalStocks.reduce(0) { $0 + $1.shares }
        
        return totalShares > 0 ? totalInvestment / Double(totalShares) : nil
    }
    
    private func calculateTotalAnnualDividend() -> Double {
        return normalStocks.reduce(0) {
            $0 + (Double($1.shares) * $1.dividendPerShare * Double($1.frequency))
        }
    }
    
    private func calculateDividendYield() -> Double {
        let totalInvestment = normalStocks.reduce(0.0) {
            $0 + (Double($1.shares) * ($1.purchasePrice ?? 0))
        }
        let totalAnnualDividend = calculateTotalAnnualDividend()
        
        return totalInvestment > 0 ? (totalAnnualDividend / totalInvestment) * 100 : 0
    }
}

// MARK: - 定期定額詳細頁面
struct RegularInvestmentDetailView: View {
    @Binding var stocks: [Stock]
    let symbol: String
    let bankId: UUID
    let planId: UUID
    
    private var stock: Stock? {
        stocks.first { $0.id == planId }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本資訊卡片
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        // 定期定額設定
                        DetailRow(
                            title: "投資金額",
                            value: String(format: "$ %.0f", stock?.regularInvestment?.amount ?? 0)
                        )
                        DetailRow(
                            title: "投資頻率",
                            value: stock?.regularInvestment?.frequency.rawValue ?? ""
                        )
                        DetailRow(
                            title: "開始日期",
                            value: formatDate(stock?.regularInvestment?.startDate)
                        )
                        if let endDate = stock?.regularInvestment?.endDate {
                            DetailRow(title: "結束日期", value: formatDate(endDate))
                        }
                        DetailRow(
                            title: "執行狀態",
                            value: stock?.regularInvestment?.executionStatus.description ?? "未啟用",
                            valueColor: stock?.regularInvestment?.executionStatus.color ?? .gray
                        )
                        if let note = stock?.regularInvestment?.note, !note.isEmpty {
                            DetailRow(title: "備註", value: note)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 投資成效卡片
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("投資成效")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        // 已執行投資金額
                        let executedAmount = (stock?.regularInvestment?.transactions ?? [])
                            .filter { $0.isExecuted }
                            .reduce(0) { $0 + $1.amount }
                        DetailRow(
                            title: "已執行投資",
                            value: String(format: "$ %.0f", executedAmount)
                        )
                        
                        // 預計投資金額（未執行的交易）
                        let pendingAmount = (stock?.regularInvestment?.transactions ?? [])
                            .filter { !$0.isExecuted }
                            .reduce(0) { $0 + $1.amount }
                        if pendingAmount > 0 {
                            DetailRow(
                                title: "預計投資",
                                value: String(format: "$ %.0f", pendingAmount),
                                valueColor: .gray
                            )
                        }
                        
                        DetailRow(
                            title: "累計股數",
                            value: "\(stock?.regularInvestment?.totalShares ?? 0) 股"
                        )
                        
                        if let avgCost = stock?.regularInvestment?.averageCost {
                            DetailRow(
                                title: "平均成本",
                                value: String(format: "$ %.2f", avgCost)
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 交易記錄列表
                if let transactions = stock?.regularInvestment?.transactions?.sorted(by: { $0.date > $1.date }) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("交易記錄")
                                    .font(.headline)
                                Spacer()
                                Text("\(transactions.count) 筆")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 4)
                            
                            // 執行狀態統計
                            HStack(spacing: 20) {
                                let executedCount = transactions.filter { $0.isExecuted }.count
                                let pendingCount = transactions.filter { !$0.isExecuted }.count
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("已執行")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(executedCount)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("待執行")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(pendingCount)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.vertical, 8)
                            
                            // 交易記錄列表
                            ForEach(transactions) { transaction in
                                VStack(spacing: 12) {
                                    HStack {
                                        Text(formatDate(transaction.date))
                                            .font(.system(size: 15))
                                        Spacer()
                                        Text(transaction.isExecuted ? "已執行" : "待執行")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(transaction.isExecuted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                            )
                                    }
                                    
                                    HStack(spacing: 20) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("投資金額")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("$\(Int(transaction.amount).formattedWithComma)")
                                                .font(.system(size: 15, weight: .medium))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("成交價")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("$\(String(format: "%.2f", transaction.price))")
                                                .font(.system(size: 15, weight: .medium))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("股數")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("\(transaction.shares)")
                                                .font(.system(size: 15, weight: .medium))
                                        }
                                    }
                                    
                                    if transaction != transactions.last {
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                            .padding(.top, 8)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .groupBoxStyle(TransparentGroupBox())
                }
            }
            .padding()
        }
        .navigationTitle("定期定額詳細資訊")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Stock 擴展
extension Stock {
    func calculateDividendYield() -> Double? {
        guard let purchasePrice = purchasePrice, purchasePrice > 0 else { return nil }
        return (dividendPerShare * Double(frequency) / purchasePrice) * 100
    }
}
