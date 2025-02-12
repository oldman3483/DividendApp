//
//  KLineInfoCard.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/12.
//



import SwiftUI

struct KLineInfoCard: View {
    let data: KLineData
    
    var body: some View {
        VStack(spacing: 12) {
            // 日期和成交量
            HStack {
                Text(formatDate(data.date))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
                Text("成交量: \(data.volume.formattedWithComma)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            // K線主要數據
            HStack(spacing: 20) {
                PriceMetric(title: "開盤", value: data.open, color: data.candleColor)
                PriceMetric(title: "最高", value: data.high, color: .red)
                PriceMetric(title: "最低", value: data.low, color: .green)
                PriceMetric(title: "收盤", value: data.close, color: data.candleColor)
            }
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

struct PriceMetric: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Text(String(format: "%.2f", value))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
        }
    }
}
