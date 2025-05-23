//
//  HoldingDetailViews.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/19.
//

import SwiftUI

// MARK: - 一般持股詳細頁面
struct NormalStockDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    let symbol: String
    let bankId: UUID
    
    // 添加狀態以存儲從SQL資料庫獲取的最新資料
    @State private var updatedDividendPerShare: Double?
    @State private var updatedFrequency: Int?
    @State private var isLoadingDividendInfo: Bool = true
    
    private var normalStocks: [Stock] {
        stocks.filter { $0.symbol == symbol && $0.bankId == bankId && $0.regularInvestment == nil }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本資訊卡片
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        // 股票基本資訊
                        HStack {
                            Text(symbol)
                                .font(.title2)
                                .bold()
                            Text(normalStocks.first?.name ?? "")
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 5)
                        
                        // 彙總持股資訊
                        let totalShares = normalStocks.reduce(0) { $0 + $1.shares }
                        DetailRow(title: "總持股數量", value: "\(totalShares) 股")
                        
                        if let avgCost = calculateAverageCost() {
                            DetailRow(title: "平均成本", value: String(format: "$ %.2f", avgCost))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 股利資訊卡片 - 使用更新後的資料
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("股利資訊")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        let stock = normalStocks.first
                        
                        // 每股股利行 - 添加載入指示器
                        HStack {
                            Text("每股股利")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            if isLoadingDividendInfo {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 20, height: 20)
                                Text("更新中...")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            } else {
                                Text(String(format: "$ %.2f", updatedDividendPerShare ?? stock?.dividendPerShare ?? 0))
                            }
                        }
                        
                        // 發放頻率行 - 添加載入指示器
                        HStack {
                            Text("發放頻率")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            if isLoadingDividendInfo {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 20, height: 20)
                                Text("更新中...")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            } else {
                                Text(getFrequencyText(updatedFrequency ?? stock?.frequency ?? 1))
                            }
                        }
                        
                        // 年化股利行
                        HStack {
                            Text("年化股利")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            if isLoadingDividendInfo {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 20, height: 20)
                                Text("更新中...")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            } else {
                                Text(String(format: "$ %.0f", calculateTotalAnnualDividend(
                                    withDividendPerShare: updatedDividendPerShare,
                                    withFrequency: updatedFrequency
                                )))
                                .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 績效分析卡片
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("績效分析")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        let totalInvestment = normalStocks.reduce(0.0) {
                            $0 + (Double($1.shares) * ($1.purchasePrice ?? 0))
                        }
                        
                        DetailRow(
                            title: "總投資成本",
                            value: String(format: "$ %.0f", totalInvestment)
                        )
                        
                        HStack {
                            Text("殖利率")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            if isLoadingDividendInfo {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 20, height: 20)
                                Text("更新中...")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            } else {
                                Text(String(format: "%.2f%%", calculateDividendYield(
                                    withDividendPerShare: updatedDividendPerShare,
                                    withFrequency: updatedFrequency
                                )))
                                .foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 購買明細區塊 (保持不變)
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("購買明細")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        ForEach(normalStocks.sorted(by: { $0.purchaseDate > $1.purchaseDate }), id: \.id) { stock in
                            purchaseDetailRow(for: stock)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .groupBoxStyle(TransparentGroupBox())
            }
            .padding()
        }
        .navigationTitle("一般持股詳細資訊")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
        .task {
            // 視圖顯示時從SQL資料庫載入最新資料
            await loadUpdatedDividendInfo()
        }
    }
    
    // 新增: 從SQL資料庫讀取最新的股息資料
    private func loadUpdatedDividendInfo() async {
        isLoadingDividendInfo = true
        
        do {
            // 使用 APIService 和 SQLDataProcessor 獲取最新資料
            let dividendResponse = try await APIService.shared.getDividendData(symbol: symbol)
            
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
            
            if let dividend = await localService.getTaiwanStockDividend(symbol: symbol) {
                await MainActor.run {
                    self.updatedDividendPerShare = dividend
                }
            }
            if let freq = await localService.getTaiwanStockFrequency(symbol: symbol) {
                await MainActor.run {
                    self.updatedFrequency = freq
                }
            }
            
            await MainActor.run {
                self.isLoadingDividendInfo = false
            }
        }
    }
    
    // 修改計算年化股利的方法，以使用更新的數據
    private func calculateTotalAnnualDividend(withDividendPerShare dividend: Double? = nil, withFrequency frequency: Int? = nil) -> Double {
        return normalStocks.reduce(0) {
            let divPerShare = dividend ?? $1.dividendPerShare
            let freq = frequency ?? $1.frequency
            return $0 + (Double($1.shares) * divPerShare * Double(freq))
        }
    }
    
    // 修改計算殖利率的方法，以使用更新的數據
    private func calculateDividendYield(withDividendPerShare dividend: Double? = nil, withFrequency frequency: Int? = nil) -> Double {
        let totalInvestment = normalStocks.reduce(0.0) {
            $0 + (Double($1.shares) * ($1.purchasePrice ?? 0))
        }
        let totalAnnualDividend = calculateTotalAnnualDividend(
            withDividendPerShare: dividend,
            withFrequency: frequency
        )
        
        return totalInvestment > 0 ? (totalAnnualDividend / totalInvestment) * 100 : 0
    }
    
    // 其他方法保持不變
    private func calculateAverageCost() -> Double? {
        let totalInvestment = normalStocks.reduce(0.0) {
            $0 + (Double($1.shares) * ($1.purchasePrice ?? 0))
        }
        let totalShares = normalStocks.reduce(0) { $0 + $1.shares }
        
        return totalShares > 0 ? totalInvestment / Double(totalShares) : nil
    }
    
    private func purchaseDetailRow(for stock: Stock) -> some View {
        // (保持原來的實現)
        VStack(alignment: .leading, spacing: 8) {
            GroupBox {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                            Text("購買日期")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text(formatDate(stock.purchaseDate))
                            .font(.system(size: 16))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                            Text("股數")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Text("\(stock.shares) 股")
                            .font(.system(size: 16))
                    }
                    
                    Spacer()
                    
                    if let price = stock.purchasePrice {
                        VStack(alignment: .trailing, spacing: 8) {
                            HStack {
                                Text("股價")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Image(systemName: "dollarsign.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                            }
                            Text("$\(String(format: "%.2f", price))")
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.vertical, 8)
                
                HStack {
                    Text("總成本")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let price = stock.purchasePrice {
                        Text("$\(String(format: "%.0f", Double(stock.shares) * price))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            .groupBoxStyle(TransparentGroupBox())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 定期定額詳細頁面
struct RegularInvestmentDetailView: View {
    @Binding var stocks: [Stock]
    let symbol: String
    let bankId: UUID
    let planId: UUID
    
    private var stock: Stock? {
        stocks.first { $0.id == planId }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本資訊卡片
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        // 標題區域
                        HStack {
                            Text(symbol)
                                .font(.title2)
                                .bold()
                            Text(stock?.name ?? "")
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 8)
                        
                        // 定期定額設定詳情
                        DetailRow(
                            title: "計劃標題",
                            value: stock?.regularInvestment?.title ?? ""
                        )
                        
                        DetailRow(
                            title: "每期金額",
                            value: String(format: "$ %.0f", stock?.regularInvestment?.amount ?? 0)
                        )
                        
                        DetailRow(
                            title: "投資頻率",
                            value: stock?.regularInvestment?.frequency.rawValue ?? ""
                        )
                        
                        DetailRow(
                            title: "開始日期",
                            value: formatDate(stock?.regularInvestment?.startDate)
                        )
                        
                        if let endDate = stock?.regularInvestment?.endDate {
                            DetailRow(title: "結束日期", value: formatDate(endDate))
                        }
                        
                        DetailRow(
                            title: "執行狀態",
                            value: stock?.regularInvestment?.executionStatus.description ?? "未啟用",
                            valueColor: stock?.regularInvestment?.executionStatus.color ?? .gray
                        )
                        
                        if let note = stock?.regularInvestment?.note, !note.isEmpty {
                            DetailRow(title: "備註", value: note)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 投資成效卡片
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("投資成效")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        // 已執行投資金額
                        let executedAmount = (stock?.regularInvestment?.transactions ?? [])
                            .filter { $0.isExecuted }
                            .reduce(0) { $0 + $1.amount }
                            
                        DetailRow(
                            title: "已執行投資",
                            value: String(format: "$ %.0f", executedAmount)
                        )
                        
                        // 預計投資金額（未執行的交易）
                        let pendingAmount = (stock?.regularInvestment?.transactions ?? [])
                            .filter { !$0.isExecuted }
                            .reduce(0) { $0 + $1.amount }
                            
                        if pendingAmount > 0 {
                            DetailRow(
                                title: "預計投資",
                                value: String(format: "$ %.0f", pendingAmount),
                                valueColor: .gray
                            )
                        }
                        
                        DetailRow(
                            title: "累計股數",
                            value: "\(stock?.regularInvestment?.totalShares ?? 0) 股"
                        )
                        
                        if let avgCost = stock?.regularInvestment?.averageCost {
                            DetailRow(
                                title: "平均成本",
                                value: String(format: "$ %.2f", avgCost)
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 交易記錄列表
                if let transactions = stock?.regularInvestment?.transactions?.sorted(by: { $0.date > $1.date }) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("交易記錄")
                                    .font(.headline)
                                Spacer()
                                Text("\(transactions.count) 筆")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 4)
                            
                            // 執行狀態統計
                            HStack(spacing: 20) {
                                let executedCount = transactions.filter { $0.isExecuted }.count
                                let pendingCount = transactions.filter { !$0.isExecuted }.count
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("已執行")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(executedCount)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("待執行")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(pendingCount)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.vertical, 8)
                            
                            // 交易記錄列表
                            ForEach(transactions) { transaction in
                                VStack(spacing: 12) {
                                    HStack {
                                        Text(formatDate(transaction.date))
                                            .font(.system(size: 15))
                                        Spacer()
                                        Text(transaction.isExecuted ? "已執行" : "待執行")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(transaction.isExecuted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                            )
                                    }
                                    
                                    HStack(spacing: 20) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("投資金額")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("$\(Int(transaction.amount).formattedWithComma)")
                                                .font(.system(size: 15, weight: .medium))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("成交價")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("$\(String(format: "%.2f", transaction.price))")
                                                .font(.system(size: 15, weight: .medium))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("股數")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("\(transaction.shares)")
                                                .font(.system(size: 15, weight: .medium))
                                        }
                                    }
                                    
                                    if transaction != transactions.last {
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                            .padding(.top, 8)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .groupBoxStyle(TransparentGroupBox())
                }
            }
            .padding()
        }
        .navigationTitle("定期定額詳細資訊")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Stock 擴展
extension Stock {
    func calculateDividendYield() -> Double? {
        guard let purchasePrice = purchasePrice, purchasePrice > 0 else { return nil }
        return (dividendPerShare * Double(frequency) / purchasePrice) * 100
    }
}
