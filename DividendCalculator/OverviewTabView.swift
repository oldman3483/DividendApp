//
//  OverviewTabView.swift
//  DividendCalculator
//
//  Created on 2025/3/9.
//

import SwiftUI
import Charts


struct OverviewTabView: View {
    @Binding var stocks: [Stock]
    @Binding var metrics: InvestmentMetrics
    @Binding var selectedTimeRange: String
    @Binding var selectedAnalysisType: String
    @Binding var showReportGenerator: Bool

    let timeRanges: [String]
    let stockService: LocalStockService
    
    var body: some View {
        VStack(spacing: 20) {
            // 投資概覽卡片
            investmentSummaryCards
            
            // 績效指標
            performanceMetricsView
            
            //報表預覽卡片
            reportPreviewCard
            
            // 股利統計
            dividendStatistics
            
            // 個股績效排行
            stockPerformanceRanking
            
            // 股利行事曆
            dividendCalendar
        }
        .padding(.horizontal)
    }
    
    // MARK: - 子視圖
    
    private var reportPreviewCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("投資報表")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        showReportGenerator = true
                    }) {
                        Text("查看詳細報表")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                
                Text("生成投資報酬率或股利報酬率報表，輕鬆分享您的投資成果")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Button(action: {
                    showReportGenerator = true
                }) {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                        Text("生成報表")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.top, 5)
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
        .padding(.horizontal)
    }
    
    private var investmentSummaryCards: some View {
        VStack(spacing: 15) {
            Text("投資概覽")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                summaryCard(title: "總投資金額", value: "$\(Int(metrics.totalInvestment).formattedWithComma)", color: .blue)
                summaryCard(title: "年化股利", value: "$\(Int(metrics.annualDividend).formattedWithComma)", color: .green)
                summaryCard(title: "平均殖利率", value: String(format: "%.2f%%", metrics.averageYield), color: .yellow)
                summaryCard(title: "持股數量", value: "\(metrics.stockCount)", color: .purple)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    // 績效指標面板
    private var performanceMetricsView: some View {
        VStack(spacing: 15) {
            Text("績效指標")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack {
                    Text("總報酬")
                        .foregroundColor(.gray)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("$\(Int(metrics.performanceMetrics.totalReturn).formattedWithComma)")
                        Text("(\(String(format: "%.2f%%", metrics.performanceMetrics.totalReturnPercentage)))")
                            .foregroundColor(metrics.performanceMetrics.totalReturnPercentage >= 0 ? .green : .red)
                    }
                }
                
                HStack {
                    Text("時間加權報酬率")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(String(format: "%.2f%%", metrics.performanceMetrics.timeWeightedReturn))")
                        .foregroundColor(metrics.performanceMetrics.timeWeightedReturn >= 0 ? .green : .red)
                }
                
                HStack {
                    Text("平均持有期間")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(String(format: "%.1f", metrics.performanceMetrics.averageHoldingPeriod)) 個月")
                }
                
                HStack {
                    Text("夏普比率")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(String(format: "%.2f", metrics.performanceMetrics.sharpeRatio))")
                        .foregroundColor(metrics.performanceMetrics.sharpeRatio >= 1 ? .green :
                            (metrics.performanceMetrics.sharpeRatio >= 0 ? .yellow : .red))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var dividendStatistics: some View {
        VStack(spacing: 15) {
            HStack {
                Text("股利統計")
                    .font(.headline)
                Spacer()
                
                Picker("分析類型", selection: $selectedAnalysisType) {
                    Text("金額").tag("amount")
                    Text("殖利率").tag("yield")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            
            Chart {
                ForEach(metrics.trendData) { trend in
                    if selectedAnalysisType == "amount" {
                        LineMark(
                            x: .value("日期", trend.date),
                            y: .value("年化股利", trend.annualDividend)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.monotone)
                        
                        // 分開顯示一般持股和定期定額的股利
                        LineMark(
                            x: .value("日期", trend.date),
                            y: .value("一般持股", trend.normalDividend)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.monotone)
                        .symbol(.circle)
                        
                        LineMark(
                            x: .value("日期", trend.date),
                            y: .value("定期定額", trend.regularDividend)
                        )
                        .foregroundStyle(.orange)
                        .interpolationMethod(.monotone)
                        .symbol(.square)
                    } else {
                        LineMark(
                            x: .value("日期", trend.date),
                            y: .value("殖利率", trend.yield)
                        )
                        .foregroundStyle(.yellow)
                        .interpolationMethod(.monotone)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date.formatted(.dateTime.month().year()))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            if selectedAnalysisType == "amount" {
                                Text("$\(Int(number))")
                                    .foregroundColor(.gray)
                            } else {
                                Text(String(format: "%.1f%%", number))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .frame(height: 200)
            
            // 圖例
            HStack(spacing: 20) {
                if selectedAnalysisType == "amount" {
                    legendItem(color: .blue, text: "總年化")
                    legendItem(color: .green, text: "一般持股")
                    legendItem(color: .orange, text: "定期定額")
                } else {
                    legendItem(color: .yellow, text: "平均殖利率")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var stockPerformanceRanking: some View {
        VStack(spacing: 15) {
            Text("個股績效排行")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(metrics.topPerformingStocks.prefix(5), id: \.id) { stock in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stock.symbol)
                            .font(.system(size: 16, weight: .medium))
                        Text(stock.name)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(Int(stock.calculateAnnualDividend()).formattedWithComma)")
                            .foregroundColor(.green)
                            .font(.system(size: 16, weight: .medium))
                        
                        if let yield = stock.calculateDividendYield() {
                            Text(String(format: "%.2f%%", yield))
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var dividendCalendar: some View {
        VStack(spacing: 15) {
            Text("近期股利行事曆")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if metrics.upcomingDividends.isEmpty {
                Text("近期無股利行事曆")
                    .foregroundColor(.gray)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(metrics.upcomingDividends.prefix(3)) { dividend in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(dividend.symbol)
                                .font(.system(size: 16, weight: .medium))
                            Text(dividend.name)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("除息日: \(formatDate(dividend.exDividendDate))")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text("$\(dividend.dividendAmount, specifier: "%.2f")")
                                .foregroundColor(.green)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    
    // MARK: - 輔助視圖元件
    
    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}
