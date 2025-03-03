//
//  BankListSummaryView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/12.
//

import SwiftUI

struct BankListSummaryView: View {
    // 改為接受直接參數而非計算
    let totalValue: Double
    let totalProfitLoss: Double
    let totalROI: Double
    let dailyChange: Double
    let dailyChangePercentage: Double
    let annualDividend: Double
    let dividendYield: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // 主要數據卡片
            HStack(spacing: 12) {
                // 總市值
                MainMetricCard(
                    title: "總市值",
                    value: formatCurrency(totalValue),
                    change: formatPercentage(dailyChangePercentage),
                    isPositive: dailyChangePercentage >= 0
                )
                
                // 總投資報酬
                MainMetricCard(
                    title: "總投資報酬",
                    value: formatCurrency(totalProfitLoss),
                    change: formatPercentage(totalROI),
                    isPositive: totalProfitLoss >= 0
                )
            }
            
            // 次要數據卡片
            HStack(spacing: 12) {
                // 當日損益
                SecondaryMetricCard(
                    title: "當日損益",
                    mainValue: formatCurrency(abs(dailyChange)),
                    subValue: formatPercentage(dailyChangePercentage),
                    isPositive: dailyChange >= 0
                )
                
                // 年化股利率
                SecondaryMetricCard(
                    title: "年化股利率",
                    mainValue: formatPercentage(dividendYield),
                    subValue: "年化 \(formatCurrency(annualDividend))",
                    showTrend: false
                )
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        return "$\(Int(value).formattedWithComma)"
    }
    
    private func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", abs(value))
    }
}

// 主要指標卡片
struct MainMetricCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 2) {
                Image(systemName: isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 8))
                Text(change)
                    .font(.caption)
            }
            .foregroundColor(isPositive ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}

// 次要指標卡片
struct SecondaryMetricCard: View {
    let title: String
    let mainValue: String
    let subValue: String
    var isPositive: Bool = true
    var showTrend: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(mainValue)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(showTrend ? (isPositive ? .green : .red) : .white)
            
            HStack(spacing: 2) {
                if showTrend {
                    Image(systemName: isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 8))
                }
                Text(subValue)
                    .font(.caption2)
            }
            .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}
