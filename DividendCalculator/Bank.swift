//
//  Bank.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/31.
//


import Foundation

struct Bank: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var createdDate: Date
    
    init(id: UUID = UUID(), name: String, createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.createdDate = createdDate
    }
    
    static func == (lhs: Bank, rhs: Bank) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Bank {
    /// 獲取此銀行關聯的所有股票
    func getStocks(from allStocks: [Stock]) -> [Stock] {
        return allStocks.filter { $0.bankId == self.id }
    }
    
    /// 獲取此銀行的一般持股
    func getNormalStocks(from allStocks: [Stock]) -> [Stock] {
        return allStocks.filter { $0.bankId == self.id && $0.regularInvestment == nil }
    }
    
    /// 獲取此銀行的定期定額投資
    func getRegularInvestments(from allStocks: [Stock]) -> [Stock] {
        return allStocks.filter { $0.bankId == self.id && $0.regularInvestment != nil }
    }
    
    /// 獲取此銀行的投資組合指標
    func getPortfolioMetrics(allStocks: [Stock]) async -> BankPortfolioMetrics {
        return await PortfolioManager.shared.getBankPortfolioMetrics(
            bankId: id,
            allStocks: allStocks
        )
    }
    
    /// 計算銀行總市值
    func calculateBankTotalValue(allStocks: [Stock]) async -> Double {
        return await PortfolioManager.shared.calculateBankTotalValue(
            bankId: id,
            allStocks: allStocks
        )
    }
    
    /// 計算銀行總投資成本
    func calculateBankTotalInvestment(allStocks: [Stock]) -> Double {
        return PortfolioManager.shared.calculateBankTotalInvestment(
            bankId: id,
            allStocks: allStocks
        )
    }
    
    /// 計算銀行總年化股利
    func calculateAnnualDividend(allStocks: [Stock]) -> Double {
        return PortfolioManager.shared.calculateBankAnnualDividend(
            bankId: id,
            allStocks: allStocks
        )
    }
    
    /// 計算銀行當日損益和漲跌幅
    func calculateDailyChange(allStocks: [Stock]) async -> (change: Double, percentage: Double) {
        return await PortfolioManager.shared.calculateBankDailyChange(
            bankId: id,
            allStocks: allStocks
        )
    }
}
