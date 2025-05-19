//
//  PortfolioManager.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/5/16.
//  銀行和投資組合管理的高層邏輯

import Foundation

/// 投資組合管理器 - 整合銀行、股票及相關計算
class PortfolioManager {
    // MARK: - 單例模式
    static let shared = PortfolioManager()
    
    // 依賴的服務
//    private let stockValueService = StockValueService.shared
    private let stockService = LocalStockService()
    
    private init() {}
    
    // MARK: - 投資組合查詢方法
    
    /// 獲取特定銀行的所有股票
    /// - Parameter bankId: 銀行ID
    /// - Parameter stocks: 所有股票
    /// - Returns: 該銀行的股票
    func getStocksForBank(bankId: UUID, allStocks: [Stock]) -> [Stock] {
        return allStocks.filter { $0.bankId == bankId }
    }
    
    /// 獲取特定銀行的定期定額投資
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: 該銀行的定期定額投資
    func getRegularInvestmentsForBank(bankId: UUID, allStocks: [Stock]) -> [Stock] {
        return allStocks.filter { $0.bankId == bankId && $0.regularInvestment != nil }
    }
    
    /// 獲取特定銀行的一般持股
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: 該銀行的一般持股
    func getNormalStocksForBank(bankId: UUID, allStocks: [Stock]) -> [Stock] {
        return allStocks.filter { $0.bankId == bankId && $0.regularInvestment == nil }
    }
    
    /// 獲取特定銀行特定股票的所有持股
    /// - Parameters:
    ///   - symbol: 股票代號
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: 該銀行的特定股票持股
    func getStocksForSymbol(symbol: String, bankId: UUID, allStocks: [Stock]) -> [Stock] {
        return allStocks.filter { $0.symbol == symbol && $0.bankId == bankId }
    }
    
    // MARK: - 投資組合計算方法
    
    /// 計算股票總市值
    /// - Parameters:
    ///   - stocks: 要計算的股票列表
    ///   - currentPrices: 可選的當前價格字典，如果提供將優先使用
    ///   - date: 計算市值的日期，默認為今天
    /// - Returns: 計算得到的總市值
    func calculateTotalValue(for stocks: [Stock], currentPrices: [String: Double]? = nil, date: Date = Date()) async -> Double {
        // 如果提供了價格字典，優先使用提供的價格
        let prices: [String: Double]
        if let providedPrices = currentPrices {
            prices = providedPrices
        } else {
            prices = await getCurrentPrices(for: stocks, on: date)
        }
        
        return stocks.reduce(0) { total, stock in
            guard let currentPrice = prices[stock.symbol] else { return total }
            
            // 一般持股市值
            let normalValue = Double(stock.shares) * currentPrice
            
            // 定期定額市值（已執行的交易）
            let regularValue = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted && $0.date <= date }
                .reduce(0) { sum, transaction in
                    sum + (Double(transaction.shares) * currentPrice)
                } ?? 0
                    
            return total + normalValue + regularValue
        }
    }
    /// 計算特定銀行的股票總市值
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    ///   - currentPrices: 可選的當前價格字典
    ///   - date: 計算市值的日期，默認為今天
    /// - Returns: 該銀行的股票總市值
    func calculateBankTotalValue(bankId: UUID, allStocks: [Stock], currentPrices: [String: Double]? = nil, date: Date = Date()) async -> Double {
        let bankStocks = getStocksForBank(bankId: bankId, allStocks: allStocks)
        return await calculateTotalValue(for: bankStocks, currentPrices: currentPrices, date: date)
    }
    
    /// 計算股票投資總成本
    /// - Parameters:
    ///   - stocks: 要計算的股票列表
    ///   - date: 截止日期，只計算該日期前的交易，默認為今天
    /// - Returns: 總投資成本
    func calculateTotalInvestment(for stocks: [Stock], before date: Date = Date()) -> Double {
        stocks.reduce(0) { total, stock in
            // 一般持股成本
            let normalCost = Double(stock.shares) * (stock.purchasePrice ?? 0)
            
            // 定期定額成本（已執行的交易）
            let regularCost = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted && $0.date <= date }
                .reduce(0) { sum, transaction in
                    sum + transaction.amount
                } ?? 0
                
            return total + normalCost + regularCost
        }
    }
    
    /// 計算特定銀行的總投資成本
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: 該銀行的總投資成本
    func calculateBankTotalInvestment(bankId: UUID, allStocks: [Stock]) -> Double {
        let bankStocks = getStocksForBank(bankId: bankId, allStocks: allStocks)
        return calculateTotalInvestment(for: bankStocks)
    }
    
    
    
    /// 計算股票總年化股利
    /// - Parameters:
    ///   - stocks: 要計算的股票列表
    ///   - date: 截止日期，只計算該日期前的交易，默認為今天
    /// - Returns: 總年化股利
    func calculateAnnualDividend(for stocks: [Stock], before date: Date = Date()) -> Double {
        stocks.reduce(0) { total, stock in
            // 一般持股的年化股利
            let normalDividend = Double(stock.shares) * stock.dividendPerShare * Double(stock.frequency)
            
            // 定期定額的年化股利（已執行的交易）
            let regularShares = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted && $0.date <= date }
                .reduce(0) { sum, transaction in
                    sum + transaction.shares
                } ?? 0
            let regularDividend = Double(regularShares) * stock.dividendPerShare * Double(stock.frequency)
            
            return total + normalDividend + regularDividend
        }
    }
    /// 計算特定銀行的年化股利
        /// - Parameters:
        ///   - bankId: 銀行ID
        ///   - allStocks: 所有股票
        /// - Returns: 該銀行的年化股利
        func calculateBankAnnualDividend(bankId: UUID, allStocks: [Stock]) -> Double {
            let bankStocks = getStocksForBank(bankId: bankId, allStocks: allStocks)
            return calculateAnnualDividend(for: bankStocks)
        }
    /// 計算銀行股利殖利率
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: 股利殖利率（百分比）
    func calculateBankDividendYield(bankId: UUID, allStocks: [Stock]) async -> Double {
        let bankStocks = getStocksForBank(bankId: bankId, allStocks: allStocks)
        
        // 使用本地方法獲取總市值
        let totalValue = await calculateTotalValue(for: bankStocks)
        
        // 使用本地方法獲取年化股利
        let annualDividend = calculateAnnualDividend(for: bankStocks)
        
        // 計算股利殖利率
        return totalValue > 0 ? (annualDividend / totalValue) * 100 : 0
    }
    
    /// 計算銀行投資報酬率
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: 投資報酬率（百分比）
    func calculateBankROI(bankId: UUID, allStocks: [Stock]) async -> Double {
        let bankStocks = getStocksForBank(bankId: bankId, allStocks: allStocks)
        
        // 使用本地方法獲取總市值
        let totalValue = await calculateTotalValue(for: bankStocks)
        
        // 使用本地方法獲取總投資成本
        let totalInvestment = calculateTotalInvestment(for: bankStocks)
        
        // 計算總報酬
        let totalProfitLoss = totalValue - totalInvestment
        
        // 計算報酬率
        return totalInvestment > 0 ? (totalProfitLoss / totalInvestment) * 100 : 0
    }
    
    /// 計算投資組合的總體報酬率
    /// - Parameters:
    ///   - stocks: 要計算的股票列表
    ///   - currentPrices: 當前價格字典
    /// - Returns: 總投資報酬率（百分比）
    func calculateTotalROI(for stocks: [Stock], currentPrices: [String: Double]? = nil) async -> Double {
        // 使用本地方法獲取總市值
        let totalValue = await calculateTotalValue(for: stocks, currentPrices: currentPrices)
        
        // 使用本地方法獲取總投資成本
        let totalInvestment = calculateTotalInvestment(for: stocks)
        
        // 計算總報酬
        let totalProfitLoss = totalValue - totalInvestment
        
        // 計算報酬率
        return totalInvestment > 0 ? (totalProfitLoss / totalInvestment) * 100 : 0
    }
    
    /// 計算銀行當日損益及漲跌幅
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: (損益金額, 漲跌幅百分比)
    func calculateBankDailyChange(bankId: UUID, allStocks: [Stock]) async -> (change: Double, percentage: Double) {
        let bankStocks = getStocksForBank(bankId: bankId, allStocks: allStocks)
        let currentPrices = await getCurrentPrices(for: bankStocks)
        let previousPrices = await getPreviousDayPrices(for: bankStocks)
        
        // 使用本地方法
        return calculateDailyChange(
            for: bankStocks,
            currentPrices: currentPrices,
            previousPrices: previousPrices
        )
    }
    
    /// 獲取銀行所有股票的彙總統計
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: 銀行投資組合指標
    func getBankPortfolioMetrics(bankId: UUID, allStocks: [Stock]) async -> BankPortfolioMetrics {
        let bankStocks = getStocksForBank(bankId: bankId, allStocks: allStocks)
        
        let currentPrices = await getCurrentPrices(for: bankStocks)
        let previousPrices = await getPreviousDayPrices(for: bankStocks)
        
        // 計算總市值 - 使用本地計算方法
        let totalValue = await calculateTotalValue(for: bankStocks, currentPrices: currentPrices)
        
        // 計算總投資成本
        let totalInvestment = calculateTotalInvestment(for: bankStocks)
        
        // 計算年化股利
        let annualDividend = calculateAnnualDividend(for: bankStocks)
        
        // 計算當日損益和漲跌幅 - 使用本地計算方法
        let (dailyChange, dailyChangePercentage) = calculateDailyChange(
            for: bankStocks,
            currentPrices: currentPrices,
            previousPrices: previousPrices
        )
        
        // 計算總報酬和報酬率
        let totalProfitLoss = totalValue - totalInvestment
        let totalROI = totalInvestment > 0 ? (totalProfitLoss / totalInvestment) * 100 : 0
        
        // 計算股利率
        let dividendYield = totalValue > 0 ? (annualDividend / totalValue) * 100 : 0
        
        // 計算股票數量
        let stockCount = Set(bankStocks.map { $0.symbol }).count
        let regularInvestmentCount = getRegularInvestmentsForBank(bankId: bankId, allStocks: allStocks).count
        let normalStockCount = getNormalStocksForBank(bankId: bankId, allStocks: allStocks).count
        
        return BankPortfolioMetrics(
            totalValue: totalValue,
            totalInvestment: totalInvestment,
            totalProfitLoss: totalProfitLoss,
            totalROI: totalROI,
            annualDividend: annualDividend,
            dividendYield: dividendYield,
            dailyChange: dailyChange,
            dailyChangePercentage: dailyChangePercentage,
            stockCount: stockCount,
            regularInvestmentCount: regularInvestmentCount,
            normalStockCount: normalStockCount
        )
    }
    
    // MARK: - 股票處理方法
    
    /// 更新定期定額股票的交易記錄
    /// - Parameters:
    ///   - stock: 待更新的股票
    /// - Returns: 更新後的股票
    func updateRegularInvestmentTransactions(stock: Stock) async -> Stock {
        var updatedStock = stock
        await updatedStock.updateRegularInvestmentTransactions(stockService: stockService)
        return updatedStock
    }
    
    /// 將股票加權平均處理
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: 加權平均後的股票信息
    func getWeightedStockInfo(bankId: UUID, allStocks: [Stock]) -> [WeightedStockInfo] {
        let bankStocks = getStocksForBank(bankId: bankId, allStocks: allStocks)
        return bankStocks.calculateWeightedAverage(forBankId: bankId)
    }
    
    /// 獲取一般持股的加權平均
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: 加權平均後的一般持股
    func getWeightedNormalStocks(bankId: UUID, allStocks: [Stock]) -> [WeightedStockInfo] {
        let normalStocks = getNormalStocksForBank(bankId: bankId, allStocks: allStocks)
        return normalStocks.calculateWeightedAverage(forBankId: bankId)
    }
    
    /// 獲取定期定額的加權平均
    /// - Parameters:
    ///   - bankId: 銀行ID
    ///   - allStocks: 所有股票
    /// - Returns: 加權平均後的定期定額
    func getWeightedRegularInvestments(bankId: UUID, allStocks: [Stock]) -> [WeightedStockInfo] {
        let regularInvestments = getRegularInvestmentsForBank(bankId: bankId, allStocks: allStocks)
        return regularInvestments.calculateWeightedAverage(forBankId: bankId)
    }
    /// 獲取多個銀行的彙總投資指標
    /// - Parameters:
    ///   - bankIds: 銀行ID列表
    ///   - allStocks: 所有股票
    /// - Returns: 彙總投資指標
    func getMultiBanksPortfolioMetrics(banks: [Bank], allStocks: [Stock]) async -> BankPortfolioMetrics {
        var totalValue: Double = 0
        var totalInvestment: Double = 0
        var annualDividend: Double = 0
        var dailyChange: Double = 0
        var stockCount: Int = 0
        var regularInvestmentCount: Int = 0
        var normalStockCount: Int = 0
        
        // 計算所有銀行的合計指標
        for bank in banks {
            let bankMetrics = await getBankPortfolioMetrics(bankId: bank.id, allStocks: allStocks)
            
            totalValue += bankMetrics.totalValue
            totalInvestment += bankMetrics.totalInvestment
            annualDividend += bankMetrics.annualDividend
            dailyChange += bankMetrics.dailyChange
            stockCount += bankMetrics.stockCount
            regularInvestmentCount += bankMetrics.regularInvestmentCount
            normalStockCount += bankMetrics.normalStockCount
        }
        
        // 計算其他指標
        let totalProfitLoss = totalValue - totalInvestment
        let totalROI = totalInvestment > 0 ? (totalProfitLoss / totalInvestment) * 100 : 0
        let dailyChangePercentage = totalValue > 0 ? (dailyChange / totalValue) * 100 : 0
        let dividendYield = totalValue > 0 ? (annualDividend / totalValue) * 100 : 0
        
        return BankPortfolioMetrics(
            totalValue: totalValue,
            totalInvestment: totalInvestment,
            totalProfitLoss: totalProfitLoss,
            totalROI: totalROI,
            annualDividend: annualDividend,
            dividendYield: dividendYield,
            dailyChange: dailyChange,
            dailyChangePercentage: dailyChangePercentage,
            stockCount: stockCount,
            regularInvestmentCount: regularInvestmentCount,
            normalStockCount: normalStockCount
        )
    }
    
    // MARK: - 股票價格方法

    /// 獲取股票當前價格
    /// - Parameters:
    ///   - stocks: 需要獲取價格的股票列表
    ///   - date: 指定日期，默認為今天
    /// - Returns: 股票代號到價格的映射字典
    func getCurrentPrices(for stocks: [Stock], on date: Date = Date()) async -> [String: Double] {
        var prices: [String: Double] = [:]
        
        // 使用股票服務取得價格
        for stock in stocks {
            if let price = await stockService.getStockPrice(symbol: stock.symbol, date: date) {
                prices[stock.symbol] = price
            }
        }
        
        return prices
    }

    /// 獲取前一日股價
    /// - Parameter stocks: 需要獲取價格的股票列表
    /// - Parameter currentDate: 當前日期，默認為今天
    /// - Returns: 股票代號到價格的映射字典
    func getPreviousDayPrices(for stocks: [Stock], currentDate: Date = Date()) async -> [String: Double] {
        let calendar = Calendar.current
        guard let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
            return [:]
        }
        
        return await getCurrentPrices(for: stocks, on: yesterdayDate)
    }
    
    /// 計算當日損益及漲跌幅
    /// - Parameters:
    ///   - stocks: 要計算的股票列表
    ///   - currentPrices: 當日價格
    ///   - previousPrices: 前一日價格
    /// - Returns: (損益金額, 漲跌幅百分比)
    func calculateDailyChange(for stocks: [Stock], currentPrices: [String: Double], previousPrices: [String: Double]) -> (change: Double, percentage: Double) {
        // 計算當日損益
        let dailyChange = stocks.reduce(0) { totalChange, stock in
            // 計算總持股數（一般持股 + 已執行的定期定額）
            let normalShares = stock.shares
            let regularShares = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { $0 + $1.shares } ?? 0
            let totalShares = normalShares + regularShares
            
            // 取得價格
            guard let previousPrice = previousPrices[stock.symbol],
                  let currentPrice = currentPrices[stock.symbol] else {
                return totalChange
            }
            
            // 計算這支股票的當日損益
            return totalChange + ((currentPrice - previousPrice) * Double(totalShares))
        }
        
        // 計算前一日總市值（用於計算漲跌幅）
        let previousTotalValue = stocks.reduce(0) { total, stock in
            let totalShares = stock.shares + (stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { $0 + $1.shares } ?? 0)
            let previousPrice = previousPrices[stock.symbol] ?? 0
            return total + (Double(totalShares) * previousPrice)
        }
        
        // 計算漲跌幅
        let percentage = previousTotalValue > 0 ? (dailyChange / previousTotalValue) * 100 : 0
        
        return (dailyChange, percentage)
    }
    
    //使用 CustomRangeMetricsService 處理特定日期範圍
    func getMetricsForDateRange(startDate: Date, endDate: Date, stocks: [Stock]) async -> InvestmentMetrics {
        let metricsService = CustomRangeMetricsService(stocks: stocks, stockService: stockService)
        return await metricsService.calculateMetrics(startDate: startDate, endDate: endDate)
    }
}

/// 銀行投資組合指標結構
struct BankPortfolioMetrics {
    let totalValue: Double
    let totalInvestment: Double
    let totalProfitLoss: Double
    let totalROI: Double
    let annualDividend: Double
    let dividendYield: Double
    let dailyChange: Double
    let dailyChangePercentage: Double
    
    var stockCount: Int
    var regularInvestmentCount: Int
    var normalStockCount: Int
}
