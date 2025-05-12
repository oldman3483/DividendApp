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
    @Binding var watchlist: [WatchStock]
    @Binding var banks: [Bank]
    
    let stockService = LocalStockService()
    @State private var searchResults: [SearchStock] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    
    let searchText: String
    let bankId: UUID?
    
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
                            NavigationLink(destination: AddStockView(
                                stocks: $stocks,
                                watchlist: $watchlist,
                                banks: $banks,
                                initialSymbol: stock.symbol,
                                initialName: stock.name,
                                bankId: bankId ?? banks.first?.id ?? UUID(),
                                isFromBankPortfolio: false
                            )) {
                                VStack(alignment: .leading) {
                                    Text(stock.symbol)
                                        .font(.headline)
                                    Text(stock.name)
                                        .foregroundColor(.gray)
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
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .task {
                await searchStocks()
            }
        }
    }
    
    func searchStocks() async {
        isLoading = true
        errorMessage = nil
        searchResults = []
        
        let matchedStocks = await stockService.searchStocks(query: searchText)
        
        await MainActor.run {
            searchResults = matchedStocks
            isLoading = false
        }
    }
}
