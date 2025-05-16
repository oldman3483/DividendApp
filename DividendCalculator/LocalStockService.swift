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
        ("2891", "中信金", 2.8, 2, 25.0),
        ("0050", "元大台灣50", 2.0, 4, 120.0)
    ]
    
    // 加入波動性參數
    private let volatilityRange: ClosedRange<Double> = -0.05...0.05  // 5% 的波動範圍
    private let trendBias: ClosedRange<Double> = -0.02...0.03       // 偏向上漲的趨勢
    
    // 使用緩存管理器
    private let priceCache = StockPriceCache.shared

    // 取得指定日期的收盤價，加入更真實的價格變動
    func getStockPrice(symbol: String, date: Date) async -> Double? {
        // 使用緩存，並提供計算價格的閉包
        return priceCache.getStockPrice(symbol: symbol, date: date) {
            // 以下是原始的計算邏輯，但現在只有在緩存未命中時才會執行
            let basePrice = self.mockStocks.first { $0.0 == symbol }?.4 ?? 0
            
            // 根據日期和股票代號生成種子
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            let dateSeed = (components.year ?? 2025) * 10000 + (components.month ?? 1) * 100 + (components.day ?? 1)
            
            var randomGenerator = SystemRandomNumberGenerator()
            let combinedSeedString = "\(symbol)_\(dateSeed)"
            let seedData = combinedSeedString.data(using: .utf8)!
            let seedUInt = seedData.withUnsafeBytes { $0.load(as: UInt64.self) }
            randomGenerator.seed = seedUInt
            
            let randomVolatility = Double.random(in: self.volatilityRange, using: &randomGenerator)
            let trendComponent = Double.random(in: self.trendBias, using: &randomGenerator)
            
            let variation = randomVolatility + trendComponent
            let newPrice = basePrice * (1 + variation)
            
            let maxDeviation = basePrice * 0.2
            let minPrice = basePrice - maxDeviation
            let maxPrice = basePrice + maxDeviation
            let finalPrice = min(max(newPrice, minPrice), maxPrice)
            
            return finalPrice
        }
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

// 擴展 SystemRandomNumberGenerator 以支援自定義種子
extension SystemRandomNumberGenerator {
    private static var _seed: UInt64 = 0
    
    var seed: UInt64 {
        get { Self._seed }
        set { Self._seed = newValue }
    }
    
    mutating func seed(_ newSeed: UInt64) {
        seed = newSeed
    }
}
