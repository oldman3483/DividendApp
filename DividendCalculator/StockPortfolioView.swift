//
//  StockPortfolioView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/24.
//

import SwiftUI

struct StockPortfolioView: View {
    @Binding var stocks: [Stock]
    @Binding var isEditing: Bool
    
    var body: some View {
        List {
            ForEach(stocks) { stock in
                HStack {
                    VStack(alignment: .leading) {
                        Text(stock.symbol)
                            .font(.headline)
                        Text(stock.name)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("持股：\(stock.shares)")
                        Text("股利：\(String(format: "%.2f", stock.dividendPerShare))")
                        Text("年化：\(String(format: "%.0f", stock.calculateAnnualDividend()))")
                    }
                    .font(.subheadline)
                }
            }
            .onDelete { offsets in
                stocks.remove(atOffsets: offsets)
            }
            .onMove { from, to in
                stocks.move(fromOffsets: from, toOffset: to)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("庫存股")
                    .font(.system(size: 40, weight: .bold))
            }
            
                
            
        }
    }
}

