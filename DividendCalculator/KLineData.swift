//
//  KLineData.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/12.
//

import Foundation
import SwiftUI

struct KLineData: Identifiable {
    let id = UUID()
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
    
    var isUp: Bool {
        close >= open
    }
    
    var candleColor: Color {
        isUp ? .red : .green
    }
    
    var bodyHeight: Double {
        abs(open - close)
    }
    
    var shadowHeight: Double {
        high - low
    }
}
