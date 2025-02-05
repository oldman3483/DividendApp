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
    
    let stockService = LocalStockService()
    @State private var searchResults: [SearchStock] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showingAddStockView = false
    @State private var selectedSymbol: String = ""
    @State private var selectedName: String = ""
    
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
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(stock.symbol)
                                        .font(.headline)
                                    Text(stock.name)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Button(action: {
                                    print("選擇股票: \(stock.symbol) \(stock.name)")
                                    selectedSymbol = stock.symbol
                                    selectedName = stock.name
                                    showingAddStockView = true
                                }) {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddStockView) {
                NavigationStack{
                    AddStockView(
                        stocks: $stocks,
                        watchlist: $watchlist,
                        initialSymbol: selectedSymbol,
                        initialName: selectedName,
                        bankId: bankId ?? UUID()
                    )
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
            .onChange(of: showingAddStockView) { oldValue, newValue in
                print("showingAddStockView: \(newValue)") // 添加調試輸出
                print("selectedSymbol: \(selectedSymbol)") // 添加調試輸出
                print("selectedName: \(selectedName)") // 添加調試輸出
                
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

#Preview {
    ContentView()
}



