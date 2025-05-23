//
//  DataCacheManager.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/5/23.
//

import Foundation

class DataCacheManager {
    static let shared = DataCacheManager()
    private init() {}
    
    private let userDefaults = UserDefaults.standard
    private let lastUpdateKey = "lastDataUpdate"
    
    // 檢查是否需要更新數據
    func shouldUpdateData() -> Bool {
        guard let lastUpdate = userDefaults.object(forKey: lastUpdateKey) as? Date else {
            return true // 首次使用，需要更新
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // 檢查是否過了一天
        return !calendar.isDate(lastUpdate, inSameDayAs: today)
    }
    
    // 標記數據已更新
    func markDataUpdated() {
        userDefaults.set(Date(), forKey: lastUpdateKey)
    }
    
    // 清除所有緩存
    func clearCache() {
        userDefaults.removeObject(forKey: lastUpdateKey)
    }
}
