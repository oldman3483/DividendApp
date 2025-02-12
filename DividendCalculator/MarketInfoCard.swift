//
//  MarketInfoCard.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/12.
//


import SwiftUI

struct MarketInfoCard: View {
    let price: Double
    let change: Double
    let changePercentage: Double
    let high: Double
    let low: Double
    let volume: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // 主要價格
            HStack(alignment: .lastTextBaseline) {
                Text(String(format: "%.2f", price))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(change >= 0 ? .red : .green)
                
                HStack(spacing: 2) {
                    Text(String(format: "%+.2f", change))
                    Text(String(format: "(%.2f%%)", changePercentage))
                }
                .font(.system(size: 17))
                .foregroundColor(change >= 0 ? .red : .green)
                
                Spacer()
            }
            
            // 數據網格
            HStack(spacing: 16) {
                MetricView(title: "最高", value: String(format: "%.2f", high), color: .red)
                MetricView(title: "最低", value: String(format: "%.2f", low), color: .green)
                MetricView(title: "總量", value: volume.formattedWithComma, color: .white)
            }
            .padding(.top, 2)
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(10)
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
