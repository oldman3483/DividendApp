//
//  Stock.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import Foundation

struct Stock: Identifiable, Codable, Equatable {
    var id = UUID()
    let symbol: String        // 股票代號
    let name: String         // 公司名稱
    var shares: Int          // 持股數量
    var dividendPerShare: Double  // 每股股利
    let dividendYear: Int    // 股利年度
    let isHistorical: Bool   // 是否為歷史股利
    var frequency: Int       // 發放頻率（1=年配, 2=半年配, 4=季配, 12=月配）
    var purchaseDate: Date   // 新增：購買日期

    
    // 为 Codable 协议提供自定义编码和解码
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
    }
    
    // 计算年化股利
    func calculateAnnualDividend() -> Double {
        return Double(shares) * dividendPerShare * Double(frequency)
    }
    
    // 自定义解码初始化器
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
    }
    
    // 自定义编码方法
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
        purchaseDate: Date = Date()
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
    }
    static func == (lhs: Stock, rhs: Stock) -> Bool {
        return lhs.id == rhs.id
    }
}
