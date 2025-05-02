//
//  DividendModel.swift
//  DividendCalculator
//

import Foundation

// 股利發放資料模型
struct DividendRecord: Codable, Identifiable {
    let id: String
    let date: String                        // 資料日期
    let stock_symbol: String                // 股票代號
    let dividend_year: String              // 股利年度
    let dividend_period: String             // 股利期間 (上半年/下半年/全年)
    let shareholders_meeting_date: String  // 股東會日期
    let ex_dividend_date: String           // 除息日期
    
    
    
    let ex_dividend_reference_price: Double?    // 除息參考價
    let fill_dividend_completion_date: String? // 填息完成日
    let fill_dividend_days: Int?             // 填息花費天數
    let cash_dividend_distribution_date: String? // 現金股利發放日
    let ex_rights_date: String?              // 除權日期
    let ex_rights_reference_price: Double?      // 除權參考價
    let fill_rights_completion_date: String? // 填權完成日
    let fill_rights_days: Int?               // 填權花費天數
    let cash_dividend_earnings: Double?      // 盈餘配息
    let cash_dividend_capital_surplus: Double?  // 資本公積配息
    let total_cash_dividend: Double          // 總現金股利
    let stock_dividend_earnings: Double?        // 盈餘配股
    let stock_dividend_capital_surplus: Double? // 資本公積配股
    let total_stock_dividend: Double?           // 總股票股利
    let total_dividend: Double               // 總股利合計
    
    
    
    // 添加計算屬性以符合 camelCase 命名風格
    var dividendYear: String {
        return dividend_year
    }
    
    var dividendPeriod: String {
        return dividend_period
    }
    
    var exDividendDate: String {
        return ex_dividend_date
    }
    
    var exDividendReferencePrice: Double? {
            return ex_dividend_reference_price
        }
    
    var cashDividendDistributionDate: String {
        return cash_dividend_distribution_date ?? "未知"
    }
    
    var totalCashDividend: Double {
        return total_cash_dividend
    }
    
    var totalDividend: Double {
        return total_dividend
    }
    
    var stockSymbol: String {
        return stock_symbol
    }
    
    // 將除息日期轉換為 Date 對象
    var exDividendDateObj: Date? {
        if ex_dividend_date == "nan" || ex_dividend_date.isEmpty {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "'yy/MM/dd"
        return dateFormatter.date(from: ex_dividend_date)
    }
    
    var distributionDateObj: Date? {
        guard let distributionDate = cash_dividend_distribution_date else {
            return nil
        }
        
        if distributionDate == "nan" || distributionDate.isEmpty {
            return nil
        }
        
        let dateString = distributionDate.components(separatedBy: " ").first ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "'yy/MM/dd"
        return dateFormatter.date(from: dateString)
    }
}

// 用於錯誤響應的解碼
struct ErrorResponse: Decodable {
    let success: Bool
    let message: String
}

// 股利資料回應模型
struct DividendResponse: Decodable {
    var success: Bool
    var data: [DividendRecord]
    let message: String?
    
    // 添加 CodingKeys 枚舉
    private enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
    }
    
    // 添加自定義解碼初始化器來處理多種可能的格式
    init(from decoder: Decoder) throws {
        do {
            // 首先嘗試解析為對象
            let container = try decoder.container(keyedBy: CodingKeys.self)
            success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? true
            data = try container.decode([DividendRecord].self, forKey: .data)
            message = try container.decodeIfPresent(String.self, forKey: .message)
        } catch {
            do {
                // 嘗試直接解析為數組
                let container = try decoder.singleValueContainer()
                data = try container.decode([DividendRecord].self)
                success = true
                message = nil
            } catch let arrayError {
                print("嘗試解析為數組失敗: \(arrayError)")
                throw arrayError
            }
        }
    }
    
    // 添加一個自定義初始化器用於創建包裝響應
    init(success: Bool, data: [DividendRecord], message: String?) {
        self.success = success
        self.data = data
        self.message = message
    }
}
