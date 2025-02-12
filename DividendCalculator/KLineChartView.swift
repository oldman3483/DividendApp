//
//  KLineChartView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/12.
//


import SwiftUI
import Charts

struct KLineChartView: View {
    let data: [KLineData]
    let maxPrice: Double
    let minPrice: Double
    
    private let volumeHeightRatio: CGFloat = 0.2
    
    var body: some View {
        VStack(spacing: 0) {
            // K線圖
            Chart {
                ForEach(data) { item in
                    // 影線
                    RectangleMark(
                        x: .value("Date", item.date),
                        yStart: .value("Low", item.low),
                        yEnd: .value("High", item.high),
                        width: 1
                    )
                    .foregroundStyle(item.candleColor)
                    
                    // K線實體
                    RectangleMark(
                        x: .value("Date", item.date),
                        yStart: .value("Open", item.open),
                        yEnd: .value("Close", item.close),
                        width: 8
                    )
                    .foregroundStyle(item.candleColor)
                }
            }
            .chartYScale(domain: [minPrice * 0.99, maxPrice * 1.01])
            .chartXAxis {
                AxisMarks(position: .bottom) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatDate(date))
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    if let price = value.as(Double.self) {
                        AxisValueLabel {
                            Text(String(format: "%.2f", price))
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 250)
            
            // 成交量圖
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Date", item.date),
                        y: .value("Volume", item.volume)
                    )
                    .foregroundStyle(item.candleColor)
                }
            }
            .frame(height: 80)
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    if let volume = value.as(Int.self) {
                        AxisValueLabel {
                            Text(volume.formattedWithComma)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color(white: 0.1))
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}
