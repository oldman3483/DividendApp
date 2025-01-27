//
//  SearchResultView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/22.
//

import SwiftUI

struct SearchResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    
    let stockService = LocalStockService()
    @State private var searchResults: [SearchStock] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    let searchText: String
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("搜尋中...")
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else if searchResults.isEmpty {
                    Text("找不到符合的股票")
                } else {
                    List {
                        ForEach(searchResults, id: \.symbol) { stock in
                            NavigationLink(destination: StockDetailView(stock: stock)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(stock.symbol)
                                            .font(.headline)
                                        Text(stock.name)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                        .onTapGesture {
                                            addStockToPortfolio(stock)
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("搜尋結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            .task {
                await searchStocks()
            }
        }
    }
}

// 闊感中添加功能的方法
extension SearchResultView {
    func searchStocks() async {
        // 重置狀態
        isLoading = true
        errorMessage = nil
        searchResults = []
                
        let matchedStocks = await stockService.searchStocks(query: searchText)
        
        await MainActor.run {
            searchResults = matchedStocks
            isLoading = false
        }
    }
    
    func addStockToPortfolio(_ stock: SearchStock) {
        Task {
            if let dividend = await stockService.getTaiwanStockDividend(symbol: stock.symbol) {
                let newStock = Stock(
                    symbol: stock.symbol,
                    name: stock.name,
                    shares: 0, // 用戶需要手動輸入
                    dividendPerShare: dividend,
                    dividendYear: Calendar.current.component(.year, from: Date()),
                    isHistorical: false,
                    frequency: 1 // 預設為年配
                )
                
                await MainActor.run {
                    stocks.append(newStock)
                    dismiss()
                }
            } else {
                await MainActor.run {
                    errorMessage = "無法獲取股利資訊，請手動輸入"
                }
            }
        }
    }
}
