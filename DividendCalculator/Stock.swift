//
//  Stock.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import Foundation
import SwiftUI

// MARK: - 定期定額交易紀錄
struct RegularInvestmentTransaction: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let amount: Double      // 投資金額
    let shares: Int        // 購買股數
    let price: Double      // 成交價格
    let isExecuted: Bool   // 是否已執行
    
    init(id: UUID = UUID(), date: Date, amount: Double, shares: Int, price: Double, isExecuted: Bool = false) {
        self.id = id
        self.date = date
        self.amount = amount
        self.shares = shares
        self.price = price
        self.isExecuted = isExecuted
    }
    
    // 實作 Equatable
    static func == (lhs: RegularInvestmentTransaction, rhs: RegularInvestmentTransaction) -> Bool {
        return lhs.id == rhs.id &&
               lhs.date == rhs.date &&
               lhs.amount == rhs.amount &&
               lhs.shares == rhs.shares &&
               lhs.price == rhs.price &&
               lhs.isExecuted == rhs.isExecuted
    }
}

// MARK: - 定期定額設定
struct RegularInvestment: Codable, Equatable {
    var title: String           // 計劃標題
    var amount: Double           // 每期投資金額
    var frequency: Frequency     // 投資頻率
    var startDate: Date         // 開始日期
    var endDate: Date?          // 結束日期
    var isActive: Bool          // 是否啟用
    var note: String?           // 備註
    var transactions: [RegularInvestmentTransaction]? // 交易紀錄
    
    enum Frequency: String, Codable, CaseIterable {
        case weekly = "每週"
        case monthly = "每月"
        case quarterly = "每季"
        
        var days: Int {
            switch self {
            case .weekly: return 7
            case .monthly: return 30
            case .quarterly: return 90
            }
        }
    }
    
    // 定期定額執行狀態
    enum ExecutionStatus {
        case ongoing   // 進行中
        case completed // 已完成
        case stopped   // 已停止
        case inactive  // 未啟用
        
        var description: String {
            switch self {
            case .ongoing: return "進行中"
            case .completed: return "已完成"
            case .stopped: return "已停止"
            case .inactive: return "未啟用"
            }
        }
        
        var color: Color {
            switch self {
            case .ongoing: return .green
            case .completed: return .blue
            case .stopped: return .red
            case .inactive: return .gray
            }
        }
    }
    // 計算執行狀態
    var executionStatus: ExecutionStatus {
        // 如果沒有交易記錄，則根據開始日期判斷
        guard let transactions = transactions,
              !transactions.isEmpty else {
            // 如果開始日期在今天或之前，且計畫已啟用，顯示為進行中
            if startDate <= Date() && isActive {
                return .ongoing
            }
            // 如果開始日期在未來，顯示為未啟用
            return .inactive
        }
        
        let hasPendingTransactions = transactions.contains { !$0.isExecuted }
        if !isActive {
            return .stopped
        } else if !hasPendingTransactions {
            return .completed
        } else {
            return .ongoing
        }
    }
    
    // 實作 Equatable
    static func == (lhs: RegularInvestment, rhs: RegularInvestment) -> Bool {
        return lhs.amount == rhs.amount &&
               lhs.frequency == rhs.frequency &&
               lhs.startDate == rhs.startDate &&
               lhs.endDate == rhs.endDate &&
               lhs.isActive == rhs.isActive &&
               lhs.note == rhs.note &&
               lhs.transactions == rhs.transactions
    }
    
    // 計算下一次投資日期
    func nextInvestmentDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self.frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        }
    }
    
    // 計算所有投資日期
    func calculateInvestmentDates() -> [Date] {
        var dates: [Date] = []
        var currentDate = self.startDate
        let endDate = self.endDate ?? Date()
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = nextInvestmentDate(from: currentDate)
        }
        
        return dates
    }
    
    // 計算總投資金額
    var totalInvestmentAmount: Double {
        guard let transactions = transactions else { return 0 }
        return transactions.reduce(0) { $0 + $1.amount }
    }
    
    // 計算總股數
    var totalShares: Int {
        guard let transactions = transactions else { return 0 }
        return transactions.reduce(0) { $0 + $1.shares }
    }
    
    // 計算平均成本
    var averageCost: Double? {
        guard totalShares > 0 else { return nil }
        return totalInvestmentAmount / Double(totalShares)
    }
}

// MARK: - 股票結構體
struct Stock: Identifiable, Codable, Equatable {
    // MARK: - Properties
    var id: UUID
    let symbol: String             // 股票代號
    let name: String              // 公司名稱
    var shares: Int               // 持股數量
    var dividendPerShare: Double   // 每股股利
    let dividendYear: Int         // 股利年度
    let isHistorical: Bool        // 是否為歷史股利
    var frequency: Int            // 發放頻率（1=年配, 2=半年配, 4=季配, 12=月配）
    var purchaseDate: Date        // 購買日期
    var purchasePrice: Double?    // 購買價格
    var bankId: UUID             // 關聯的銀行ID
    var regularInvestment: RegularInvestment? // 定期定額設定
    
    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        shares: Int,
        dividendPerShare: Double,
        dividendYear: Int,
        isHistorical: Bool = false,
        frequency: Int = 1,
        purchaseDate: Date = Date(),
        purchasePrice: Double? = nil,
        bankId: UUID,
        regularInvestment: RegularInvestment? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.shares = shares
        self.dividendPerShare = dividendPerShare
        self.dividendYear = dividendYear
        self.isHistorical = isHistorical
        self.frequency = frequency
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.bankId = bankId
        self.regularInvestment = regularInvestment
    }
    
    // MARK: - Calculations
    
    /// 計算年化股利
    func calculateAnnualDividend() -> Double {
        let totalShares = self.totalShares
        return Double(totalShares) * dividendPerShare * Double(frequency)
    }
    
    /// 計算總持股數
    var totalShares: Int {
        if let regularInvestment = regularInvestment {
            return regularInvestment.totalShares + shares
        }
        return shares
    }
    
    /// 計算購買時的總價值
    func calculateTotalCost() -> Double? {
        if let price = purchasePrice {
            return Double(shares) * price
        }
        return nil
    }
    
    /// 計算平均成本
    func calculateAverageCost() -> Double? {
        var totalCost = 0.0
        var totalShares = 0
        
        // 一般購買成本
        if let purchasePrice = purchasePrice {
            totalCost += Double(shares) * purchasePrice
            totalShares += shares
        }
        
        // 定期定額成本
        if let regularInvestment = regularInvestment {
            totalCost += regularInvestment.totalInvestmentAmount
            totalShares += regularInvestment.totalShares
        }
        
        guard totalShares > 0 else { return nil }
        return totalCost / Double(totalShares)
    }
    
    /// 計算損益
    func calculateProfitLoss(currentPrice: Double) -> Double {
        guard let avgCost = calculateAverageCost() else { return 0 }
        return Double(totalShares) * (currentPrice - avgCost)
    }
    
    /// 計算報酬率
    func calculateROI(currentPrice: Double) -> Double {
        guard let avgCost = calculateAverageCost(), avgCost > 0 else { return 0 }
        return ((currentPrice - avgCost) / avgCost) * 100
    }
    
    // MARK: - Regular Investment Methods
    
    /// 更新定期定額交易紀錄
    mutating func updateRegularInvestmentTransactions(stockService: LocalStockService) async {
        guard var regularInvestment = self.regularInvestment,
              regularInvestment.isActive else {
            return
        }
        
        // 獲取所有投資日期
        let investmentDates = regularInvestment.calculateInvestmentDates()
        var transactions = regularInvestment.transactions ?? []
        
        // 添加新的交易記錄
        for date in investmentDates {
            // 如果此日期還沒有交易紀錄，且日期不超過結束日期
            if !transactions.contains(where: { $0.date == date }),
               regularInvestment.endDate.map({ date <= $0 }) ?? true,
               let price = await stockService.getStockPrice(symbol: self.symbol, date: date) {
                let shares = Int(regularInvestment.amount / price)
                transactions.append(RegularInvestmentTransaction(
                    date: date,
                    amount: regularInvestment.amount,
                    shares: shares,
                    price: price,
                    isExecuted: date <= Date()
                ))
            }
        }
        
        // 排序交易紀錄，確保時間順序
        transactions.sort { $0.date < $1.date }
        
        // 更新定期定額的交易紀錄
        regularInvestment.transactions = transactions
        self.regularInvestment = regularInvestment
    }
    
    // MARK: - Equatable
    static func == (lhs: Stock, rhs: Stock) -> Bool {
        return lhs.id == rhs.id &&
               lhs.symbol == rhs.symbol &&
               lhs.bankId == rhs.bankId &&
               lhs.regularInvestment == rhs.regularInvestment
    }
    
    
}

// MARK: - 加權平均後的股票資訊結構
struct WeightedStockInfo: Identifiable {
    var id: String { "\(symbol)-\(isRegularInvestment ? "regular" : "normal")"  }
    let symbol: String
    let name: String
    let totalShares: Int
    let weightedDividendPerShare: Double
    let frequency: Int
    let details: [Stock]
    let isRegularInvestment: Bool
    
    /// 計算加權平均購買價格
    var weightedPurchasePrice: Double? {
        let stocksWithPrice = details.filter { $0.purchasePrice != nil }
        guard !stocksWithPrice.isEmpty else { return nil }
        
        let totalValue = stocksWithPrice.reduce(0.0) { sum, stock in
            sum + (stock.purchasePrice ?? 0) * Double(stock.shares)
        }
        let totalShares = stocksWithPrice.reduce(0) { $0 + $1.shares }
        return totalValue / Double(totalShares)
    }
    
    /// 計算總年化股利
    func calculateTotalAnnualDividend() -> Double {
        return Double(totalShares) * weightedDividendPerShare * Double(frequency)
    }
    
    /// 計算總市值
    func calculateTotalValue() -> Double? {
        guard let avgPrice = weightedPurchasePrice else { return nil }
        return Double(totalShares) * avgPrice
    }
}

// MARK: - Array Extensions
extension Array where Element == Stock {
    func calculateWeightedAverage(forBankId bankId: UUID? = nil) -> [WeightedStockInfo] {
        // 1. 過濾指定銀行的股票
        let filteredStocks = bankId != nil ? self.filter { $0.bankId == bankId } : self
        
        // 2. 分組股票（根據股票代號和投資類型）
        var stockGroups: [String: [Stock]] = [:]
        for stock in filteredStocks {
            let isRegular = stock.regularInvestment != nil
            let key = "\(stock.symbol)-\(isRegular ? "regular" : "normal")"
            stockGroups[key, default: []].append(stock)
        }
        
        // 3. 轉換成 WeightedStockInfo
        var result: [WeightedStockInfo] = []
        
        for stockGroup in stockGroups.values {
            guard let firstStock = stockGroup.first else { continue }
            
            // 計算總持股數
            let totalShares = stockGroup.reduce(0) { sum, stock in
                sum + stock.totalShares
            }
            
            // 計算加權平均股利
            let weightedDividend: Double
            if totalShares > 0 {
                let totalDividend = stockGroup.reduce(0.0) { sum, stock in
                    sum + (stock.dividendPerShare * Double(stock.totalShares))
                }
                weightedDividend = totalDividend / Double(totalShares)
            } else {
                weightedDividend = 0
            }
            
            // 創建 WeightedStockInfo
            let info = WeightedStockInfo(
                symbol: firstStock.symbol,
                name: firstStock.name,
                totalShares: totalShares,
                weightedDividendPerShare: weightedDividend,
                frequency: firstStock.frequency,
                details: stockGroup,
                isRegularInvestment: firstStock.regularInvestment != nil
            )
            
            result.append(info)
        }
        
        // 4. 根據股票代號排序並返回
        return result.sorted { $0.symbol < $1.symbol }
    }
}
