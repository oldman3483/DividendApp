//
//  CacheManager.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/5/14.
//

import Foundation

// 股價緩存管理器
class StockPriceCache {
    
    // 加入緩存大小限制
    private let maxCacheSize = 1000
        
        // 修改緩存清理方法
    func clearCache() {
        priceCache.removeAll(keepingCapacity: true)
        updateCurrentDateString()
    }
    
    static let shared = StockPriceCache()
    
    // 日期格式化工具
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // 緩存的股價數據
    private var priceCache: [String: Double] = [:]
    
    // 添加緩存管理方法
    private func manageCacheSize() {
        if priceCache.count > maxCacheSize {
            // 只保留最近使用的項目
            let keysToRemove = priceCache.keys.dropLast(maxCacheSize / 2)
            keysToRemove.forEach { priceCache.removeValue(forKey: $0) }
        }
    }
    
    // 今日日期字串，用於重設緩存
    private var currentDateString: String = ""
    
    private init() {
        resetCacheIfNewDay()
    }
    
    // 獲取緩存的股價，如果沒有則生成並緩存
    func getStockPrice(symbol: String, date: Date, calculatePrice: () -> Double) -> Double {
        resetCacheIfNewDay()
        
        let cacheKey = createCacheKey(symbol: symbol, date: date)
        
        if let cachedPrice = priceCache[cacheKey] {
            return cachedPrice
        }
        
        let price = calculatePrice()
        priceCache[cacheKey] = price
        return price
    }
    
    // 創建緩存鍵
    private func createCacheKey(symbol: String, date: Date) -> String {
        let dateString = dateFormatter.string(from: date)
        return "\(symbol)_\(dateString)"
    }
    
    // 更新當前日期字串
    private func updateCurrentDateString() {
        currentDateString = dateFormatter.string(from: Date())
    }
    
    // 如果是新的一天則重設緩存
    private func resetCacheIfNewDay() {
        let today = dateFormatter.string(from: Date())
        if today != currentDateString {
            clearCache()
            currentDateString = today
        }
    }
}
