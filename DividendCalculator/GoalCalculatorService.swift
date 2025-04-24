//
//  GoalCalculatorService.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/4/24.
//

import Foundation

class GoalCalculatorService {
    // 模擬過去10年平均年化報酬率
    private let historicalReturns: [String: Double] = [
        "0050": 0.09, // 9% 年化報酬率
        "2330": 0.15  // 15% 年化報酬率
    ]
    
    // 獲取特定股票歷史報酬率
    func getHistoricalReturn(for symbol: String) -> Double {
        return historicalReturns[symbol] ?? 0.08 // 默認8%
    }
    
    // 計算達到目標所需的每期投入金額
    func calculateRequiredInvestment(symbol: String, goalAmount: Double, years: Int, paymentsPerYear: Int) -> Double {
        let r = getHistoricalReturn(for: symbol)
        let n = paymentsPerYear
        let t = years
        let totalPayments = n * t
        let ratePerPeriod = r / Double(n)
        
        // 使用未來值公式的逆運算來計算每期所需投入
        // FV = PMT * ((1 + r)^n - 1) / r
        // 因此 PMT = FV * r / ((1 + r)^n - 1)
        let compoundFactor = pow(1 + ratePerPeriod, Double(totalPayments))
        let periodicPayment = goalAmount * ratePerPeriod / (compoundFactor - 1)
        
        return periodicPayment
    }
    
    // 計算投資增長預測
    func generateGrowthProjection(symbol: String, periodicAmount: Double, years: Int, paymentsPerYear: Int) -> [GrowthPoint] {
        let r = getHistoricalReturn(for: symbol)
        let ratePerPeriod = r / Double(paymentsPerYear)
        let totalPeriods = years * paymentsPerYear
        
        var projection: [GrowthPoint] = []
        var currentAmount: Double = 0
        
        for period in 0...totalPeriods {
            // 計算該期間結束時的總金額
            if period > 0 {
                // 先計算前一期本金加上收益
                currentAmount = currentAmount * (1 + ratePerPeriod)
                // 再加上本期投入金額
                if period < totalPeriods {
                    currentAmount += periodicAmount
                }
            }
            
            let timePoint = Double(period) / Double(paymentsPerYear)
            projection.append(GrowthPoint(
                year: timePoint,
                amount: currentAmount,
                principal: min(Double(period) * periodicAmount, Double(totalPeriods) * periodicAmount)
            ))
        }
        
        return projection
    }
}

// 增長數據點模型
struct GrowthPoint: Identifiable {
    let id = UUID()
    let year: Double      // 年份（可以是小數，如0.25表示第1年的第1季）
    let amount: Double    // 總金額
    let principal: Double // 本金部分
}
