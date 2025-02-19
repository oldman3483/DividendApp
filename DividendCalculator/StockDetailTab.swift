//
//  StockDetailTab.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/12.
//

import Foundation

enum StockDetailTab: String, CaseIterable {
    case market = "行情"
    case kline = "K線"
//    case analysis = "評析"
    case news = "新聞"
    case chip = "籌碼"
    case basic = "基本"
    case financial = "財務"
    
    var timeRanges: [String] {
        switch self {
        case .market:
            return ["當日", "五日", "近月", "三月", "六月", "一年", "五年"]
        case .kline:
            return ["日K", "週K", "月K", "季K", "年K"]
//        case .analysis:
//            return ["技術面", "基本面", "籌碼面"]
        case .news:
            return ["即時", "今日", "本週", "本月"]
        case .chip:
            return ["當日", "三日", "五日", "十日", "月"]
        case .basic:
            return ["基本資料", "股利政策", "董監持股"]
        case .financial:
            return ["獲利能力", "營運績效", "償債能力"]
        }
    }
}
