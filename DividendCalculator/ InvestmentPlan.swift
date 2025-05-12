//
//   InvestmentPlan.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/5/8.
//


import Foundation

struct InvestmentPlan: Identifiable, Codable {
    let id: UUID
    var title: String
    var targetAmount: Double
    var currentAmount: Double
    var targetYear: Int
    var symbol: String
    var investmentYears: Int
    var investmentFrequency: Int
    var createdDate: Date
    var requiredAmount: Double
    var projectionData: [GrowthPoint]?
    
    // 計算完成百分比
    var completionPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return min(100, (currentAmount / targetAmount) * 100)
    }
    
    // 獲取頻率文字
    func getFrequencyText() -> String {
        switch investmentFrequency {
        case 1: return "年"
        case 4: return "季"
        case 12: return "月"
        default: return "期"
        }
    }
    
    // 添加 Coding keys 以確保正確編碼和解碼
    enum CodingKeys: String, CodingKey {
        case id, title, targetAmount, currentAmount, targetYear, symbol
        case investmentYears, investmentFrequency, createdDate, requiredAmount
        case projectionData
    }
    
    // 實現自定義解碼器
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        targetAmount = try container.decode(Double.self, forKey: .targetAmount)
        currentAmount = try container.decode(Double.self, forKey: .currentAmount)
        targetYear = try container.decode(Int.self, forKey: .targetYear)
        symbol = try container.decode(String.self, forKey: .symbol)
        investmentYears = try container.decode(Int.self, forKey: .investmentYears)
        investmentFrequency = try container.decode(Int.self, forKey: .investmentFrequency)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        requiredAmount = try container.decode(Double.self, forKey: .requiredAmount)
        projectionData = try container.decodeIfPresent([GrowthPoint].self, forKey: .projectionData)
    }
    
    // 實現自定義編碼器
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(targetAmount, forKey: .targetAmount)
        try container.encode(currentAmount, forKey: .currentAmount)
        try container.encode(targetYear, forKey: .targetYear)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(investmentYears, forKey: .investmentYears)
        try container.encode(investmentFrequency, forKey: .investmentFrequency)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(requiredAmount, forKey: .requiredAmount)
        try container.encodeIfPresent(projectionData, forKey: .projectionData)
    }
}
extension InvestmentPlan {
    init(
        title: String,
        targetAmount: Double,
        currentAmount: Double = 0.0,
        targetYear: Int,
        symbol: String,
        investmentYears: Int,
        investmentFrequency: Int,
        requiredAmount: Double,
        projectionData: [GrowthPoint]? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetYear = targetYear
        self.symbol = symbol
        self.investmentYears = investmentYears
        self.investmentFrequency = investmentFrequency
        self.createdDate = Date()
        self.requiredAmount = requiredAmount
        self.projectionData = projectionData
    }
}
