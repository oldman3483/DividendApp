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
    
  
    /// 將 API 的股利歷史數據轉換為自定義 DividendData 模型
    static func mapToDividendData(from dividendHistory: [DividendHistory]) -> [DividendData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return dividendHistory.compactMap { history in
            guard let date = dateFormatter.date(from: history.date),
                  let exDate = dateFormatter.date(from: history.exDividendDate),
                  let payDate = dateFormatter.date(from: history.paymentDate) else {
                return nil
            }
            
            return DividendData(
                id: UUID(),
                date: date,
                amount: history.amount,
                exDividendDate: exDate,
                paymentDate: payDate
            )
        }
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
