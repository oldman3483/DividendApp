//
//  DataMapper.swift
//  DividendCalculator
//
//  Created on 2025/3/6.
//

import Foundation

class DataMapper {
    /// 從 API 响應轉換為 Stock 模型
    static func mapToStock(from apiStock: StockInfoResponse, bankId: UUID) -> Stock {
        let id = UUID()
        let purchaseDate = Date() // 預設為當前日期
        let dividendYear = Calendar.current.component(.year, from: Date())
        
        return Stock(
            id: id,
            symbol: apiStock.symbol,
            name: apiStock.name,
            shares: 0, // 預設為 0，需要用戶輸入
            dividendPerShare: apiStock.dividendPerShare,
            dividendYear: dividendYear,
            isHistorical: false,
            frequency: apiStock.frequency,
            purchaseDate: purchaseDate,
            purchasePrice: apiStock.currentPrice,
            bankId: bankId
        )
    }
    
    /// 從 API 響應轉換為 WatchStock 模型
    static func mapToWatchStock(from apiStock: StockInfoResponse, listName: String) -> WatchStock {
        return WatchStock(
            id: UUID(),
            symbol: apiStock.symbol,
            name: apiStock.name,
            addedDate: Date(),
            listName: listName
        )
    }
    
    /// 將資料庫的股利歷史數據轉換為自定義 DividendData 模型
    static func mapToDividendData(from dividendRecords: [DividendRecord]) -> [DividendData] {
        return dividendRecords.compactMap { record -> DividendData? in
            guard let exDate = record.exDividendDateObj else { return nil }
            
            // 獲取發放日期，如果沒有則使用除息日加上30天
            let payDate: Date
            if let distributionDate = record.distributionDateObj {
                payDate = distributionDate
            } else {
                payDate = Calendar.current.date(byAdding: .day, value: 30, to: exDate) ?? exDate
            }
            
            return DividendData(
                id: UUID(),
                date: exDate, // 使用除息日作為主要日期
                amount: record.totalCashDividend, // 使用現金股利總額
                exDividendDate: exDate,
                paymentDate: payDate
            )
        }
    }
    
    /// 將資料庫的股利數據轉換為股利發放時間表
    static func mapToDividendSchedule(from dividendRecords: [DividendRecord]) -> [DividendData] {
        let currentDate = Date()
        
        return dividendRecords.compactMap { record -> DividendData? in
            guard let exDate = record.exDividendDateObj,
                  let distributionDate = record.distributionDateObj,
                  distributionDate > currentDate else {
                return nil
            }
            
            return DividendData(
                id: UUID(),
                date: exDate,
                amount: record.totalCashDividend,
                exDividendDate: exDate,
                paymentDate: distributionDate
            )
        }.sorted { $0.paymentDate < $1.paymentDate }
    }
    
    /// 從資料庫中獲取的股利數據計算股利發放頻率
    static func calculateDividendFrequency(from records: [DividendRecord]) -> Int {
        // 按年份分組
        var recordsByYear: [String: [DividendRecord]] = [:]
        
        for record in records {
            if recordsByYear[record.dividendYear] == nil {
                recordsByYear[record.dividendYear] = []
            }
            recordsByYear[record.dividendYear]?.append(record)
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
    
    /// 從資料庫中獲取的股利數據計算每股股利
    static func calculateDividendPerShare(from records: [DividendRecord]) -> Double {
        // 獲取最近年度的記錄
        let latestYear = records.compactMap { Int($0.dividendYear) }.max() ?? 0
        
        // 過濾出最近年度的記錄
        let latestRecords = records.filter {
            Int($0.dividendYear) ?? 0 == latestYear
        }
        
        // 計算最近年度的總股利
        var totalDividend: Double = 0
        for record in latestRecords {
            totalDividend += record.totalCashDividend
        }
        
        return totalDividend
    }
}

/// 自定義股息數據模型，用於顯示股息歷史和預測
struct DividendData: Identifiable {
    let id: UUID
    let date: Date
    let amount: Double
    let exDividendDate: Date
    let paymentDate: Date
}
