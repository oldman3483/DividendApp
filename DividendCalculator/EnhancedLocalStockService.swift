//
//  EnhancedLocalStockService.swift
//  DividendCalculator
//
//  Created on 2025/3/6.
//

import Foundation

/// 增強版的 LocalStockService
/// 整合本地資料和 API 數據
class EnhancedLocalStockService {
    // MARK: - 單例模式
    static let shared = EnhancedLocalStockService()
    
    // 原始本地服務
    private let localService = LocalStockService()
    
    // 資料倉庫
    private let repository = StockRepository.shared
    
    private init() {}
    
    // MARK: - 公開方法
    
    /// 搜尋股票
    func searchStocks(query: String) async -> [SearchStock] {
        return await repository.searchStocks(query: query)
    }
    
    /// 獲取股票名稱
    func getTaiwanStockInfo(symbol: String) async -> String? {
        let info = await repository.getStockInfo(symbol: symbol)
        return info.name
    }
    
    /// 獲取股利資訊
    func getTaiwanStockDividend(symbol: String) async -> Double? {
        let info = await repository.getStockInfo(symbol: symbol)
        return info.dividendPerShare
    }
    
    /// 獲取股利頻率
    func getTaiwanStockFrequency(symbol: String) async -> Int? {
        let info = await repository.getStockInfo(symbol: symbol)
        return info.frequency
    }
    
    /// 獲取股票價格
    func getStockPrice(symbol: String, date: Date) async -> Double? {
        return await repository.getStockPrice(symbol: symbol, date: date)
    }
    
    /// 獲取 K 線圖數據
    func getKLineData(symbol: String, days: Int) async -> [KLineData] {
        return await repository.getStockPriceHistory(symbol: symbol, days: days)
    }
    
    /// 獲取股利歷史
    func getDividendHistory(symbol: String, years: Int = 3) async -> [DividendData] {
        return await repository.getDividendHistory(symbol: symbol, years: years)
    }
    
    /// 獲取股利發放時間表
    func getDividendSchedule(symbol: String) async -> [DividendData] {
        return await repository.getDividendSchedule(symbol: symbol)
    }
    
    /// 獲取產業列表
    func getIndustries() async -> [String] {
        return await repository.getIndustries()
    }
    
    /// 獲取產業內的股票
    func getStocksByIndustry(industry: String) async -> [SearchStock] {
        return await repository.getStocksByIndustry(industry: industry)
    }
    
    /// 更新定期定額股票的交易數據
    func updateRegularInvestmentTransactions(stock: inout Stock) async {
        // 保留原有的更新邏輯，但使用新的資料來源
        guard var regularInvestment = stock.regularInvestment,
              regularInvestment.isActive else {
            print("定期定額未啟用或不存在")
            return
        }
        
        // 獲取所有投資日期
        let investmentDates = regularInvestment.calculateInvestmentDates()
        
        // 計算交易紀錄
        var transactions: [RegularInvestmentTransaction] = regularInvestment.transactions ?? []
        
        for date in investmentDates {
            // 檢查此日期是否已經有交易紀錄
            let existingTransaction = transactions.first { $0.date == date }
            
            // 如果這個日期還沒有交易紀錄，且日期不超過結束日期（如果有設定的話）
            if existingTransaction == nil,
               regularInvestment.endDate.map({ date <= $0 }) ?? true,
               let price = await repository.getStockPrice(symbol: stock.symbol, date: date) {
                let shares = Int(regularInvestment.amount / price)
                let transaction = RegularInvestmentTransaction(
                    date: date,
                    amount: regularInvestment.amount,
                    shares: shares,
                    price: price,
                    isExecuted: date <= Date()
                )
                transactions.append(transaction)
            }
        }
        
        // 排序交易紀錄，確保時間順序
        transactions.sort { $0.date < $1.date }
        
        // 更新定期定額的交易紀錄
        regularInvestment.transactions = transactions
        stock.regularInvestment = regularInvestment
    }
}
