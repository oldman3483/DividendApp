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
    
    // 改為使用 UserDefaults 來存儲價格，確保應用重啟前價格保持一致
    private let priceStorageKey = "StockPricesCache"
    private let lastUpdateKey = "StockPricesLastUpdate"
    
    // 獲取今天的日期字串作為緩存key的一部分
    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // 從 UserDefaults 讀取價格緩存
    private func loadPriceCache() -> [String: Double] {
        let key = "\(priceStorageKey)_\(todayKey)"
        if let data = UserDefaults.standard.data(forKey: key),
           let cache = try? JSONDecoder().decode([String: Double].self, from: data) {
            return cache
        }
        return [:]
    }
    
    // 保存價格緩存到 UserDefaults
    private func savePriceCache(_ cache: [String: Double]) {
        let key = "\(priceStorageKey)_\(todayKey)"
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.set(Date(), forKey: lastUpdateKey)
        }
    }
    
    // 檢查是否需要重新生成價格（新的一天）
    private func shouldRegeneratePrice() -> Bool {
        guard let lastUpdate = UserDefaults.standard.object(forKey: lastUpdateKey) as? Date else {
            return true
        }
        
        let calendar = Calendar.current
        return !calendar.isDate(lastUpdate, inSameDayAs: Date())
    }
    
    // 生成穩定的價格（每個交易日固定）
    private func generateStablePrice(symbol: String, date: Date) -> Double {
        let basePrice = mockStocks.first { $0.0 == symbol }?.4 ?? 100.0
        
        // 使用日期和股票代號生成固定的種子
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let dateSeed = (components.year ?? 2025) * 10000 + (components.month ?? 1) * 100 + (components.day ?? 1)
        
        // 創建固定的隨機數生成器
        let combinedSeedString = "\(symbol)_\(dateSeed)"
        let seedData = combinedSeedString.data(using: .utf8)!
        let seedValue = seedData.withUnsafeBytes { $0.load(as: UInt64.self) }
        
        var generator = SeededRandomNumberGenerator(seed: seedValue)
        
        // 生成固定的價格變動
        let volatility = Double.random(in: -0.05...0.05, using: &generator)
        let trend = Double.random(in: -0.02...0.03, using: &generator)
        
        let variation = volatility + trend
        let newPrice = basePrice * (1 + variation)
        
        // 限制價格變動範圍
        let maxDeviation = basePrice * 0.2
        let minPrice = basePrice - maxDeviation
        let maxPrice = basePrice + maxDeviation
        
        return min(max(newPrice, minPrice), maxPrice)
    }

    // 取得指定日期的收盤價
    func getStockPrice(symbol: String, date: Date) async -> Double? {
        // 對於今天的價格，使用緩存機制
        if Calendar.current.isDateInToday(date) {
            var priceCache = loadPriceCache()
            
            if let cachedPrice = priceCache[symbol] {
                return cachedPrice
            } else {
                // 生成新價格並緩存
                let price = generateStablePrice(symbol: symbol, date: date)
                priceCache[symbol] = price
                savePriceCache(priceCache)
                return price
            }
        } else {
            // 對於歷史日期，直接生成固定價格（不需要緩存）
            return generateStablePrice(symbol: symbol, date: date)
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
    
    // 清理舊的價格緩存
    func cleanOldPriceCache() {
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        // 只保留今天的價格緩存
        for key in allKeys {
            if key.hasPrefix(priceStorageKey) && !key.hasSuffix(todayKey) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}

// 固定種子的隨機數生成器
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 1103515245 &+ 12345
        return state
    }
}
