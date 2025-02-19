//
//  StockSummaryRow.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/7.
//

import SwiftUI

struct StockSummaryRow: View {
    let stockInfo: WeightedStockInfo
    let isEditing: Bool
    
    private var regularInvestmentCount: Int {
        stockInfo.details.filter { $0.regularInvestment != nil }.count
    }
    
    private var totalRegularAmount: Double {
        stockInfo.details
            .compactMap { $0.regularInvestment }
            .reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        HStack(spacing: 12) {
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
                
                // 第二行：定期定額信息或股利信息
                if hasRegularInvestment {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(regularInvestmentCount) 個定期定額計畫")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            Spacer()
                            Text("每期總金額：$\(Int(totalRegularAmount).formattedWithComma)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    // 一般持股的股利信息顯示
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
            }
                        
            if !isEditing {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(.vertical, 4)
    }
    
    private var hasRegularInvestment: Bool {
        stockInfo.details.contains { $0.regularInvestment != nil }
    }
}
