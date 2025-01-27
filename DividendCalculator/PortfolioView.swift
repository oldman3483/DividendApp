//
//  PortfolioView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import SwiftUI

struct PortfolioView: View {
    @Binding var stocks: [Stock]
    @Binding var showingAddSheet: Bool
    
    var body: some View {
        List {
            ForEach(stocks) { stock in
                VStack(alignment: .leading) {
                    HStack {
                        Text(stock.symbol)
                            .font(.headline)
                        Text(stock.name)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("持股：\(stock.shares)")
                        Spacer()
                        Text("股利：\(String(format: "%.2f", stock.dividendPerShare))")
                        Spacer()
                        Text("年化：\(String(format: "%.0f", stock.calculateAnnualDividend()))")
                    }
                    .font(.subheadline)
                }
            }
            .onDelete(perform: deleteStocks)
        }
        .navigationTitle("投資組合")
        .toolbar {
            Button {
                showingAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    func deleteStocks(at offsets: IndexSet) {
        stocks.remove(atOffsets: offsets)
    }
}
