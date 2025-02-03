//
//  LocalStockService.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/21.
//

//
//  LocalStockService.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/21.
//

import SwiftUI

class LocalStockService {
    // 模擬資料庫 - 基本股票資訊
    private let mockStocks = [
        ("2330", "台積電", 2.75, 4),
        ("2317", "鴻海", 5.0, 1),
        ("2454", "聯發科", 3.0, 4),
        ("2412", "中華電", 4.5, 4),
        ("2308", "台達電", 3.5, 4),
        ("2881", "富邦金", 3.0, 2),
        ("2882", "國泰金", 2.5, 2),
        ("1301", "台塑", 4.0, 1),
        ("1303", "南亞", 3.2, 1),
        ("2891", "中信金", 2.8, 2)
    ]
    
    // 模擬近十天的收盤價資料
    private let mockHistoricalPrices: [String: [(Date, Double)]] = [
        "2330": [ // 台積電
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 550.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 548.0),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 552.0),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 555.0),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 553.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 557.0),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 560.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 558.0),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 562.0),
            (Date(), 565.0)
        ],
        "2317": [ // 鴻海
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 120.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 119.5),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 121.0),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 120.5),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 122.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 121.5),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 123.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 122.5),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 124.0),
            (Date(), 123.5)
        ],
        "2454": [ // 聯發科
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 850.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 848.0),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 855.0),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 853.0),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 858.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 856.0),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 860.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 857.0),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 862.0),
            (Date(), 865.0)
        ],
        "2412": [ // 中華電
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 120.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 119.0),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 120.5),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 121.0),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 120.5),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 121.5),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 122.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 121.5),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 122.5),
            (Date(), 122.0)
        ],
        "2308": [ // 台達電
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 290.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 288.0),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 292.0),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 291.0),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 293.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 292.5),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 294.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 293.0),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 295.0),
            (Date(), 294.5)
        ],
        "2881": [ // 富邦金
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 75.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 74.5),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 75.5),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 75.2),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 76.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 75.8),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 76.5),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 76.2),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 77.0),
            (Date(), 76.8)
        ],
        "2882": [ // 國泰金
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 45.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 44.8),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 45.2),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 45.1),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 45.5),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 45.3),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 45.7),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 45.5),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 45.9),
            (Date(), 45.7)
        ],
        "1301": [ // 台塑
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 110.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 109.5),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 111.0),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 110.5),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 111.5),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 111.0),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 112.0),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 111.5),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 112.5),
            (Date(), 112.0)
        ],
        "1303": [ // 南亞
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 85.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 84.5),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 85.5),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 85.2),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 86.0),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 85.8),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 86.5),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 86.2),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 87.0),
            (Date(), 86.8)
        ],
        "2891": [ // 中信金
            (Calendar.current.date(byAdding: .day, value: -9, to: Date())!, 25.0),
            (Calendar.current.date(byAdding: .day, value: -8, to: Date())!, 24.8),
            (Calendar.current.date(byAdding: .day, value: -7, to: Date())!, 25.2),
            (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 25.1),
            (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 25.4),
            (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 25.3),
            (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 25.6),
            (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 25.5),
            (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 25.8),
            (Date(), 25.7)
        ]
    ]
    
    // 搜尋股票
    func searchStocks(query: String) async -> [SearchStock] {
        return mockStocks
            .filter { stockInfo in
                let (symbol, name, _, _) = stockInfo
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
        guard let prices = mockHistoricalPrices[symbol] else { return nil }
        
        // 將日期標準化到當天的開始時間（去除時分秒）
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        // 找到最接近的價格
        return prices
            .min(by: { abs($0.0.timeIntervalSince(normalizedDate)) < abs($1.0.timeIntervalSince(normalizedDate)) })?
            .1
    }
}
