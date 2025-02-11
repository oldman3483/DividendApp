//
//  LocalStockService.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/21.
//

import SwiftUI

class LocalStockService {
    // 保留原有的基本股票資訊
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
    
    // 加入波動性參數
    private let volatilityRange: ClosedRange<Double> = -0.05...0.05  // 5% 的波動範圍
    private let trendBias: ClosedRange<Double> = -0.02...0.03       // 偏向上漲的趨勢
    
    // 記錄每個股票的最後價格
    private var lastPrices: [String: Double] = [:]
    
    // 取得指定日期的收盤價，加入更真實的價格變動
    func getStockPrice(symbol: String, date: Date) async -> Double? {
        // 取得基礎價格
        let basePrice = mockStocks.first { $0.0 == symbol }?.4 ?? 0
        
        // 如果沒有最後價格，初始化為基礎價格
        if lastPrices[symbol] == nil {
            lastPrices[symbol] = basePrice
        }
        
        // 獲取最後價格
        guard let lastPrice = lastPrices[symbol] else { return basePrice }
        
        // 生成隨機波動
        let randomVolatility = Double.random(in: volatilityRange)
        let trendComponent = Double.random(in: trendBias)
        
        // 計算新價格，綜合考慮波動性和趨勢
        let variation = randomVolatility + trendComponent
        var newPrice = lastPrice * (1 + variation)
        
        // 加入價格限制，避免價格過度偏離基礎價格
        let maxDeviation = basePrice * 0.2 // 最大允許偏離基準價格的 20%
        let minPrice = basePrice - maxDeviation
        let maxPrice = basePrice + maxDeviation
        newPrice = min(max(newPrice, minPrice), maxPrice)
        
        // 更新最後價格
        lastPrices[symbol] = newPrice
        
        return newPrice
    }
    
    // 搜尋股票（保持原有功能）
    func searchStocks(query: String) async -> [SearchStock] {
        return mockStocks
            .filter { stockInfo in
                let (symbol, name, _, _, _) = stockInfo
                return symbol.lowercased().contains(query.lowercased()) ||
                name.lowercased().contains(query.lowercased())
            }
            .map { SearchStock(symbol: $0.0, name: $0.1) }
    }
    
    // 取得股票資訊（保持原有功能）
    func getTaiwanStockInfo(symbol: String) async -> String? {
        return mockStocks.first { $0.0 == symbol }?.1
    }
    
    // 取得股利資訊（保持原有功能）
    func getTaiwanStockDividend(symbol: String) async -> Double? {
        return mockStocks.first { $0.0 == symbol }?.2
    }
    
    // 獲取股利頻率（保持原有功能）
    func getTaiwanStockFrequency(symbol: String) async -> Int? {
        return mockStocks.first { $0.0 == symbol }?.3
    }
}
