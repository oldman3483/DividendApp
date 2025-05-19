////
////  StockValueService.swift
////  DividendCalculator
////
////  Created on 2025/5/15.
//// 股票價值計算的基礎邏輯
//
//import Foundation
//
///// 股票市值計算服務 - 提供統一的市值計算方式
//class StockValueService {
//    // MARK: - 單例模式
//    static let shared = StockValueService()
//    
//    private let stockService = LocalStockService()
//    private let priceCache = StockPriceCache.shared
//    
//    private init() {}
//    
//    // MARK: - 公開方法
//    
//    /// 計算股票總市值
//    /// - Parameters:
//    ///   - stocks: 要計算的股票列表
//    ///   - currentPrices: 可選的當前價格字典，如果提供將優先使用
//    ///   - date: 計算市值的日期，默認為今天
//    /// - Returns: 計算得到的總市值
//    func calculateTotalValue(for stocks: [Stock], currentPrices: [String: Double]? = nil, date: Date = Date()) async -> Double {
//        // 如果提供了價格字典，優先使用提供的價格
//        let prices: [String: Double]
//        if let providedPrices = currentPrices {
//            prices = providedPrices
//        } else {
//            prices = await getCurrentPrices(for: stocks, on: date)
//        }
//        
//        return stocks.reduce(0) { total, stock in
//            guard let currentPrice = prices[stock.symbol] else { return total }
//            
//            // 一般持股市值
//            let normalValue = Double(stock.shares) * currentPrice
//            
//            // 定期定額市值（已執行的交易）
//            let regularValue = stock.regularInvestment?.transactions?
//                .filter { $0.isExecuted && $0.date <= date }
//                .reduce(0) { sum, transaction in
//                    sum + (Double(transaction.shares) * currentPrice)
//                } ?? 0
//                    
//            return total + normalValue + regularValue
//        }
//    }
//    
//    /// 計算特定銀行的股票總市值
//    /// - Parameters:
//    ///   - stocks: 所有股票列表
//    ///   - bankId: 銀行ID
//    ///   - currentPrices: 可選的當前價格字典
//    ///   - date: 計算市值的日期，默認為今天
//    /// - Returns: 該銀行的股票總市值
//    func calculateBankTotalValue(stocks: [Stock], bankId: UUID, currentPrices: [String: Double]? = nil, date: Date = Date()) async -> Double {
//        let bankStocks = stocks.filter { $0.bankId == bankId }
//        return await calculateTotalValue(for: bankStocks, currentPrices: currentPrices, date: date)
//    }
//    
//    /// 計算股票投資總成本
//    /// - Parameters:
//    ///   - stocks: 要計算的股票列表
//    ///   - date: 截止日期，只計算該日期前的交易，默認為今天
//    /// - Returns: 總投資成本
//    func calculateTotalInvestment(for stocks: [Stock], before date: Date = Date()) -> Double {
//        stocks.reduce(0) { total, stock in
//            // 一般持股成本
//            let normalCost = Double(stock.shares) * (stock.purchasePrice ?? 0)
//            
//            // 定期定額成本（已執行的交易）
//            let regularCost = stock.regularInvestment?.transactions?
//                .filter { $0.isExecuted && $0.date <= date }
//                .reduce(0) { sum, transaction in
//                    sum + transaction.amount
//                } ?? 0
//                
//            return total + normalCost + regularCost
//        }
//    }
//    
//    /// 計算股票投資報酬率
//    /// - Parameters:
//    ///   - stocks: 要計算的股票列表
//    ///   - currentPrices: 可選的當前價格字典
//    ///   - date: 計算報酬率的日期，默認為今天
//    /// - Returns: 投資報酬率（百分比）
//    func calculateROI(for stocks: [Stock], currentPrices: [String: Double]? = nil, date: Date = Date()) async -> Double {
//        let totalValue = await calculateTotalValue(for: stocks, currentPrices: currentPrices, date: date)
//        let totalInvestment = calculateTotalInvestment(for: stocks, before: date)
//        
//        return totalInvestment > 0 ? ((totalValue - totalInvestment) / totalInvestment) * 100 : 0
//    }
//    
//    /// 計算股票總年化股利
//    /// - Parameters:
//    ///   - stocks: 要計算的股票列表
//    ///   - date: 截止日期，只計算該日期前的交易，默認為今天
//    /// - Returns: 總年化股利
//    func calculateAnnualDividend(for stocks: [Stock], before date: Date = Date()) -> Double {
//        stocks.reduce(0) { total, stock in
//            // 一般持股的年化股利
//            let normalDividend = Double(stock.shares) * stock.dividendPerShare * Double(stock.frequency)
//            
//            // 定期定額的年化股利（已執行的交易）
//            let regularShares = stock.regularInvestment?.transactions?
//                .filter { $0.isExecuted && $0.date <= date }
//                .reduce(0) { sum, transaction in
//                    sum + transaction.shares
//                } ?? 0
//            let regularDividend = Double(regularShares) * stock.dividendPerShare * Double(stock.frequency)
//            
//            return total + normalDividend + regularDividend
//        }
//    }
//    
//    /// 計算股票股利殖利率
//    /// - Parameters:
//    ///   - stocks: 要計算的股票列表
//    ///   - currentPrices: 可選的當前價格字典
//    ///   - date: 計算殖利率的日期，默認為今天
//    /// - Returns: 股利殖利率（百分比）
//    func calculateDividendYield(for stocks: [Stock], currentPrices: [String: Double]? = nil, date: Date = Date()) async -> Double {
//        let totalValue = await calculateTotalValue(for: stocks, currentPrices: currentPrices, date: date)
//        let annualDividend = calculateAnnualDividend(for: stocks, before: date)
//        
//        return totalValue > 0 ? (annualDividend / totalValue) * 100 : 0
//    }
//}
