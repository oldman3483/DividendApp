//
//  InvestmentOverviewView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/24.
//


import SwiftUI
import Charts

struct InvestmentOverviewView: View {
    @Binding var stocks: [Stock]
    @State private var selectedTimeRange = "1Y"
    @State private var selectedAnalysisType = "amount"
    
    private let timeRanges = ["1Y", "3Y", "5Y"]
    private let analysisTypes = ["amount", "yield"]
    
    // MARK: - 股利趨勢資料結構
    struct DividendTrend: Identifiable {
        let id = UUID()
        let date: Date
        let annualDividend: Double
        let yield: Double
    }
    
    // 計算總投資金額
    private var totalInvestment: Double {
        stocks.reduce(0) { $0 + (Double($1.shares) * ($1.purchasePrice ?? 0)) }
    }
    
    // 計算年化股利
    private var annualDividend: Double {
        stocks.reduce(0) { $0 + $1.calculateAnnualDividend() }
    }
    
    // 計算平均殖利率
    private var averageYield: Double {
        guard totalInvestment > 0 else { return 0 }
        return (annualDividend / totalInvestment) * 100
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 時間區間選擇器
                    timeRangeSelector
                    
                    // 投資概覽卡片
                    investmentSummaryCards
                    
                    // 股利統計
                    dividendStatistics
                    
                    // 個股績效排行
                    stockPerformanceRanking
                    
                    // 股利行事曆
                    dividendCalendar
                }
                .padding(.top, 20)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("投資總覽")
                        .navigationTitleStyle()
                }
            }
        }
    }
    
    // MARK: - 子視圖
    private var timeRangeSelector: some View {
        HStack(spacing: 15) {
            ForEach(timeRanges, id: \.self) { range in
                Button(action: {
                    selectedTimeRange = range
                }) {
                    Text(range)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(selectedTimeRange == range ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
        }
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
                summaryCard(title: "總投資金額", value: "$\(Int(totalInvestment).formattedWithComma)", color: .blue)
                summaryCard(title: "年化股利", value: "$\(Int(annualDividend).formattedWithComma)", color: .green)
                summaryCard(title: "平均殖利率", value: String(format: "%.2f%%", averageYield), color: .yellow)
                summaryCard(title: "持股數量", value: "\(stocks.count)", color: .purple)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var dividendStatistics: some View {
        VStack(spacing: 15) {
            Text("股利統計")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Chart(calculateTrendData()) { trend in
                LineMark(
                    x: .value("日期", trend.date),
                    y: .value("年化股利", trend.annualDividend)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.monotone)
                
                LineMark(
                    x: .value("日期", trend.date),
                    y: .value("殖利率", trend.yield)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.monotone)
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
                            Text("$\(Int(number))")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 200)
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
            
            ForEach(stocks.prefix(5).sorted(by: { $0.calculateAnnualDividend() > $1.calculateAnnualDividend() }), id: \.id) { stock in
                HStack {
                    Text(stock.symbol)
                        .font(.system(size: 16, weight: .medium))
                    Text(stock.name)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("$\(Int(stock.calculateAnnualDividend()).formattedWithComma)")
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
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
            
            ForEach(stocks.prefix(3), id: \.id) { stock in
                HStack {
                    VStack(alignment: .leading) {
                        Text(stock.symbol)
                            .font(.system(size: 16, weight: .medium))
                        Text("除息日: 2025/3/15") // 這裡應該使用實際的除息日期
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("$\(stock.dividendPerShare, specifier: "%.2f")")
                        .foregroundColor(.green)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
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
    
    // MARK: - 輔助方法
    private func calculateTrendData() -> [DividendTrend] {
        let calendar = Calendar.current
        var trendData: [DividendTrend] = []
        
        // 根據選擇的時間範圍決定起始日期
        let now = Date()
        let yearsToShow: Int = {
            switch selectedTimeRange {
            case "1Y": return 1
            case "3Y": return 3
            case "5Y": return 5
            default: return 1
            }
        }()
        
        guard let startDate = calendar.date(byAdding: .year, value: -yearsToShow, to: now) else { return [] }
        var currentDate = startDate
        
        while currentDate <= now {
            // 篩選在該日期之前購買的股票
            let relevantStocks = stocks.filter { $0.purchaseDate <= currentDate }
            
            // 計算總年化股利
            let totalAnnualDividend = relevantStocks.reduce(0) { $0 + $1.calculateAnnualDividend() }
            
            // 計算總投資金額
            let totalInvestment = relevantStocks.reduce(0) { $0 + (Double($1.shares) * ($1.purchasePrice ?? 0)) }
            
            // 計算殖利率
            let yield = totalInvestment > 0 ? (totalAnnualDividend / totalInvestment) * 100 : 0
            
            trendData.append(DividendTrend(
                date: currentDate,
                annualDividend: totalAnnualDividend,
                yield: yield
            ))
            
            // 移到下一個月
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = nextMonth
            } else {
                break
            }
        }
        
        return trendData
    }
}

// MARK: - 擴展
extension Int {
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}
