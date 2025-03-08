//
//  MonthlyTabView.swift
//  DividendCalculator
//
//  Created on 2025/3/9.
//

import SwiftUI
import Charts

struct MonthlyTabView: View {
    @Binding var metrics: InvestmentMetrics
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 月度股利圖表
            GroupBox {
                VStack(spacing: 15) {
                    Text("未來12個月股利預測")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if metrics.monthlyDividends.isEmpty {
                        ProgressView()
                            .frame(height: 200)
                    } else {
                        monthlyDividendChart
                            .frame(height: 250)
                        
                        // 總計
                        HStack {
                            Text("預計年度總股利:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("$\(Int(metrics.monthlyDividends.reduce(0) { $0 + $1.amount }).formattedWithComma)")
                                .foregroundColor(.green)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // 月度股利明細
            GroupBox {
                VStack(spacing: 15) {
                    Text("月度股利明細")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    monthlySummaryView
                    
                    monthlyDetailList
                }
                .padding()
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // 股利來源分析
            GroupBox {
                VStack(spacing: 15) {
                    Text("股利來源分析")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    dividendSourceChart
                        .frame(height: 200)
                    
                    // 來源說明
                    dividendSourceLegend
                }
                .padding()
            }
            .groupBoxStyle(TransparentGroupBox())
        }
        .padding(.horizontal)
    }
    
    // MARK: - 子視圖
    
    // 月度股利圖表
    private var monthlyDividendChart: some View {
        Chart {
            ForEach(metrics.monthlyDividends.sorted(by: { $0.month < $1.month }).prefix(12)) { monthly in
                BarMark(
                    x: .value("Month", formatMonth(monthly.month)),
                    y: .value("Dividend", monthly.amount)
                )
                .foregroundStyle(.green)
                .annotation(position: .top) {
                    if monthly.amount > 0 {
                        Text("$\(Int(monthly.amount))")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let number = value.as(Double.self) {
                    AxisValueLabel {
                        Text("$\(Int(number))")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // 月度股利摘要視圖
    private var monthlySummaryView: some View {
        HStack(spacing: 20) {
            summaryMetric(
                title: "平均月配息",
                value: calculateAverageMonthlyDividend(),
                format: { "$\(Int($0).formattedWithComma)" },
                color: .green
            )
            
            summaryMetric(
                title: "最高月配息",
                value: calculateMaxMonthlyDividend().0,
                format: { "$\(Int($0).formattedWithComma)" },
                subtitle: formatMonth(calculateMaxMonthlyDividend().1),
                color: .blue
            )
            
            summaryMetric(
                title: "最低月配息",
                value: calculateMinMonthlyDividend().0,
                format: { "$\(Int($0).formattedWithComma)" },
                subtitle: formatMonth(calculateMinMonthlyDividend().1),
                color: .orange
            )
        }
        .padding(.vertical, 8)
    }
    
    // 月度股利詳細列表
    private var monthlyDetailList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(metrics.monthlyDividends.sorted(by: { $0.month < $1.month }).prefix(12)) { monthly in
                    HStack {
                        Text(formatMonth(monthly.month))
                            .frame(width: 60, alignment: .leading)
                        
                        Spacer()
                        
                        Text("$\(Int(monthly.amount).formattedWithComma)")
                            .foregroundColor(.green)
                            .frame(width: 80)
                        
                        HStack(spacing: 5) {
                            Text("一般:")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                            Text("$\(Int(monthly.normalDividend).formattedWithComma)")
                                .font(.system(size: 12))
                        }
                        .frame(width: 100)
                        
                        HStack(spacing: 5) {
                            Text("定期:")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                            Text("$\(Int(monthly.regularDividend).formattedWithComma)")
                                .font(.system(size: 12))
                        }
                        .frame(width: 100)
                    }
                    .padding(.vertical, 12)
                    
                    if monthly.id != metrics.monthlyDividends.sorted(by: { $0.month < $1.month }).prefix(12).last?.id {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                }
            }
        }
        .frame(height: 300)
    }
    
    // 股利來源圓餅圖
    private var dividendSourceChart: some View {
        let (normalTotal, regularTotal) = calculateDividendSourceTotals()
        
        return Chart {
            SectorMark(
                angle: .value("Normal", normalTotal),
                innerRadius: .ratio(0.6),
                angularInset: 1.0
            )
            .foregroundStyle(.green)
            .annotation(position: .overlay) {
                if normalTotal > 0 {
                    let percentage = (normalTotal / (normalTotal + regularTotal)) * 100
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            SectorMark(
                angle: .value("Regular", regularTotal),
                innerRadius: .ratio(0.6),
                angularInset: 1.0
            )
            .foregroundStyle(.orange)
            .annotation(position: .overlay) {
                if regularTotal > 0 {
                    let percentage = (regularTotal / (normalTotal + regularTotal)) * 100
                    Text(String(format: "%.1f%%", percentage))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // 股利來源圖例
    private var dividendSourceLegend: some View {
        let (normalTotal, regularTotal) = calculateDividendSourceTotals()
        let total = normalTotal + regularTotal
        
        return HStack(spacing: 20) {
            legendItem(
                color: .green,
                title: "一般持股股利",
                value: "$\(Int(normalTotal).formattedWithComma)",
                percentage: total > 0 ? (normalTotal / total) * 100 : 0
            )
            
            legendItem(
                color: .orange,
                title: "定期定額股利",
                value: "$\(Int(regularTotal).formattedWithComma)",
                percentage: total > 0 ? (regularTotal / total) * 100 : 0
            )
        }
        .padding(.top, 8)
    }
    
    // MARK: - 輔助視圖元件
    
    private func summaryMetric(title: String, value: Double, format: (Double) -> String, subtitle: String? = nil, color: Color) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            
            Text(format(value))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func legendItem(color: Color, title: String, value: String, percentage: Double) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(String(format: "(%.1f%%)", percentage))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - 輔助計算方法
    
    // 計算平均月配息
    private func calculateAverageMonthlyDividend() -> Double {
        guard !metrics.monthlyDividends.isEmpty else { return 0 }
        let totalDividend = metrics.monthlyDividends.reduce(0) { $0 + $1.amount }
        return totalDividend / Double(metrics.monthlyDividends.count)
    }
    
    // 計算最高月配息及其月份
    private func calculateMaxMonthlyDividend() -> (Double, Date) {
        guard let maxDividend = metrics.monthlyDividends.max(by: { $0.amount < $1.amount }) else {
            return (0, Date())
        }
        return (maxDividend.amount, maxDividend.month)
    }
    
    // 計算最低月配息及其月份
    private func calculateMinMonthlyDividend() -> (Double, Date) {
        // 過濾掉為零的配息以找到真正的最低值
        let nonZeroDividends = metrics.monthlyDividends.filter { $0.amount > 0 }
        guard let minDividend = nonZeroDividends.min(by: { $0.amount < $1.amount }) else {
            return (0, Date())
        }
        return (minDividend.amount, minDividend.month)
    }
    
    // 計算一般持股與定期定額的總股利
    private func calculateDividendSourceTotals() -> (Double, Double) {
        let normalTotal = metrics.monthlyDividends.reduce(0) { $0 + $1.normalDividend }
        let regularTotal = metrics.monthlyDividends.reduce(0) { $0 + $1.regularDividend }
        return (normalTotal, regularTotal)
    }
    
    // MARK: - 輔助格式化方法
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月"
        return formatter.string(from: date)
    }
}
