//
//  FinMindService.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/21.
//

import Foundation

class FinMindService {
    // 模擬資料庫
    private let mockStocks = [
        ("2330", "台積電", 2.75),
        ("2317", "鴻海", 5.0),
        ("2454", "聯發科", 3.0),
        ("2412", "中華電", 4.5),
        ("2308", "台達電", 3.5),
        ("2881", "富邦金", 3.0),
        ("2882", "國泰金", 2.5),
        ("1301", "台塑", 4.0),
        ("1303", "南亞", 3.2),
        ("2891", "中信金", 2.8)
    ]
    
    // 搜尋股票
    func searchStocks(query: String) async -> [SearchStock] {
        // 模糊搜尋
        return mockStocks
            .filter { stockInfo in
                let (symbol, name, _) = stockInfo
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
}
