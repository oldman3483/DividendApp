//
//  StockService.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import Foundation

protocol StockServiceProtocol {
    func getStockName(_ symbol: String) async throws -> String?
    func getDividendInfo(_ symbol: String) async throws -> DividendInfo
}

struct DividendInfo {
    let amount: Double
    let year: Int
    let isHistorical: Bool
}

class StockService: StockServiceProtocol {
    private let finMindService = FinMindService()
    
    func getStockName(_ symbol: String) async throws -> String? {
        return try await finMindService.getTaiwanStockInfo(symbol: symbol)
    }
    
    func getDividendInfo(_ symbol: String) async throws -> DividendInfo {
        if let dividend = try await finMindService.getTaiwanStockDividend(symbol: symbol) {
            let currentYear = Calendar.current.component(.year, from: Date())
            return DividendInfo(
                amount: dividend,
                year: currentYear,
                isHistorical: false
            )
        }
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "無法取得股利資訊"])
    }
}
