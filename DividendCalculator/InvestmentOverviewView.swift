//
//  InvestmentOverviewView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/24.
//


import SwiftUI

struct InvestmentOverviewView: View {
    @Binding var stocks: [Stock]
    @State private var selectedTimeRange = "1Y"
    @State private var selectedAnalysisType = "amount"
    
    private let timeRanges = ["1Y", "3Y", "5Y"]
    private let analysisTypes = ["amount", "yield"]
    
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
            // 卡片標題
            Text("投資概覽")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 卡片網格
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
            
            // 這裡可以加入圖表視圖
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    Text("股利趨勢圖")
                        .foregroundColor(.gray)
                )
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
}

// MARK: - 擴展
extension Int {
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}

#Preview {
    NavigationStack {
        InvestmentOverviewView(stocks: .constant([]))
    }
}
