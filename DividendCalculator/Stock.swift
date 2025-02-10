//
//  Stock.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import Foundation

// 基本的股票結構
struct Stock: Identifiable, Codable, Equatable {
    var id = UUID()
    let symbol: String        // 股票代號
    let name: String         // 公司名稱
    var shares: Int          // 持股數量
    var dividendPerShare: Double  // 每股股利
    let dividendYear: Int    // 股利年度
    let isHistorical: Bool   // 是否為歷史股利
    var frequency: Int       // 發放頻率（1=年配, 2=半年配, 4=季配, 12=月配）
    var purchaseDate: Date   // 購買日期
    var purchasePrice: Double? // 購買價格
    var bankId: UUID // 關聯的銀行ID



    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case shares
        case dividendPerShare
        case dividendYear
        case isHistorical
        case frequency
        case purchaseDate
        case purchasePrice
        case bankId
    }
    
    // 計算年化股利
    func calculateAnnualDividend() -> Double {
        return Double(shares) * dividendPerShare * Double(frequency)
    }
    
    // 計算購買時的總價值
    func calculateTotalCost() -> Double? {
        if let price = purchasePrice {
            return Double(shares) * price
        }
        return nil
    }
    // 計算損益
    func calculateProfitLoss(currentPrice: Double?) -> Double {
        guard let currentPrice = currentPrice,
              let purchasePrice = self.purchasePrice else { return 0 }
        return Double(shares) * (currentPrice - purchasePrice)
    }
        
    // 計算報酬率
    func calculateROI(currentPrice: Double?) -> Double {
        guard let currentPrice = currentPrice,
              let purchasePrice = self.purchasePrice,
              purchasePrice > 0 else { return 0 }
        return ((currentPrice - purchasePrice) / purchasePrice) * 100
    }
    // 計算當前總市值
    func calculateCurrentValue(currentPrice: Double?) -> Double {
        return Double(shares) * (currentPrice ?? 0)
    }


    
    // 解碼初始化器
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        symbol = try container.decode(String.self, forKey: .symbol)
        name = try container.decode(String.self, forKey: .name)
        shares = try container.decode(Int.self, forKey: .shares)
        dividendPerShare = try container.decode(Double.self, forKey: .dividendPerShare)
        dividendYear = try container.decode(Int.self, forKey: .dividendYear)
        isHistorical = try container.decode(Bool.self, forKey: .isHistorical)
        frequency = try container.decode(Int.self, forKey: .frequency)
        purchaseDate = try container.decode(Date.self, forKey: .purchaseDate)
        purchasePrice = try container.decodeIfPresent(Double.self, forKey: .purchasePrice)
        bankId = try container.decodeIfPresent(UUID.self, forKey: .bankId) ?? UUID()
    }
    
    // 編碼方法
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(name, forKey: .name)
        try container.encode(shares, forKey: .shares)
        try container.encode(dividendPerShare, forKey: .dividendPerShare)
        try container.encode(dividendYear, forKey: .dividendYear)
        try container.encode(isHistorical, forKey: .isHistorical)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(purchaseDate, forKey: .purchaseDate)
        try container.encodeIfPresent(purchasePrice, forKey: .purchasePrice)
        try container.encodeIfPresent(bankId, forKey: .bankId)
    }
    
    // 初始化方法
    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        shares: Int,
        dividendPerShare: Double,
        dividendYear: Int,
        isHistorical: Bool = false,
        frequency: Int = 1,
        purchaseDate: Date = Date(),
        purchasePrice: Double? = nil,
        bankId: UUID
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.shares = shares
        self.dividendPerShare = dividendPerShare
        self.dividendYear = dividendYear
        self.isHistorical = isHistorical
        self.frequency = frequency
        self.purchaseDate = purchaseDate
        self.purchasePrice = purchasePrice
        self.bankId = bankId
    }
    
    static func == (lhs: Stock, rhs: Stock) -> Bool {
        return lhs.id == rhs.id
    }
}

// 加權平均後的股票資訊結構
struct WeightedStockInfo: Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let totalShares: Int
    let weightedDividendPerShare: Double
    let frequency: Int
    let details: [Stock]
    
    // 計算加權平均購買價格
    var weightedPurchasePrice: Double? {
        let stocksWithPrice = details.filter { $0.purchasePrice != nil }
        guard !stocksWithPrice.isEmpty else { return nil }
        
        let totalValue = stocksWithPrice.reduce(0.0) { sum, stock in
            sum + (stock.purchasePrice ?? 0) * Double(stock.shares)
        }
        let totalShares = stocksWithPrice.reduce(0) { $0 + $1.shares }
        return totalValue / Double(totalShares)
    }
    
    // 計算總年化股利
    func calculateTotalAnnualDividend() -> Double {
        return Double(totalShares) * weightedDividendPerShare * Double(frequency)
    }
    
    // 計算總市值
    func calculateTotalValue() -> Double? {
        guard let avgPrice = weightedPurchasePrice else { return nil }
        return Double(totalShares) * avgPrice
    }
}

// Array 擴展，用於股票分組和計算
extension Array where Element == Stock {
    // 將相同股票分組
    func groupedBySymbol() -> [String: [Stock]] {
        Dictionary(grouping: self) { $0.symbol }
    }
    
    // 計算加權平均數據
    func calculateWeightedAverage(forBankId bankId: UUID? = nil) -> [WeightedStockInfo] {
        let stocks = bankId != nil ? self.filter { $0.bankId == bankId } : self
        
        
        let groupedStocks = stocks.groupedBySymbol()
        
        return groupedStocks.map { symbol, stocks in
            let totalShares = stocks.reduce(0) { $0 + $1.shares }
            
            // 計算加權平均股利
            let weightedDividend = stocks.reduce(0.0) { sum, stock in
                sum + (stock.dividendPerShare * Double(stock.shares))
            } / Double(totalShares)
            
            let frequency = stocks[0].frequency // 假設同一股票的發放頻率相同
            
            return WeightedStockInfo(
                symbol: symbol,
                name: stocks[0].name,
                totalShares: totalShares,
                weightedDividendPerShare: weightedDividend,
                frequency: frequency,
                details: stocks
            )
        }.sorted { $0.symbol < $1.symbol }
    }
}

