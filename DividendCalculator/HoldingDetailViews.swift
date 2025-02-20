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
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    let symbol: String
    let bankId: UUID
    
    private var stock: Stock? {
        stocks.first { $0.symbol == symbol && $0.bankId == bankId && $0.regularInvestment != nil }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本資訊卡片
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        // 股票基本資訊
                        HStack {
                            Text(symbol)
                                .font(.title2)
                                .bold()
                            Text(stock?.name ?? "")
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 8)
                        
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
                        
                        DetailRow(
                            title: "總投資金額",
                            value: String(format: "$ %.0f", stock?.regularInvestment?.totalInvestmentAmount ?? 0)
                        )
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
                        DetailRow(
                            title: "年化股利",
                            value: String(format: "$ %.0f", stock?.calculateAnnualDividend() ?? 0),
                            valueColor: .green
                        )
                    }
                    .padding(.vertical, 8)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 交易記錄列表
                if let transactions = stock?.regularInvestment?.transactions?.sorted(by: { $0.date > $1.date }) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("交易記錄")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            ForEach(transactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .padding(.vertical, 4)
                                if transaction != transactions.last {
                                    Divider()
                                        .background(Color.gray.opacity(0.3))
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

// MARK: - 輔助方法
func getFrequencyText(_ frequency: Int) -> String {
    switch frequency {
    case 1: return "年配"
    case 2: return "半年配"
    case 4: return "季配"
    case 12: return "月配"
    default: return "未知"
    }
}

// MARK: - Stock 擴展
extension Stock {
    func calculateDividendYield() -> Double? {
        guard let purchasePrice = purchasePrice, purchasePrice > 0 else { return nil }
        return (dividendPerShare * Double(frequency) / purchasePrice) * 100
    }
}
