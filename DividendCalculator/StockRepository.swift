//
//  StockRepository.swift
//  DividendCalculator
//
//  Created on 2025/3/6.
//

import Foundation
import Combine

/// 股票資料倉庫 - 整合本地和遠端資料來源
class StockRepository {
    // MARK: - 單例模式
    static let shared = StockRepository()
    
    // 服務
    private let localService = LocalStockService()
    private let apiService = StockAPIService.shared
    
    // 緩存
    private var stockCache: [String: StockInfoResponse] = [:]
    private var priceHistoryCache: [String: [StockPriceHistory]] = [:]
    private var dividendHistoryCache: [String: [DividendHistory]] = [:]
    
    private init() {}
    
    // MARK: - 公開方法
    
    /// 搜索股票
    func searchStocks(query: String) async -> [SearchStock] {
        // 優先使用遠端 API
        do {
            let apiResults = try await apiService.searchStocks(query: query)
            return apiResults.map { SearchStock(symbol: $0.symbol, name: $0.name) }
        } catch {
            print("API 搜索失敗，使用本地搜索: \(error.localizedDescription)")
            // 備用使用本地搜索
            return await localService.searchStocks(query: query)
        }
    }
    
    /// 獲取股票資訊 (使用 API，備用本地)
    func getStockInfo(symbol: String) async -> (name: String?, dividendPerShare: Double?, frequency: Int?) {
        // 先檢查緩存
        if let cachedInfo = stockCache[symbol] {
            return (cachedInfo.name, cachedInfo.dividendPerShare, cachedInfo.frequency)
        }
        
        // 嘗試從 API 獲取
        do {
            let stockInfo = try await apiService.getStockInfo(symbol: symbol)
            stockCache[symbol] = stockInfo
            return (stockInfo.name, stockInfo.dividendPerShare, stockInfo.frequency)
        } catch {
            print("API 獲取股票資訊失敗，使用本地資料: \(error.localizedDescription)")
            
            // 備用使用本地資料
            let name = await localService.getTaiwanStockInfo(symbol: symbol)
            let dividend = await localService.getTaiwanStockDividend(symbol: symbol)
            let frequency = await localService.getTaiwanStockFrequency(symbol: symbol)
            
            return (name, dividend, frequency)
        }
    }
    
    /// 獲取指定日期的股票價格
    func getStockPrice(symbol: String, date: Date) async -> Double? {
        // 嘗試從 API 獲取
        do {
            return try await apiService.getStockPriceOnDate(symbol: symbol, date: date)
        } catch {
            print("API 獲取股價失敗，使用本地資料: \(error.localizedDescription)")
            // 備用使用本地資料
            return await localService.getStockPrice(symbol: symbol, date: date)
        }
    }
    
    /// 獲取股票價格歷史 (K線圖數據)
    func getStockPriceHistory(symbol: String, days: Int) async -> [KLineData] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }
        
        // 嘗試從 API 獲取
        do {
            let historyData = try await apiService.getStockPriceHistory(symbol: symbol, startDate: startDate, endDate: endDate)
            
            // 更新緩存
            priceHistoryCache[symbol] = historyData
            
            return DataMapper.mapToKLineData(from: historyData)
        } catch {
            print("API 獲取股價歷史失敗，使用模擬數據: \(error.localizedDescription)")
            
            // 備用使用模擬數據生成 K 線圖
            return await generateSimulatedKLineData(symbol: symbol, days: days)
        }
    }
    
    /// 獲取股利歷史
    func getDividendHistory(symbol: String, years: Int = 3) async -> [DividendData] {
        // 嘗試從 API 獲取
        do {
            let historyData = try await apiService.getDividendHistory(symbol: symbol, years: years)
            
            // 更新緩存
            dividendHistoryCache[symbol] = historyData
            
            return DataMapper.mapToDividendData(from: historyData)
        } catch {
            print("API 獲取股利歷史失敗，使用模擬數據: \(error.localizedDescription)")
            
            // 備用生成模擬數據
            return await generateSimulatedDividendHistory(symbol: symbol, years: years)
        }
    }
    
    /// 獲取股利發放時間表
    func getDividendSchedule(symbol: String) async -> [DividendData] {
        // 嘗試從 API 獲取
        do {
            let scheduleData = try await apiService.getDividendSchedule(symbol: symbol)
            return DataMapper.mapToDividendData(from: scheduleData)
        } catch {
            print("API 獲取股利時間表失敗，使用模擬數據: \(error.localizedDescription)")
            
            // 備用生成模擬數據
            return await generateSimulatedDividendSchedule(symbol: symbol)
        }
    }
    
    /// 獲取產業列表
    func getIndustries() async -> [String] {
        // 嘗試從 API 獲取
        do {
            return try await apiService.getIndustries()
        } catch {
            print("API 獲取產業列表失敗，使用預設列表: \(error.localizedDescription)")
            
            // 備用使用預設列表
            return [
                "半導體", "電子零組件", "電腦及周邊設備", "光電", "通信網路",
                "電子通路", "資訊服務", "其他電子", "金融保險", "建材營造",
                "航運", "生技醫療", "食品", "紡織纖維", "鋼鐵", "觀光"
            ]
        }
    }
    
    /// 獲取產業中的股票
    func getStocksByIndustry(industry: String) async -> [SearchStock] {
        // 嘗試從 API 獲取
        do {
            let stocks = try await apiService.getStocksByIndustry(industry: industry)
            return stocks.map { SearchStock(symbol: $0.symbol, name: $0.name) }
        } catch {
            print("API 獲取產業股票失敗，使用空列表: \(error.localizedDescription)")
            
            // 備用返回空列表
            return []
        }
    }
    
    // MARK: - 私有輔助方法
    
    /// 生成模擬的 K 線數據
    private func generateSimulatedKLineData(symbol: String, days: Int) async -> [KLineData] {
        var kLineData: [KLineData] = []
        
        // 獲取基準價格
        let basePrice = await localService.getStockPrice(symbol: symbol, date: Date()) ?? 100.0
        
        let calendar = Calendar.current
        let today = Date()
        
        for day in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -day, to: today) else { continue }
            
            // 模擬每日波動
            let dailyVolatility = Double.random(in: -0.05...0.05)
            let open = basePrice * (1 + Double.random(in: -0.03...0.03))
            let close = open * (1 + dailyVolatility)
            let high = max(open, close) * (1 + Double.random(in: 0.005...0.02))
            let low = min(open, close) * (1 - Double.random(in: 0.005...0.02))
            let volume = Int.random(in: 100000...5000000)
            
            kLineData.append(KLineData(
                date: date,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            ))
        }
        
        return kLineData.sorted(by: { $0.date < $1.date })
    }
    
    /// 生成模擬的股利歷史數據
    private func generateSimulatedDividendHistory(symbol: String, years: Int) async -> [DividendData] {
        var dividendHistory: [DividendData] = []
        
        // 獲取基準股利
        let baseDividend = await localService.getTaiwanStockDividend(symbol: symbol) ?? 2.0
        let frequency = await localService.getTaiwanStockFrequency(symbol: symbol) ?? 1
        
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        
        // 根據頻率生成歷史數據
        for year in (currentYear - years)...currentYear {
            for period in 0..<frequency {
                let month = 12 / frequency * period + 1
                
                var dateComponents = DateComponents()
                dateComponents.year = year
                dateComponents.month = month
                dateComponents.day = 15
                
                guard let recordDate = calendar.date(from: dateComponents),
                      let exDate = calendar.date(byAdding: .day, value: -14, to: recordDate),
                      let payDate = calendar.date(byAdding: .day, value: 30, to: recordDate) else {
                    continue
                }
                
                // 模擬股利波動
                let dividendVariation = Double.random(in: -0.2...0.2)
                let amount = baseDividend / Double(frequency) * (1 + dividendVariation)
                
                dividendHistory.append(DividendData(
                    id: UUID(),
                    date: recordDate,
                    amount: amount,
                    exDividendDate: exDate,
                    paymentDate: payDate
                ))
            }
        }
        
        return dividendHistory.sorted(by: { $0.date > $1.date })
    }
    
    /// 生成模擬的股利發放時間表
    private func generateSimulatedDividendSchedule(symbol: String) async -> [DividendData] {
        var dividendSchedule: [DividendData] = []
        
        // 獲取基準股利
        let baseDividend = await localService.getTaiwanStockDividend(symbol: symbol) ?? 2.0
        let frequency = await localService.getTaiwanStockFrequency(symbol: symbol) ?? 1
        
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        
        // 生成未來一年的股利時間表
        for period in 0..<frequency {
            let month = (calendar.component(.month, from: today) + 12 / frequency * (period + 1)) % 12
            let year = currentYear + ((calendar.component(.month, from: today) + 12 / frequency * (period + 1)) > 12 ? 1 : 0)
            
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month == 0 ? 12 : month
            dateComponents.day = 15
            
            guard let recordDate = calendar.date(from: dateComponents),
                  let exDate = calendar.date(byAdding: .day, value: -14, to: recordDate),
                  let payDate = calendar.date(byAdding: .day, value: 30, to: recordDate) else {
                continue
            }
            
            // 模擬股利波動
            let dividendVariation = Double.random(in: -0.1...0.1)
            let amount = baseDividend / Double(frequency) * (1 + dividendVariation)
            
            dividendSchedule.append(DividendData(
                id: UUID(),
                date: recordDate,
                amount: amount,
                exDividendDate: exDate,
                paymentDate: payDate
            ))
        }
        
        return dividendSchedule.sorted(by: { $0.date < $1.date })
    }
}
