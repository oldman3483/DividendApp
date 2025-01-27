//
//  StockDetailView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/24.
//

import SwiftUI

struct StockDetailView: View {
    let stock: SearchStock
    let stockService = LocalStockService()
    @State private var dividend: Double?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本資訊卡片
                GroupBox(label: Text("基本資訊").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("股票代號：")
                            Text(stock.symbol)
                                .foregroundColor(.blue)
                        }
                        HStack {
                            Text("公司名稱：")
                            Text(stock.name)
                        }
                        HStack {
                            Text("每股股利：")
                            if let dividend = dividend {
                                Text(String(format: "%.2f", dividend))
                                    .foregroundColor(.green)
                            } else {
                                Text("尚無資料")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                }
                .padding(.horizontal)
                
                // 這裡可以加入更多資訊區塊
                // 例如：股利政策、歷史股利等
            }
        }
        .navigationTitle("\(stock.name)(\(stock.symbol))")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // 載入股利資訊
            if let dividendInfo = await stockService.getTaiwanStockDividend(symbol: stock.symbol) {
                dividend = dividendInfo
            }
        }
    }
}
