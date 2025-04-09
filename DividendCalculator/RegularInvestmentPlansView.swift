//
//  RegularInvestmentPlansView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/20.
//


import SwiftUI

struct RegularInvestmentPlansView: View {
    @Binding var stocks: [Stock]
    let symbol: String
    let bankId: UUID
    
    private var regularInvestmentStocks: [Stock] {
        stocks.filter {
            $0.symbol == symbol &&
            $0.bankId == bankId &&
            $0.regularInvestment != nil
        }
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
                            Text(regularInvestmentStocks.first?.name ?? "")
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 8)
                        
                        // 每期投資資訊
                        let totalAmount = regularInvestmentStocks.reduce(0.0) {
                            $0 + ($1.regularInvestment?.amount ?? 0)
                        }
                        DetailRow(
                            title: "每期總投資",
                            value: String(format: "$ %.0f", totalAmount)
                        )
                        
                        // 執行狀態分組
                        Group {
                            // 已執行投資金額
                            let executedAmount = regularInvestmentStocks.reduce(0.0) { sum, stock in
                                sum + (stock.regularInvestment?.transactions?.filter { $0.isExecuted }.reduce(0.0) { $0 + $1.amount } ?? 0)
                            }
                            DetailRow(
                                title: "已執行投資",
                                value: String(format: "$ %.0f", executedAmount),
                                valueColor: .green
                            )
                            
                            // 待執行投資金額
                            let pendingAmount = regularInvestmentStocks.reduce(0.0) { sum, stock in
                                sum + (stock.regularInvestment?.transactions?.filter { !$0.isExecuted }.reduce(0.0) { $0 + $1.amount } ?? 0)
                            }
                            if pendingAmount > 0 {
                                DetailRow(
                                    title: "待執行投資",
                                    value: String(format: "$ %.0f", pendingAmount),
                                    valueColor: .gray
                                )
                            }
                            
                            // 執行狀態分隔線
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.vertical, 4)
                            
                            // 已執行股數
                            let executedShares = regularInvestmentStocks.reduce(0) { sum, stock in
                                sum + (stock.regularInvestment?.transactions?.filter { $0.isExecuted }.reduce(0) { $0 + $1.shares } ?? 0)
                            }
                            DetailRow(
                                title: "已執行股數",
                                value: "\(executedShares) 股",
                                valueColor: .green
                            )
                            
                            // 待執行股數
                            let pendingShares = regularInvestmentStocks.reduce(0) { sum, stock in
                                sum + (stock.regularInvestment?.transactions?.filter { !$0.isExecuted }.reduce(0) { $0 + $1.shares } ?? 0)
                            }
                            if pendingShares > 0 {
                                DetailRow(
                                    title: "待執行股數",
                                    value: "\(pendingShares) 股",
                                    valueColor: .gray
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 定期定額計劃列表
                ForEach(regularInvestmentStocks) { stock in
                    NavigationLink(
                        destination: RegularInvestmentDetailView(
                            stocks: $stocks,
                            symbol: symbol,
                            bankId: bankId,
                            planId: stock.id
                        )
                    ) {
                        RegularInvestmentPlanCard(stock: stock)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("定期定額計畫")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }
}


struct RegularInvestmentPlanCard: View {
    let stock: Stock
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // 標題
                Text(stock.regularInvestment?.title ?? "")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                // 第一行：金額和頻率
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("每期金額")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("$\(Int(stock.regularInvestment?.amount ?? 0).formattedWithComma)")
                            .font(.system(size: 17, weight: .medium))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("投資頻率")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(stock.regularInvestment?.frequency.rawValue ?? "")
                            .font(.system(size: 15))
                    }
                    
                    // 箭頭指示器
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                        .padding(.leading, 12)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // 第二行：日期和狀態
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("開始日期")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(formatDate(stock.regularInvestment?.startDate))
                            .font(.system(size: 14))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("狀態")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(stock.regularInvestment?.executionStatus.description ?? "未啟用")
                            .font(.system(size: 14))
                            .foregroundColor(stock.regularInvestment?.executionStatus.color ?? .gray)
                    }
                }
                
                // 第三行：已執行投資和股數
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("已執行投資")
                            .font(.caption)
                            .foregroundColor(.gray)
                        let executedAmount = stock.regularInvestment?.transactions?
                            .filter { $0.isExecuted }
                            .reduce(0.0) { $0 + $1.amount } ?? 0
                        Text("$\(Int(executedAmount).formattedWithComma)")
                            .font(.system(size: 15))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("已執行股數")
                            .font(.caption)
                            .foregroundColor(.gray)
                        let executedShares = stock.regularInvestment?.transactions?
                            .filter { $0.isExecuted }
                            .reduce(0) { $0 + $1.shares } ?? 0
                        Text("\(executedShares) 股")
                            .font(.system(size: 15))
                            .foregroundColor(.green)
                    }
                }
                
                // 第四行：待執行投資和股數（如果有的話）
                let pendingAmount = stock.regularInvestment?.transactions?
                    .filter { !$0.isExecuted }
                    .reduce(0.0) { $0 + $1.amount } ?? 0
                let pendingShares = stock.regularInvestment?.transactions?
                    .filter { !$0.isExecuted }
                    .reduce(0) { $0 + $1.shares } ?? 0
                
                if pendingAmount > 0 || pendingShares > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("待執行投資")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("$\(Int(pendingAmount).formattedWithComma)")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("待執行股數")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(pendingShares) 股")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // 備註（如果有的話）
                if let note = stock.regularInvestment?.note,
                   !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
        }
        .groupBoxStyle(TransparentGroupBox())
        .foregroundColor(.white)
        .cardBackground()
        // 點擊時的反饋效果
        .contentShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
        // hover 效果
        .hoverEffect(.highlight)
    }
}
