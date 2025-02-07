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
                
                // 第二行：股利信息
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
                        
            if !isEditing {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(.vertical, 4)
    }
}
