//
//  StockAPIService.swift
//  DividendCalculator
//
//  Created on 2025/3/6.
//

import Foundation

// MARK: - 回應模型
struct ApiResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T
    let message: String?
}

// MARK: - 股票相關資料模型
struct StockInfoResponse: Decodable {
    let symbol: String
    let name: String
    let currentPrice: Double
    let dividendPerShare: Double
    let frequency: Int
    let industry: String?
    let peRatio: Double?
    let marketCap: Double?
    let yearHighPrice: Double?
    let yearLowPrice: Double?
}

// MARK: - 股票 API 服務
class StockAPIService {
    // MARK: - 單例模式
    static let shared = StockAPIService()
    
    private init() {}
    
    // MARK: - 公開方法
    
    /// 獲取股票基本資訊
    func getStockInfo(symbol: String) async throws -> StockInfoResponse {
        do {
            // 從資料庫獲取股利數據
            let dividendResponse: DividendResponse = try await APIService.shared.getDividendData(symbol: symbol)
            
            // 若無數據或發生錯誤，拋出異常
            guard !dividendResponse.data.isEmpty else {
                throw APIError(code: 404, message: "找不到股票數據")
            }
            
            // 從本地服務獲取基本資訊（後續可改為從資料庫獲取）
            let localService = LocalStockService()
            let name = await localService.getTaiwanStockInfo(symbol: symbol) ?? symbol
            
            // 計算每股股利和頻率（根據股利歷史數據）
            let (dividendPerShare, frequency) = calculateDividendInfo(from: dividendResponse.data)
            
            // 獲取最新收盤價（這裡使用本地服務模擬，後續應從價格表中獲取）
            let currentPrice = await localService.getStockPrice(symbol: symbol, date: Date()) ?? 0
            
            // 構建 StockInfoResponse
            return StockInfoResponse(
                symbol: symbol,
                name: name,
                currentPrice: currentPrice,
                dividendPerShare: dividendPerShare,
                frequency: frequency,
                industry: nil,
                peRatio: nil,
                marketCap: nil,
                yearHighPrice: nil,
                yearLowPrice: nil
            )
        } catch {
            print("獲取股票資訊失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 獲取多檔股票資訊
    func getMultipleStockInfo(symbols: [String]) async throws -> [StockInfoResponse] {
        var results: [StockInfoResponse] = []
        
        for symbol in symbols {
            do {
                let info = try await getStockInfo(symbol: symbol)
                results.append(info)
            } catch {
                print("獲取 \(symbol) 股票資訊失敗: \(error.localizedDescription)")
                // 繼續處理下一支股票，不中斷整個流程
            }
        }
        
        return results
    }
    
    /// 根據關鍵字搜尋股票
    func searchStocks(query: String) async throws -> [StockInfoResponse] {
        let localService = LocalStockService()
        let searchResults = await localService.searchStocks(query: query)
        
        // 將 SearchStock 轉換為 StockInfoResponse
        var responses: [StockInfoResponse] = []
        for result in searchResults {
            do {
                let info = try await getStockInfo(symbol: result.symbol)
                responses.append(info)
            } catch {
                print("獲取 \(result.symbol) 詳細資訊失敗: \(error.localizedDescription)")
                // 繼續處理下一支股票
            }
        }
        
        return responses
    }
    
    /// 獲取特定日期的股價
    func getStockPriceOnDate(symbol: String, date: Date) async throws -> Double {
        let localService = LocalStockService()
        if let price = await localService.getStockPrice(symbol: symbol, date: date) {
            return price
        }
        throw APIError(code: 404, message: "無法獲取股價數據")
    }
    
    /// 獲取股利發放時間表
    func getDividendSchedule(symbol: String) async throws -> [DividendRecord] {
        // 從資料庫獲取股利數據
        let dividendResponse: DividendResponse = try await APIService.shared.getDividendData(symbol: symbol)
        
        // 過濾出未來的股利發放記錄
        let currentDate = Date()
        let futureRecords = dividendResponse.data.filter { record in
            guard let distributionDate = record.distributionDateObj else { return false }
            return distributionDate > currentDate
        }
        
        return futureRecords.sorted { a, b in
            guard let dateA = a.distributionDateObj, let dateB = b.distributionDateObj else {
                return false
            }
            return dateA < dateB
        }
    }
    
    /// 獲取產業列表
    func getIndustries() async throws -> [String] {
        // 返回預設產業列表
        return [
            "半導體", "電子零組件", "電腦及周邊設備", "光電", "通信網路",
            "電子通路", "資訊服務", "其他電子", "金融保險", "建材營造",
            "航運", "生技醫療", "食品", "紡織纖維", "鋼鐵", "觀光"
        ]
    }
    
    /// 獲取某產業的所有股票
    func getStocksByIndustry(industry: String) async throws -> [StockInfoResponse] {
        // 後續可實現從資料庫獲取產業股票
        let localService = LocalStockService()
        let searchResults = await localService.searchStocks(query: "")
        
        // 模擬過濾產業股票
        let filteredResults = searchResults.filter { _ in
            // 使用隨機概率進行模擬
            return Double.random(in: 0...1) < 0.2
        }
        
        // 將 SearchStock 轉換為 StockInfoResponse
        var responses: [StockInfoResponse] = []
        for result in filteredResults.prefix(10) { // 限制數量
            do {
                let info = try await getStockInfo(symbol: result.symbol)
                responses.append(info)
            } catch {
                print("獲取 \(result.symbol) 詳細資訊失敗: \(error.localizedDescription)")
                // 繼續處理下一支股票
            }
        }
        
        return responses
    }
    
    // MARK: - 私有輔助方法
    
    /// 從股利歷史數據計算每股股利和頻率
    private func calculateDividendInfo(from records: [DividendRecord]) -> (dividendPerShare: Double, frequency: Int) {
        // 獲取最近年度的股利記錄
        let sortedRecords = records.sorted { a, b in
            guard let yearA = Int(a.dividendYear), let yearB = Int(b.dividendYear) else {
                return false
            }
            if yearA == yearB {
                // 同一年，比較期間 (上半年/下半年/全年)
                if a.dividendPeriod.contains("上半年") && b.dividendPeriod.contains("下半年") {
                    return true // 上半年在前
                } else if a.dividendPeriod.contains("下半年") && b.dividendPeriod.contains("上半年") {
                    return false // 下半年在後
                }
            }
            return yearA > yearB // 年份大的在前
        }
        
        // 獲取最新年度的全部股利記錄
        let latestYear = sortedRecords.first.map { Int($0.dividendYear) ?? 0 } ?? 0
        let latestYearRecords = sortedRecords.filter {
            Int($0.dividendYear) ?? 0 == latestYear
        }
        
        // 計算每股股利：最新年度的總股利
        var dividendPerShare: Double = 0
        for record in latestYearRecords {
            dividendPerShare += record.totalCashDividend
        }
        
        // 計算發放頻率
        var frequency = 1 // 默認年配
        
        // 根據兩年的記錄判斷頻率
        let twoYearsRecords = sortedRecords.filter {
            let year = Int($0.dividendYear) ?? 0
            return year >= latestYear - 1
        }
        
        // 檢查期間命名
        var hasHalfYear = false
        var hasQuarter = false
        
        for record in twoYearsRecords {
            if record.dividendPeriod.contains("季") {
                hasQuarter = true
                break
            } else if record.dividendPeriod.contains("半年") {
                hasHalfYear = true
            }
        }
        
        // 直接檢查一年內的發放次數
        let countPerYear = twoYearsRecords.count / 2 // 兩年的記錄除以2
        
        if hasQuarter || countPerYear >= 4 {
            frequency = 4 // 季配
        } else if hasHalfYear || countPerYear >= 2 {
            frequency = 2 // 半年配
        } else {
            frequency = 1 // 年配
        }
        
        return (dividendPerShare, frequency)
    }
}
