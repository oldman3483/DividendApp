//
//  DataManager.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/3.
//

import Foundation

class DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    func saveStocks(_ stocks: [Stock]) {
        if let encoded = try? JSONEncoder().encode(stocks) {
            UserDefaults.standard.set(encoded, forKey: "stocks")
        }
    }
    
    func saveWatchlist(_ watchlist: [WatchStock]) {
        if let encoded = try? JSONEncoder().encode(watchlist) {
            UserDefaults.standard.set(encoded, forKey: "watchlist")
        }
    }
    
    func saveBanks(_ banks: [Bank]) {
        if let encoded = try? JSONEncoder().encode(banks) {
            UserDefaults.standard.set(encoded, forKey: "banks")
        }
    }
    
    func loadStocks() -> [Stock] {
        guard let data = UserDefaults.standard.data(forKey: "stocks"),
              let stocks = try? JSONDecoder().decode([Stock].self, from: data) else {
            return []
        }
        return stocks
    }
    
    func loadWatchlist() -> [WatchStock] {
        guard let data = UserDefaults.standard.data(forKey: "watchlist"),
              let watchlist = try? JSONDecoder().decode([WatchStock].self, from: data) else {
            return []
        }
        return watchlist
    }
    
    func loadBanks() -> [Bank] {
        guard let data = UserDefaults.standard.data(forKey: "banks"),
              let banks = try? JSONDecoder().decode([Bank].self, from: data) else {
            return []
        }
        return banks
    }
}
