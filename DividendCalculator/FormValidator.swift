//
//  FormValidator.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/14.
//

import Foundation
import SwiftUI

// MARK: - 通用的驗證結果
enum ValidationResult {
    case success
    case failure(String)
}

// MARK: - 驗證規則協議
protocol ValidationRule {
    func validate(_ value: String) -> ValidationResult
}

// MARK: - 具體的驗證規則
struct NotEmptyRule: ValidationRule {
    let fieldName: String
    
    func validate(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? .failure("\(fieldName)不能為空") : .success
    }
}

struct UniqueNameRule<T>: ValidationRule {
    let fieldName: String
    let items: [T]
    let getValue: (T) -> String
    let excludeId: UUID?
    
    func validate(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let exists = items.contains { item in
            if let excludeId = excludeId, let identifiable = item as? any Identifiable {
                return getValue(item) == trimmed && identifiable.id as? UUID != excludeId
            }
            return getValue(item) == trimmed
        }
        return exists ? .failure("已存在相同\(fieldName)") : .success
    }
}

struct NumberRule: ValidationRule {
    let fieldName: String
    let minValue: Int
    
    func validate(_ value: String) -> ValidationResult {
        guard let number = Int(value) else {
            return .failure("請輸入有效的\(fieldName)")
        }
        return number >= minValue ? .success : .failure("\(fieldName)必須大於或等於\(minValue)")
    }
}

// MARK: - 表單驗證器
class FormValidator {
    static func validate(_ value: String, rules: [ValidationRule]) -> ValidationResult {
        for rule in rules {
            let result = rule.validate(value)
            if case .failure = result {
                return result
            }
        }
        return .success
    }
    
    // MARK: - 銀行表單驗證
    static func validateBankName(_ name: String, existingBanks: [Bank], excludeId: UUID? = nil) -> ValidationResult {
        let rules: [ValidationRule] = [
            NotEmptyRule(fieldName: "銀行名稱"),
            UniqueNameRule(fieldName: "名稱", items: existingBanks, getValue: { $0.name }, excludeId: excludeId)
        ]
        return validate(name, rules: rules)
    }
    
    // MARK: - 股票表單驗證
    static func validateShares(_ shares: String) -> ValidationResult {
        let rules: [ValidationRule] = [
            NotEmptyRule(fieldName: "持股數量"),
            NumberRule(fieldName: "持股數量", minValue: 1)
        ]
        return validate(shares, rules: rules)
    }
    
    static func validateStockAddition(
        shares: String,
        symbol: String,
        watchlist: [WatchStock],
        selectedWatchlist: String
    ) -> ValidationResult {
        // 驗證持股數量
        if case .failure(let message) = validateShares(shares) {
            return .failure(message)
        }
        
        // 驗證是否已在觀察清單中
        let exists = watchlist.contains {
            $0.symbol == symbol && $0.listName == selectedWatchlist
        }
        if exists {
            return .failure("此股票已在觀察清單中")
        }
        
        return .success
    }
}
