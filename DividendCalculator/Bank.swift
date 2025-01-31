//
//  Bank.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/31.
//


import Foundation

struct Bank: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var createdDate: Date
    
    init(id: UUID = UUID(), name: String, createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.createdDate = createdDate
    }
    
    static func == (lhs: Bank, rhs: Bank) -> Bool {
        return lhs.id == rhs.id
    }
}
