//
//  DividendModel.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/5/2.
//

import Foundation

// 股利發放資料模型
struct DividendRecord: Codable, Identifiable {
    let id: Int
    let date: String                        // 資料日期
    let stockSymbol: String                 // 股票代號
    let dividendYear: String                // 股利年度
    let dividendPeriod: String              // 股利期間 (上半年/下半年/全年)
    let shareholdersMeetingDate: String?    // 股東會日期
    let exDividendDate: String              // 除息日期
    let exDividendReferencePrice: Double?   // 除息參考價
    let fillDividendCompletionDate: String? // 填息完成日
    let fillDividendDays: Int?              // 填息花費天數
    let cashDividendDistributionDate: String // 現金股利發放日
    let exRightsDate: String?               // 除權日期
    let exRightsReferencePrice: Double?     // 除權參考價
    let fillRightsCompletionDate: String?   // 填權完成日
    let fillRightsDays: Int?                // 填權花費天數
    let cashDividendEarnings: Double        // 盈餘配息
    let cashDividendCapitalSurplus: Double  // 資本公積配息
    let totalCashDividend: Double           // 總現金股利
    let stockDividendEarnings: Double       // 盈餘配股
    let stockDividendCapitalSurplus: Double // 資本公積配股
    let totalStockDividend: Double          // 總股票股利
    let totalDividend: Double               // 總股利合計
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case stockSymbol = "stock_symbol"
        case dividendYear = "dividend_year"
        case dividendPeriod = "dividend_period"
        case shareholdersMeetingDate = "shareholders_meeting_date"
        case exDividendDate = "ex_dividend_date"
        case exDividendReferencePrice = "ex_dividend_reference_price"
        case fillDividendCompletionDate = "fill_dividend_completion_date"
        case fillDividendDays = "fill_dividend_days"
        case cashDividendDistributionDate = "cash_dividend_distribution_date"
        case exRightsDate = "ex_rights_date"
        case exRightsReferencePrice = "ex_rights_reference_price"
        case fillRightsCompletionDate = "fill_rights_completion_date"
        case fillRightsDays = "fill_rights_days"
        case cashDividendEarnings = "cash_dividend_earnings"
        case cashDividendCapitalSurplus = "cash_dividend_capital_surplus"
        case totalCashDividend = "total_cash_dividend"
        case stockDividendEarnings = "stock_dividend_earnings"
        case stockDividendCapitalSurplus = "stock_dividend_capital_surplus"
        case totalStockDividend = "total_stock_dividend"
        case totalDividend = "total_dividend"
    }
    
    // 將除息日期轉換為 Date 對象
    var exDividendDateObj: Date? {
        // 處理日期格式 '25/01/17
        if exDividendDate == "nan" {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "'yy/MM/dd"
        return dateFormatter.date(from: exDividendDate)
    }
    
    // 將發放日期轉換為 Date 對象
    var distributionDateObj: Date? {
        if cashDividendDistributionDate == "nan" {
            return nil
        }
        
        // 處理日期格式 '25/02/20  即將發放
        let dateString = cashDividendDistributionDate.components(separatedBy: " ").first ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "'yy/MM/dd"
        return dateFormatter.date(from: dateString)
    }
}

// 股利資料回應模型
struct DividendResponse: Decodable {
    let success: Bool
    let data: [DividendRecord]
    let message: String?
}
