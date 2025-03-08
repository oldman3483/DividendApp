//
//  GrowthTabView.swift
//  DividendCalculator
//
//  Created on 2025/3/9.
//

import SwiftUI
import Charts

struct GrowthTabView: View {
    @Binding var metrics: InvestmentMetrics
    @Binding var isLoading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 股息成長圖表
            GroupBox {
                VStack(spacing: 15) {
                    Text("股息成長趨勢")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if metrics.dividendGrowth.isEmpty {
                        ProgressView()
                            .frame(height: 200)
                    } else {
                        dividendGrowthChart
                            .frame(height: 250)
                        
                        // 平均成長率
                        let avgGrowthRate = calculateAverageGrowthRate()
                        
                        HStack {
                            Text("平均年增長率:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(String(format: "%.2f%%", avgGrowthRate))
                                .foregroundColor(avgGrowthRate >= 0 ? .green : .red)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // 成長摘要指標
            GroupBox {
                VStack(spacing: 15) {
                    Text("成長指標摘要")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 成長指標網格
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        growthMetricCard(
                            title: "三年複合成長率",
                            value: calculateCAGR(years: 3),
                            color: calculateCAGR(years: 3) >= 0 ? .green : .red
                        )
                        
                        growthMetricCard(
                            title: "五年複合成長率",
                            value: calculateCAGR(years: 5),
                            color: calculateCAGR(years: 5) >= 0 ? .green : .red
                        )
                        
                        growthMetricCard(
                            title: "成長率波動性",
                            value: calculateGrowthVolatility(),
                            format: "%.2f%%",
                            color: calculateGrowthVolatility() < 10 ? .green :
                                   (calculateGrowthVolatility() < 20 ? .yellow : .red)
                        )
                        
                        growthMetricCard(
                            title: "現金流再投資率",
                            value: calculateReinvestmentRate(),
                            color: calculateReinvestmentRate() > 30 ? .green : .blue
                        )
                    }
                }
                .padding()
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // 股息成長明細
            GroupBox {
                VStack(spacing: 15) {
                    Text("股息成長明細")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(metrics.dividendGrowth.sorted(by: { $0.year > $1.year })) { item in
                        HStack {
                            Text("\(item.year)")
                                .frame(width: 60, alignment: .leading)
                            
                            Spacer()
                            
                            Text("$\(Int(item.annualDividend).formattedWithComma)")
                                .foregroundColor(.green)
                                .frame(width: 100)
                            
                            HStack(spacing: 3) {
                                if item.growthRate > -100 { // 避免第一年的無限成長率
                                    Image(systemName: item.growthRate >= 0 ? "arrow.up" : "arrow.down")
                                        .foregroundColor(item.growthRate >= 0 ? .green : .red)
                                        .font(.system(size: 12))
                                    
                                    Text(String(format: "%.2f%%", abs(item.growthRate)))
                                        .foregroundColor(item.growthRate >= 0 ? .green : .red)
                                } else {
                                    Text("-")
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(width: 80)
                        }
                        .padding(.vertical, 6)
                        
                        if item.id != metrics.dividendGrowth.sorted(by: { $0.year > $1.year }).last?.id {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                        }
                    }
                }
                .padding()
            }
            .groupBoxStyle(TransparentGroupBox())
            
            // 成長預測
            GroupBox {
                VStack(spacing: 15) {
                    Text("股息成長預測")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 未來預測圖表
                    growthForecastChart
                        .frame(height: 200)
                    
                    // 預測說明
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("保守預測")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            
                            let conservativeRate = max(0, calculateAverageGrowthRate() - 2)
                            Text(String(format: "+%.1f%%/年", conservativeRate))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("基準預測")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                            
                            Text(String(format: "+%.1f%%/年", calculateAverageGrowthRate()))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("樂觀預測")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                            
                            let optimisticRate = calculateAverageGrowthRate() + 2
                            Text(String(format: "+%.1f%%/年", optimisticRate))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
                .padding()
            }
            .groupBoxStyle(TransparentGroupBox())
        }
        .padding(.horizontal)
    }
    
    // MARK: - 子視圖
    
    // 股息成長圖表
    private var dividendGrowthChart: some View {
        Chart {
            ForEach(metrics.dividendGrowth.sorted(by: { $0.year < $1.year })) { item in
                BarMark(
                    x: .value("Year", "\(item.year)"),
                    y: .value("Dividend", item.annualDividend)
                )
                .foregroundStyle(.green)
                
                if item.year > metrics.dividendGrowth.sorted(by: { $0.year < $1.year }).first?.year ?? 0 {
                    LineMark(
                        x: .value("Year", "\(item.year)"),
                        y: .value("Growth", item.growthRate * 100)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
        }
        .chartYScale(domain: .automatic(includesZero: true))
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
            
            AxisMarks(position: .trailing) { value in
                if let number = value.as(Double.self), number >= -100 && number <= 100 {
                    AxisValueLabel {
                        Text("\(Int(number))%")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // 未來成長預測圖表
    private var growthForecastChart: some View {
        let currentYear = getCurrentYear()
        let lastDividendValue = getLastDividendValue()
        let forecastYears = 5
        
        return Chart {
            // 歷史資料
            ForEach(metrics.dividendGrowth.sorted(by: { $0.year < $1.year })) { item in
                LineMark(
                    x: .value("Year", item.year),
                    y: .value("Dividend", item.annualDividend)
                )
                .foregroundStyle(.gray)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .symbolSize(20)
            }
            
            // 保守預測
            ForEach(1...forecastYears, id: \.self) { year in
                let conservativeRate = max(0, calculateAverageGrowthRate() - 2) / 100
                let value = lastDividendValue * pow(1 + conservativeRate, Double(year))
                
                LineMark(
                    x: .value("Year", currentYear + year),
                    y: .value("Conservative", value)
                )
                .foregroundStyle(.blue.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            }
            
            // 基準預測
            ForEach(1...forecastYears, id: \.self) { year in
                let baseRate = calculateAverageGrowthRate() / 100
                let value = lastDividendValue * pow(1 + baseRate, Double(year))
                
                LineMark(
                    x: .value("Year", currentYear + year),
                    y: .value("Base", value)
                )
                .foregroundStyle(.green.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            
            // 樂觀預測
            ForEach(1...forecastYears, id: \.self) { year in
                let optimisticRate = (calculateAverageGrowthRate() + 2) / 100
                let value = lastDividendValue * pow(1 + optimisticRate, Double(year))
                
                LineMark(
                    x: .value("Year", currentYear + year),
                    y: .value("Optimistic", value)
                )
                .foregroundStyle(.orange.opacity(0.8))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .chartXAxis {
            AxisMarks { value in
                if let year = value.as(Int.self) {
                    AxisValueLabel {
                        Text("\(year)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
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
    
    // MARK: - 輔助視圖元件
    
    private func growthMetricCard(title: String, value: Double, format: String = "%.2f%%", color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text(String(format: format, value))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - 輔助計算方法
    
    // 計算平均成長率
    private func calculateAverageGrowthRate() -> Double {
        let validGrowthRates = metrics.dividendGrowth.filter { $0.growthRate > -100 }
        guard !validGrowthRates.isEmpty else { return 0 }
        
        let sum = validGrowthRates.reduce(0) { $0 + $1.growthRate }
        return sum / Double(validGrowthRates.count)
    }
    
    // 計算年複合成長率 (CAGR)
    private func calculateCAGR(years: Int) -> Double {
        let sortedData = metrics.dividendGrowth.sorted(by: { $0.year < $1.year })
        guard sortedData.count >= years + 1 else { return calculateAverageGrowthRate() }
        
        let startIndex = sortedData.count - years - 1
        let startValue = sortedData[startIndex].annualDividend
        let endValue = sortedData.last?.annualDividend ?? 0
        
        guard startValue > 0 else { return 0 }
        
        // CAGR = (終值/初值)^(1/年數) - 1
        return (pow((endValue / startValue), 1.0 / Double(years)) - 1) * 100
    }
    
    // 計算成長率波動性（標準差）
    private func calculateGrowthVolatility() -> Double {
        let validGrowthRates = metrics.dividendGrowth.filter { $0.growthRate > -100 }
        guard validGrowthRates.count > 1 else { return 0 }
        
        let mean = calculateAverageGrowthRate()
        let sumOfSquaredDifferences = validGrowthRates.reduce(0) { $0 + pow($1.growthRate - mean, 2) }
        
        return sqrt(sumOfSquaredDifferences / Double(validGrowthRates.count - 1))
    }
    
    // 計算現金流再投資率（模擬數據）
    private func calculateReinvestmentRate() -> Double {
        // 在實際應用中，此處應該計算真正的再投資率
        // 這裡使用一個基於平均成長率的模擬值
        let baseRate = 25.0 // 基礎再投資率
        let growthAdjustment = min(10.0, max(-10.0, calculateAverageGrowthRate() / 2))
        
        return baseRate + growthAdjustment
    }
    
    // 獲取當前年份
    private func getCurrentYear() -> Int {
        let sortedData = metrics.dividendGrowth.sorted(by: { $0.year > $1.year })
        return sortedData.first?.year ?? Calendar.current.component(.year, from: Date())
    }
    
    // 獲取最後一年的股息值
    private func getLastDividendValue() -> Double {
        let sortedData = metrics.dividendGrowth.sorted(by: { $0.year > $1.year })
        return sortedData.first?.annualDividend ?? 0
    }
}
