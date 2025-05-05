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
    
    @State private var updatedDividendPerShare: Double?
    @State private var updatedFrequency: Int?
    @State private var isLoadingDividendInfo: Bool = true
    
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
                            
                            if isLoadingDividendInfo {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .frame(width: 10, height: 10)
                                    Text("更新中...")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Text("$\(String(format: "%.2f", updatedDividendPerShare ?? stockInfo.weightedDividendPerShare))")
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("年化股利")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            if isLoadingDividendInfo {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .frame(width: 10, height: 10)
                                    Text("更新中...")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Text("$\(String(format: "%.0f", calculateUpdatedTotalAnnualDividend()))")
                                    .foregroundColor(.green)
                            }
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
        .task {
            // 視圖顯示時載入最新資料
            if !hasRegularInvestment {
                await loadUpdatedDividendInfo()
            }
        }
    }
    private func loadUpdatedDividendInfo() async {
            isLoadingDividendInfo = true
            
            do {
                // 使用 APIService 和 SQLDataProcessor 獲取最新資料
                let dividendResponse = try await APIService.shared.getDividendData(symbol: stockInfo.symbol)
                
                // 使用 SQLDataProcessor 處理資料
                let frequency = SQLDataProcessor.shared.calculateDividendFrequency(from: dividendResponse.data)
                let dividendPerShare = SQLDataProcessor.shared.calculateDividendPerShare(from: dividendResponse.data)
                
                // 更新界面
                await MainActor.run {
                    self.updatedDividendPerShare = dividendPerShare
                    self.updatedFrequency = frequency
                    self.isLoadingDividendInfo = false
                }
                
                print("成功從 API 獲取股息資料: 頻率=\(frequency), 每股股息=\(dividendPerShare)")
            } catch {
                print("從 API 獲取股息資料失敗: \(error.localizedDescription)")
                
                // 如果 API 獲取失敗，使用本地服務作為備用
                let localService = LocalStockService()
                
                if let dividend = await localService.getTaiwanStockDividend(symbol: stockInfo.symbol) {
                    await MainActor.run {
                        self.updatedDividendPerShare = dividend
                    }
                }
                if let freq = await localService.getTaiwanStockFrequency(symbol: stockInfo.symbol) {
                    await MainActor.run {
                        self.updatedFrequency = freq
                    }
                }
                
                await MainActor.run {
                    self.isLoadingDividendInfo = false
                }
            }
        }
        
        // 計算更新後的年化股利
        private func calculateUpdatedTotalAnnualDividend() -> Double {
            let dividend = updatedDividendPerShare ?? stockInfo.weightedDividendPerShare
            let frequency = updatedFrequency ?? stockInfo.frequency
            return Double(stockInfo.totalShares) * dividend * Double(frequency)
        }
        
        private var hasRegularInvestment: Bool {
            stockInfo.details.contains { $0.regularInvestment != nil }
        }
    }
