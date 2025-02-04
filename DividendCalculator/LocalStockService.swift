//
//  LocalStockService.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/21.
//

import SwiftUI


class LocalStockService {
    // 模擬資料庫
    private let mockStocks = [
        ("2330", "台積電", 2.75, 4, 550.0),  // 加入預設股價
        ("2317", "鴻海", 5.0, 1, 120.0),
        ("2454", "聯發科", 3.0, 4, 850.0),
        ("2412", "中華電", 4.5, 4, 120.0),
        ("2308", "台達電", 3.5, 4, 290.0),
        ("2881", "富邦金", 3.0, 2, 75.0),
        ("2882", "國泰金", 2.5, 2, 45.0),
        ("1301", "台塑", 4.0, 1, 110.0),
        ("1303", "南亞", 3.2, 1, 85.0),
        ("2891", "中信金", 2.8, 2, 25.0)
    ]
    
    // 搜尋股票
    func searchStocks(query: String) async -> [SearchStock] {
        // 模糊搜尋
        return mockStocks
            .filter { stockInfo in
                let (symbol, name, _, _, _) = stockInfo
                return symbol.lowercased().contains(query.lowercased()) ||
                       name.lowercased().contains(query.lowercased())
            }
            .map { SearchStock(symbol: $0.0, name: $0.1) }
    }
    
    
   
    // 取得股票資訊
    func getTaiwanStockInfo(symbol: String) async -> String? {
        return mockStocks.first { $0.0 == symbol }?.1
    }
    
    // 取得股利資訊
    func getTaiwanStockDividend(symbol: String) async -> Double? {
        return mockStocks.first { $0.0 == symbol }?.2
    }
    // 獲取股利頻率
    func getTaiwanStockFrequency(symbol: String) async -> Int? {
        return mockStocks.first { $0.0 == symbol }?.3
    }
    // 取得指定日期的收盤價
    func getStockPrice(symbol: String, date: Date) async -> Double? {
        return mockStocks.first { $0.0 == symbol }?.4
    }
}
