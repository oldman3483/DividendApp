//
//  AllocationTabView.swift
//  DividendCalculator
//
//  Created on 2025/3/9.
//

import SwiftUI
import Charts

struct AllocationTabView: View {
    @Binding var metrics: InvestmentMetrics
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 產業分配圓餅圖
            GroupBox {
                VStack(spacing: 15) {
                    Text("資產分配")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if metrics.assetAllocation.isEmpty {
                        ProgressView()
                            .frame(height: 200)
                    } else {
                        pieChart
                            .frame(height: 250)
                        
                        // 圖例
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(metrics.assetAllocation) { item in
                                    HStack(spacing: 8) {
                                        Rectangle()
                                            .fill(item.color)
                                            .frame(width: 16, height: 16)
                                        
                                        Text(item.category)
                                            .font(.system(size: 14))
                                        
                                        Spacer()
                                        
                                        Text(String(format: "%.1f%%", item.percentage))
                                            .font(.system(size: 14, weight: .medium))
                                        
                                        Text("$\(Int(item.amount).formattedWithComma)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .frame(height: 150)
                    }
                }
                .padding()
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // 多元化指標
            GroupBox {
                VStack(spacing: 15) {
                    Text("多元化指標")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 行業集中度
                    HStack {
                        Text("行業集中度")
                            .foregroundColor(.gray)
                        Spacer()
                        concentrationIndicator(value: metrics.riskMetrics.sectorConcentration)
                    }
                    
                    // 前五大持股比重
                    HStack {
                        Text("前五大持股比重")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.1f%%", metrics.riskMetrics.topHoldingsWeight))
                    }
                    
                    // 資產分散度
                    HStack {
                        Text("投資組合分散度評分")
                            .foregroundColor(.gray)
                        Spacer()
                        diversificationScore
                    }
                    
                    // 產業平衡性
                    HStack {
                        Text("產業平衡性")
                            .foregroundColor(.gray)
                        Spacer()
                        balanceIndicator
                    }
                }
                .padding()
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // 投資建議
            GroupBox {
                VStack(alignment: .leading, spacing: 15) {
                    Text("投資組合建議")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("根據您的資產配置，以下是優化建議：")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        // 建議列表 - 根據投資組合的特性動態顯示
                        if metrics.riskMetrics.sectorConcentration > 40 {
                            suggestionRow(icon: "exclamationmark.triangle", text: "產業集中度較高，建議增加其他產業的投資以分散風險。")
                        }
                        
                        if metrics.riskMetrics.topHoldingsWeight > 60 {
                            suggestionRow(icon: "chart.pie", text: "前五大持股占比過高，可考慮增加投資組合多樣性。")
                        }
                        
                        // 添加默認建議
                        suggestionRow(icon: "arrow.triangle.swap", text: "定期調整資產配置以維持目標配置比例。")
                        suggestionRow(icon: "chart.line.uptrend.xyaxis", text: "考慮增加目前比重較低的產業，提高投資組合的多元化。")
                    }
                }
                .padding()
            }
            .groupBoxStyle(TransparentGroupBox())
        }
        .padding(.horizontal)
    }
    
    // MARK: - 子視圖
    
    // 圓餅圖
    private var pieChart: some View {
        Chart {
            ForEach(metrics.assetAllocation) { item in
                SectorMark(
                    angle: .value("Investment", item.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 1
                )
                .foregroundStyle(item.color)
                .annotation(position: .overlay) {
                    if item.percentage >= 5 {
                        Text(String(format: "%.1f%%", item.percentage))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // 多元化分數視覺指示器
    private var diversificationScore: some View {
        let score = calculateDiversificationScore()
        
        return HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= score ? "star.fill" : "star")
                    .foregroundColor(index <= score ? .yellow : .gray)
                    .font(.system(size: 14))
            }
            
            Text(getDiversificationRating(score))
                .foregroundColor(score >= 4 ? .green : (score >= 2 ? .yellow : .red))
                .font(.system(size: 14))
                .padding(.leading, 4)
        }
    }
    
    // 產業平衡性指示器
    private var balanceIndicator: some View {
        let balance = calculateIndustryBalance()
        
        return HStack(spacing: 4) {
            Text(balance)
                .foregroundColor(
                    balance == "優良" ? .green :
                    balance == "良好" ? .blue :
                    balance == "一般" ? .yellow : .red
                )
            
            Image(systemName:
                balance == "優良" ? "checkmark.circle.fill" :
                balance == "良好" ? "checkmark.circle" :
                balance == "一般" ? "exclamationmark.circle" : "xmark.circle"
            )
            .foregroundColor(
                balance == "優良" ? .green :
                balance == "良好" ? .blue :
                balance == "一般" ? .yellow : .red
            )
            .font(.system(size: 14))
        }
    }
    
    // MARK: - 輔助視圖元件
    
    private func concentrationIndicator(value: Double) -> some View {
        HStack(spacing: 4) {
            ProgressView(value: value, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: value > 50 ? .red : (value > 30 ? .orange : .green)))
                .frame(width: 100)
            
            Text(String(format: "%.1f%%", value))
                .foregroundColor(value > 50 ? .red : (value > 30 ? .orange : .green))
        }
    }
    
    private func suggestionRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20, alignment: .center)
            
            Text(text)
                .font(.system(size: 14))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - 輔助計算方法
    
    // 計算多元化分數 (1-5)
    private func calculateDiversificationScore() -> Int {
        // 1. 考慮產業數量
        let industryCount = metrics.assetAllocation.count
        let industryScore = min(5, max(1, industryCount / 2))
        
        // 2. 考慮最高行業集中度
        let concentrationScore = min(5, max(1, 6 - Int(metrics.riskMetrics.sectorConcentration / 20)))
        
        // 3. 考慮前五大持股比重
        let topHoldingsScore = min(5, max(1, 6 - Int(metrics.riskMetrics.topHoldingsWeight / 20)))
        
        // 綜合評分 (簡單平均)
        return (industryScore + concentrationScore + topHoldingsScore) / 3
    }
    
    // 根據分數獲取評級描述
    private func getDiversificationRating(_ score: Int) -> String {
        switch score {
        case 5:
            return "優異"
        case 4:
            return "良好"
        case 3:
            return "一般"
        case 2:
            return "較低"
        default:
            return "不足"
        }
    }
    
    // 計算產業平衡性評估
    private func calculateIndustryBalance() -> String {
        // 計算產業配置的標準差，標準差越小代表越平衡
        if metrics.assetAllocation.count <= 1 {
            return "不足"
        }
        
        let percentages = metrics.assetAllocation.map { $0.percentage }
        let mean = percentages.reduce(0, +) / Double(percentages.count)
        
        let sumSquaredDiff = percentages.reduce(0) { $0 + pow($1 - mean, 2) }
        let standardDeviation = sqrt(sumSquaredDiff / Double(percentages.count))
        
        if standardDeviation < 5 {
            return "優良"
        } else if standardDeviation < 10 {
            return "良好"
        } else if standardDeviation < 20 {
            return "一般"
        } else {
            return "不足"
        }
    }
}
