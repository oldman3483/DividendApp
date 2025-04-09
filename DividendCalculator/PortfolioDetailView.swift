//
//  PortfolioDetailView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/29.
//


import SwiftUI

// MARK: - 彙總資訊結構體
struct SummaryInfo {
    var totalShares: Int = 0
    var totalInvestment: Double = 0
    var averageCost: Double = 0
    var annualDividend: Double = 0
    var dividendYield: Double = 0
    var totalRegularAmount: Double = 0
}



// MARK: - 主視圖
struct PortfolioDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    
    let symbol: String
    let bankId: UUID
    
    @State private var isEditing = false
    
    // MARK: - 計算屬性
    private var filteredStocks: [Stock] {
        stocks.filter { $0.symbol == symbol && $0.bankId == bankId }
    }
    
    private var regularInvestments: [Stock] {
        filteredStocks.filter { $0.regularInvestment != nil }
    }
    
    private var normalStocks: [Stock] {
        filteredStocks.filter { $0.regularInvestment == nil }
    }
    
    private var summaryInfo: SummaryInfo {
        var info = SummaryInfo()
        
        for stock in filteredStocks {
            info.totalShares += stock.totalShares
            
            if let avgCost = stock.calculateAverageCost() {
                info.totalInvestment += avgCost * Double(stock.totalShares)
            }
            
            info.annualDividend += stock.calculateAnnualDividend()
            
            if let regularInvestment = stock.regularInvestment {
                info.totalRegularAmount += regularInvestment.totalInvestmentAmount
            }
        }
        
        if info.totalShares > 0 {
            info.averageCost = info.totalInvestment / Double(info.totalShares)
            info.dividendYield = (info.annualDividend / info.totalInvestment) * 100
        }
        
        return info
    }
    
    // MARK: - 視圖
    var body: some View {
        NavigationStack {
            List {
                // 彙總資訊區塊
                Section("彙總資訊") {
                    VStack(spacing: 16) {
                        DetailRow(title: "總持股數", value: "\(summaryInfo.totalShares)股")
                        
                        DetailRow(
                            title: "總投資金額",
                            value: "$\(Int(summaryInfo.totalInvestment).formattedWithComma)"
                        )
                        
                        if summaryInfo.totalRegularAmount > 0 {
                            DetailRow(
                                title: "定期定額總額",
                                value: "$\(Int(summaryInfo.totalRegularAmount).formattedWithComma)"
                            )
                        }
                        
                        DetailRow(
                            title: "平均成本",
                            value: "$\(String(format: "%.2f", summaryInfo.averageCost))"
                        )
                        
                        DetailRow(
                            title: "預估年化股利",
                            value: "$\(Int(summaryInfo.annualDividend).formattedWithComma)",
                            valueColor: .green
                        )
                        
                        DetailRow(
                            title: "股利殖利率",
                            value: String(format: "%.2f%%", summaryInfo.dividendYield),
                            valueColor: .green
                        )
                    }
                    .padding(.vertical, 8)
                }
                
                // 定期定額區塊
                if !regularInvestments.isEmpty {
                    Section("定期定額投資") {
                        ForEach(regularInvestments) { stock in
                            RegularInvestmentCard(stock: stock)
                        }
                    }
                }
                
                // 一般持股區塊
                if !normalStocks.isEmpty {
                    Section("一般持股") {
                        ForEach(normalStocks) { stock in
                            NormalStockCard(stock: stock)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(symbol)
            .toolbar {
                
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !regularInvestments.isEmpty || !normalStocks.isEmpty {
                        Button(isEditing ? "完成" : "編輯") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 支援視圖元件
struct RegularInvestmentCard: View {
    let stock: Stock
    
    var body: some View {
        guard let regularInvestment = stock.regularInvestment else { return AnyView(EmptyView()) }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                // 定期定額基本資訊
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("每期金額：$\(Int(regularInvestment.amount).formattedWithComma)")
                        Text("頻率：\(regularInvestment.frequency.rawValue)")
                        Text("狀態：\(regularInvestment.isActive ? "進行中" : "已停止")")
                            .foregroundColor(regularInvestment.isActive ? .green : .gray)
                    }
                    .font(.system(size: 15))
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("開始：\(formatDate(regularInvestment.startDate))")
                        if let endDate = regularInvestment.endDate {
                            Text("結束：\(formatDate(endDate))")
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                }
                
                // 交易記錄
                if let transactions = regularInvestment.transactions, !transactions.isEmpty {
                    Text("交易記錄")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    ForEach(transactions.sorted { $0.date > $1.date }) { transaction in
                        TransactionRow(transaction: transaction)
                            .padding(.vertical, 4)
                    }
                }
                
                if let note = regularInvestment.note, !note.isEmpty {
                    Text("備註：\(note)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        )
    }
}

struct NormalStockCard: View {
    let stock: Stock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("買入日期：\(formatDate(stock.purchaseDate))")
                    .font(.subheadline)
                Spacer()
                if let price = stock.purchasePrice {
                    Text("$\(String(format: "%.2f", price))")
                        .font(.system(size: 15))
                }
            }
            
            HStack {
                Text("\(stock.shares)股")
                    .font(.system(size: 16, weight: .medium))
                Spacer()
                Text("股利：$\(String(format: "%.2f", stock.dividendPerShare))")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }
}
