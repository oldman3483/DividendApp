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

struct ErrorResponse: Decodable {
    let success: Bool
    let message: String
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

struct StockPriceHistory: Decodable {
    let date: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
}

struct DividendHistory: Decodable {
    let date: String
    let amount: Double
    let exDividendDate: String
    let paymentDate: String
}

// MARK: - 股票 API 服務
class StockAPIService {
    // MARK: - 單例模式
    static let shared = StockAPIService()
    
    private init() {}
    
    // MARK: - 公開方法
    
    /// 獲取股票基本資訊
    func getStockInfo(symbol: String) async throws -> StockInfoResponse {
        let queryItems = [URLQueryItem(name: "symbol", value: symbol)]
        let response: ApiResponse<StockInfoResponse> = try await APIService.shared.get(path: "stocks/info", queryItems: queryItems)
        return response.data
    }
    
    /// 獲取多檔股票資訊
    func getMultipleStockInfo(symbols: [String]) async throws -> [StockInfoResponse] {
        // 將多個 symbol 參數組合
        let queryItems = symbols.map { URLQueryItem(name: "symbols", value: $0) }
        let response: ApiResponse<[StockInfoResponse]> = try await APIService.shared.get(path: "stocks/multiple", queryItems: queryItems)
        return response.data
    }
    
    /// 獲取歷史價格資料
    func getStockPriceHistory(symbol: String, startDate: Date, endDate: Date? = nil) async throws -> [StockPriceHistory] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "startDate", value: dateFormatter.string(from: startDate))
        ]
        
        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "endDate", value: dateFormatter.string(from: endDate)))
        }
        
        let response: ApiResponse<[StockPriceHistory]> = try await APIService.shared.get(path: "stocks/history", queryItems: queryItems)
        return response.data
    }
    
    /// 獲取股利歷史資料
    func getDividendHistory(symbol: String, years: Int? = nil) async throws -> [DividendHistory] {
        var queryItems = [URLQueryItem(name: "symbol", value: symbol)]
        
        if let years = years {
            queryItems.append(URLQueryItem(name: "years", value: String(years)))
        }
        
        let response: ApiResponse<[DividendHistory]> = try await APIService.shared.get(path: "stocks/dividends", queryItems: queryItems)
        return response.data
    }
    
    /// 根據關鍵字搜尋股票
    func searchStocks(query: String) async throws -> [StockInfoResponse] {
        let queryItems = [URLQueryItem(name: "q", value: query)]
        let response: ApiResponse<[StockInfoResponse]> = try await APIService.shared.get(path: "stocks/search", queryItems: queryItems)
        return response.data
    }
    
    /// 獲取特定日期的股價
    func getStockPriceOnDate(symbol: String, date: Date) async throws -> Double {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "date", value: dateFormatter.string(from: date))
        ]
        
        struct PriceResponse: Decodable {
            let price: Double
        }
        
        let response: ApiResponse<PriceResponse> = try await APIService.shared.get(path: "stocks/price", queryItems: queryItems)
        return response.data.price
    }
    
    /// 獲取股息發放日期
    func getDividendSchedule(symbol: String) async throws -> [DividendHistory] {
        let queryItems = [URLQueryItem(name: "symbol", value: symbol)]
        let response: ApiResponse<[DividendHistory]> = try await APIService.shared.get(path: "stocks/dividend-schedule", queryItems: queryItems)
        return response.data
    }
    
    /// 獲取產業類股列表
    func getIndustries() async throws -> [String] {
        let response: ApiResponse<[String]> = try await APIService.shared.get(path: "stocks/industries")
        return response.data
    }
    
    /// 獲取某產業的所有股票
    func getStocksByIndustry(industry: String) async throws -> [StockInfoResponse] {
        let queryItems = [URLQueryItem(name: "industry", value: industry)]
        let response: ApiResponse<[StockInfoResponse]> = try await APIService.shared.get(path: "stocks/by-industry", queryItems: queryItems)
        return response.data
    }
}
