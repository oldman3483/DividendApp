//
//  LocalStockService.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/21.
//

import SwiftUI

class LocalStockService {
    // 基本股票資訊
    private let mockStocks = [
        ("2330", "台積電", 2.75, 4, 550.0),
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
    
    // 模擬十天內的股價資料
    private let mockStockPrices: [String: [(Date, Double)]] = [
        "2330": [
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 548.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 552.0),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 547.0),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 551.0),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 553.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 549.0),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 550.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 554.0),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 551.0),
            (Date(), 550.0)
        ],
        "2317": [
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 118.5),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 119.0),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 118.0),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 120.5),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 121.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 119.5),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 120.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 121.5),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 120.5),
            (Date(), 120.0)
        ],
        "2454": [
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 848.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 852.0),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 847.0),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 851.0),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 853.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 849.0),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 850.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 854.0),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 851.0),
            (Date(), 850.0)
        ],
        "2412": [ // 中華電
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 119.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 119.5),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 120.0),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 120.5),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 121.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 120.5),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 120.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 119.5),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 119.0),
            (Date(), 120.0)
        ],
        "2308": [ // 台達電
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 288.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 289.5),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 291.0),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 292.5),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 291.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 289.5),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 290.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 291.5),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 290.5),
            (Date(), 290.0)
        ],
        "2881": [ // 富邦金
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 74.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 74.5),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 75.5),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 76.0),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 75.5),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 75.0),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 74.5),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 75.0),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 75.5),
            (Date(), 75.0)
        ]
        // ... 其他股票的價格資料
    ]
    
    // 搜尋股票
    func searchStocks(query: String) async -> [SearchStock] {
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
        // 先取得該股票的所有價格資料
        guard let stockPrices = mockStockPrices[symbol] else {
            // 如果找不到價格資料，返回基本價格
            return mockStocks.first { $0.0 == symbol }?.4
        }
        
        // 將日期轉換為相同的時間格式進行比較
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)
        
        // 尋找最接近的日期的價格
        let closestPrice = stockPrices.min { first, second in
            let firstDiff = abs(calendar.startOfDay(for: first.0).timeIntervalSince(targetDate))
            let secondDiff = abs(calendar.startOfDay(for: second.0).timeIntervalSince(targetDate))
            return firstDiff < secondDiff
        }
        
        return closestPrice?.1 ?? mockStocks.first { $0.0 == symbol }?.4
    }
}
