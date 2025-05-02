//
//  SQLDataProcessor.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/5/3.
//

import Foundation

// MARK: - SQL 資料處理服務
class SQLDataProcessor {
    static let shared = SQLDataProcessor()
    
    private init() {}
    
    /// 處理從資料庫返回的股利資料
    func processDividendData(_ records: [DividendRecord]) -> [ProcessedDividendData] {
        return records.compactMap { record -> ProcessedDividendData? in
            // 處理日期格式
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "'yy/MM/dd"
            
            let exDividendDate = dateFormatter.date(from: record.ex_dividend_date)
            let distributionDate = record.cash_dividend_distribution_date.flatMap { dateFormatter.date(from: $0) }
            
            // 處理數值，確保沒有 nan 或 null
            let exDividendPrice = record.ex_dividend_reference_price ?? 0.0
            let cashDividend = record.cash_dividend_earnings ?? 0.0
            let capitalSurplusDividend = record.cash_dividend_capital_surplus ?? 0.0
            let totalCashDividend = record.total_cash_dividend
            
            // 處理文本內容，確保沒有空值
            let dividendPeriod = record.dividend_period.isEmpty ? "未指定" : record.dividend_period
            
            // 返回處理後的資料
            return ProcessedDividendData(
                id: UUID(),
                symbol: record.stock_symbol,
                dividendYear: record.dividend_year,
                dividendPeriod: dividendPeriod,
                exDividendDate: exDividendDate,
                distributionDate: distributionDate,
                exDividendPrice: exDividendPrice,
                cashDividend: cashDividend,
                capitalSurplusDividend: capitalSurplusDividend,
                totalCashDividend: totalCashDividend
            )
        }
    }
    
    /// 從股利歷史資料中計算股利頻率
    func calculateDividendFrequency(from records: [DividendRecord]) -> Int {
        // 按年份分組
        var recordsByYear: [String: [DividendRecord]] = [:]
        
        for record in records {
            if recordsByYear[record.dividend_year] == nil {
                recordsByYear[record.dividend_year] = []
            }
            recordsByYear[record.dividend_year]?.append(record)
        }
        
        // 計算最近三年的平均發放次數
        var totalCount = 0
        var yearCount = 0
        
        // 獲取三年的年份列表
        let years = recordsByYear.keys.sorted(by: >).prefix(3)
        
        for year in years {
            if let yearRecords = recordsByYear[year] {
                totalCount += yearRecords.count
                yearCount += 1
            }
        }
        
        // 計算平均每年發放次數
        let averageCount = yearCount > 0 ? Double(totalCount) / Double(yearCount) : 0
        
        // 根據平均發放次數決定頻率
        if averageCount >= 3.5 {
            return 4 // 季配
        } else if averageCount >= 1.5 {
            return 2 // 半年配
        } else {
            return 1 // 年配
        }
    }
    
    /// 從股利歷史資料中計算最新的每股股利
    func calculateDividendPerShare(from records: [DividendRecord]) -> Double {
        // 獲取最近年度的記錄
        let latestYear = records.compactMap { Int($0.dividend_year) }.max() ?? 0
        
        // 過濾出最近年度的記錄
        let latestRecords = records.filter {
            Int($0.dividend_year) ?? 0 == latestYear
        }
        
        // 計算最近年度的總股利
        var totalDividend: Double = 0
        for record in latestRecords {
            totalDividend += record.total_cash_dividend
        }
        
        return totalDividend
    }
}

// 處理後的股利資料模型
struct ProcessedDividendData: Identifiable {
    let id: UUID
    let symbol: String
    let dividendYear: String
    let dividendPeriod: String
    let exDividendDate: Date?
    let distributionDate: Date?
    let exDividendPrice: Double
    let cashDividend: Double
    let capitalSurplusDividend: Double
    let totalCashDividend: Double
}
