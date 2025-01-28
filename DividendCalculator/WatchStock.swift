//
//  WatchStock.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/25.
//

import Foundation


struct WatchStock: Identifiable, Codable, Equatable {
    let id: UUID
    let symbol: String
    let name: String
    let addedDate: Date
    let listNames: Int // 所屬自選清單編號
    
    init(id: UUID = UUID(), symbol: String, name: String, addedDate: Date = Date(), listIndex: Int) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.addedDate = addedDate
        self.listNames = listIndex
    
    
    }
    static func == (lhs: WatchStock, rhs: WatchStock) -> Bool {
        return lhs.id == rhs.id
    }
}

