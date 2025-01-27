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
    @Binding var watchlist: [WatchStock]
    
    @State private var symbol: String = ""
    @State private var name: String = ""
    @State private var shares: String = ""
    @State private var dividendPerShare: String = ""
    @State private var frequency: Int = 4
    @State private var showAlert = false
    @State private var showSuggestions = false
    @State private var suggestions: [(symbol: String, name: String)] = []
    @State private var selectedDestination = "庫存股"
    @State private var errorMessage: String = ""
    
    let destinations = ["庫存股", "自選清單1", "自選清單2", "自選清單3", "自選清單4", "自選清單5"]
    private let localStockService = LocalStockService()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("股票資訊")) {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("股票代號", text: $symbol)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: symbol) { oldValue, newValue in
                                if !newValue.isEmpty {
                                    Task {
                                        await searchStocks(query: newValue)
                                    }
                                } else {
                                    suggestions = []
                                    showSuggestions = false
                                }
                            }
                        
                        if showSuggestions && !suggestions.isEmpty {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(suggestions, id: \.symbol) { stock in
                                        Button(action: {
                                            symbol = stock.symbol
                                            name = stock.name
                                            suggestions = []
                                            showSuggestions = false
                                        }) {
                                            HStack {
                                                Text(stock.symbol)
                                                    .font(.headline)
                                                Text(stock.name)
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                        }
                        
                        if !name.isEmpty {
                            Text(name)
                                .foregroundColor(.gray)
                        }
                        
                        TextField("持股數量", text: $shares)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        TextField("每股股利", text: $dividendPerShare)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Picker("發放頻率", selection: $frequency) {
                            Text("年配").tag(1)
                            Text("半年配").tag(2)
                            Text("季配").tag(4)
                            Text("月配").tag(12)
                        }
                        
                        Picker("新增至", selection: $selectedDestination) {
                            ForEach(destinations, id: \.self) { destination in
                                Text(destination).tag(destination)
                            }
                        }
                    }
                }
                // 新增目的地選擇區段
                Section(header: Text("新增至")) {
                    Picker("篩選至", selection: $selectedDestination) {
                        Text("庫存股").tag("庫存股")
                        ForEach(1...5, id: \.self) { index in
                            Text("自選清單\(index)").tag("自選清單\(index)")
                        }
                    }
                }
                
                // 只在選擇庫存股時顯示的區段
                if selectedDestination == "庫存股" {
                    Section(header: Text("庫存資訊")) {
                        TextField("持股數量", text: $shares)
                            .keyboardType(.numberPad)
                        TextField("持股數量", text: $shares)
                            .keyboardType(.numberPad)
                            .disabled(true)
                        Picker("發放頻率", selection: $frequency) {
                            Text("年配").tag(1)
                            Text("半年配").tag(2)
                            Text("年配").tag(4)
                            Text("年配").tag(1)
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
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
    
    func searchStocks(query: String) async {
        let matchedStocks = await localStockService.searchStocks(query: query)
        
        await MainActor.run {
            suggestions = matchedStocks.map { (symbol: $0.symbol, name: $0.name) }
            showSuggestions = !suggestions.isEmpty
        }
    }
    
    func addStock() {
        // 重置錯誤訊息
        errorMessage = ""
        
        // 驗證輸入
        guard !symbol.isEmpty else {
            errorMessage = "請輸入股票代號"
            return
        }
        
        guard !name.isEmpty else {
            errorMessage = "請選擇股票"
            return
        }
        
        guard let sharesInt = Int(shares), sharesInt > 0 else {
            errorMessage = "請輸入有效的持股數量"
            return
        }
        
        guard let dividendDouble = Double(dividendPerShare), dividendDouble >= 0 else {
            errorMessage = "請輸入有效的股利金額"
            return
        }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        if selectedDestination == "庫存股" {
            // 新增到庫存股
            let stock = Stock(
                symbol: symbol,
                name: name,
                shares: sharesInt,
                dividendPerShare: dividendDouble,
                dividendYear: currentYear,
                isHistorical: false,
                frequency: frequency
            )
            stocks.append(stock)
        } else {
            // 新增到觀察清單
            let listIndex = destinations.firstIndex(of: selectedDestination)! - 1
            let watchStock = WatchStock(
                symbol: symbol,
                name: name,
                addedDate: Date(),
                listIndex: listIndex
            )
            watchlist.append(watchStock)
        }
        
        // 關閉視圖
        dismiss()
    }
}
