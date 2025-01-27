//
//  AddStockView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import SwiftUI

struct AddStockView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    
    @State private var symbol: String = ""
    @State private var name: String = ""
    @State private var shares: String = ""
    @State private var dividendPerShare: String = ""
    @State private var frequency: Int = 4
    @State private var showAlert = false
    @State private var showSuggestions = false
    @State private var suggestions: [(symbol: String, name: String)] = []
    
    private let finMindService = FinMindService()
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("股票資訊")) {
                        VStack(alignment: .leading, spacing: 0) {
                            TextField("股票代號", text: $symbol)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onChange(of: symbol) { oldValue, newValue in
                                    if !newValue.isEmpty {
                                        searchStocks(query: newValue)
                                    } else {
                                        suggestions = []
                                        showSuggestions = false
                                    }
                                }
                            
                            if showSuggestions && !suggestions.isEmpty {
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(suggestions, id: \.symbol) { stock in
                                            Button(action: {
                                                selectStock(symbol: stock.symbol, name: stock.name)
                                            }) {
                                                HStack {
                                                    Text(stock.symbol)
                                                        .font(.headline)
                                                    Text(stock.name)
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding()
                                                .background(Color.white)
                                            }
                                            Divider()
                                        }
                                    }
                                }
                                .frame(maxHeight: 200)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                            }
                        }
                        
                        TextField("股票名稱", text: $name)
                            .disabled(true)
                        TextField("持股數量", text: $shares)
                            .keyboardType(.numberPad)
                        TextField("每股股利", text: $dividendPerShare)
                            .keyboardType(.decimalPad)
                            .disabled(true)
                    }
                }
            }
            .navigationTitle("新增股票")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("新增") {
                    addStock()
                }
            )
        }
    }
    
    private func searchStocks(query: String) {
        Task {
            // 使用新的搜尋方法
            let matchedStocks = await finMindService.searchStocks(query: query)
            await MainActor.run {
                suggestions = matchedStocks.map { (symbol: $0.symbol, name: $0.name) }
                showSuggestions = !suggestions.isEmpty
            }
        }
    }
    
    private func selectStock(symbol: String, name: String) {
        self.symbol = symbol
        self.name = name
        self.showSuggestions = false
        
        Task {
                if let dividend = await finMindService.getTaiwanStockDividend(symbol: symbol) {
                    print("Dividend received: \(dividend)")
                    await MainActor.run {
                        self.dividendPerShare = String(format: "%.2f", dividend)
                        print("Dividend set to: \(self.dividendPerShare)")
                    }
                } else {
                    print("No dividend data returned")
                }
            }
        }
    
    private func addStock() {
        guard
            !symbol.isEmpty,
            !name.isEmpty,
            let sharesInt = Int(shares),
            let dividend = Double(dividendPerShare)
        else {
            showAlert = true
            return
        }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        let stock = Stock(
            symbol: symbol,
            name: name,
            shares: sharesInt,
            dividendPerShare: dividend,
            dividendYear: currentYear,
            isHistorical: false,
            frequency: frequency
        )
        
        stocks.append(stock)
        dismiss()
    }
}
