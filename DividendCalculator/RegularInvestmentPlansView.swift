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
                        
                        // 彙總資訊
                        let totalAmount = regularInvestmentStocks.reduce(0.0) {
                            $0 + ($1.regularInvestment?.amount ?? 0)
                        }
                        DetailRow(
                            title: "每期總投資",
                            value: String(format: "$ %.0f", totalAmount)
                        )
                        
                        let totalInvestment = regularInvestmentStocks.reduce(0.0) {
                            $0 + ($1.regularInvestment?.totalInvestmentAmount ?? 0)
                        }
                        DetailRow(
                            title: "累計投資金額",
                            value: String(format: "$ %.0f", totalInvestment)
                        )
                        
                        let totalShares = regularInvestmentStocks.reduce(0) {
                            $0 + ($1.regularInvestment?.totalShares ?? 0)
                        }
                        DetailRow(
                            title: "總持股數",
                            value: "\(totalShares) 股"
                        )
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

// RegularInvestmentPlanCard 不再需要 overlay 參數
struct RegularInvestmentPlanCard: View {
    let stock: Stock
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
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
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
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
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("累計投資")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("$\(Int(stock.regularInvestment?.totalInvestmentAmount ?? 0).formattedWithComma)")
                            .font(.system(size: 15))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("持有股數")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(stock.regularInvestment?.totalShares ?? 0) 股")
                            .font(.system(size: 15))
                    }
                }
                
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
    }
}
