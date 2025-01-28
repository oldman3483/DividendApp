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
    
    let initialSymbol: String
    let initialName: String
    
    @State private var shares: String = ""
    @State private var dividendPerShare: String = ""
    @State private var frequency: Int = 4
    @State private var selectedDestination = "庫存股"
    @State private var errorMessage: String = ""
    
    private let localStockService = LocalStockService()
    
    // 新增取得觀察清單名稱的計算屬性
    private var watchlistNames: [String] {
        UserDefaults.standard.stringArray(forKey: "watchlistNames") ?? ["自選清單1"]
        }
    
    // 新增一個帶初始值的建構函式
    
    init(
        stocks: Binding<[Stock]>,
        watchlist: Binding<[WatchStock]>,
        initialSymbol: String = "",
        initialName: String = ""
        
    ) {
        self._stocks = stocks
        self._watchlist = watchlist
        self.initialSymbol = initialSymbol
        self.initialName = initialName
        
 
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 第一個區段：股票資訊
                Section(header: Text("股票資訊")) {
                    HStack{
                        Text ("股票代號：")
                        Text (initialSymbol)
                            .foregroundColor(.blue)
                    }
                    HStack{
                        Text ("公司名稱：")
                        Text (initialName)
                            .foregroundColor(.gray)
                    }
                }
                
                // 第二個區段：選擇目的地
                Section(header: Text("存入清單")) {
                    Picker("新增至", selection: $selectedDestination) {
                        Text("庫存股").tag("庫存股")
                        ForEach(watchlistNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
                
                // 第三個區段：只在選擇庫存股時顯示
                if selectedDestination == "庫存股" {
                    Section(header: Text("庫存資訊")) {
                        TextField("持股數量", text: $shares)
                            .keyboardType(.numberPad)
                        
                        TextField("每股股利", text: $dividendPerShare)
                            .keyboardType(.decimalPad)
                            .disabled(true)
                        
                        Picker("發放頻率", selection: $frequency) {
                            Text("年配").tag(1)
                            Text("半年配").tag(2)
                            Text("季配").tag(4)
                            Text("月配").tag(12)
                        }
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
        .task {
            if let dividend = await localStockService.getTaiwanStockDividend(symbol: initialSymbol) {
                dividendPerShare = String(format: "%.2f", dividend)
            }
        }
    }
    
    
    
    private func addStock() {
        // 重置錯誤訊息
        errorMessage = ""
        
        
        // 根據選擇的目的地執行不同的驗證和新增邏輯
        if selectedDestination == "庫存股" {
            // 驗證庫存股特有的欄位
            guard let sharesInt = Int(shares), sharesInt > 0 else {
                errorMessage = "請輸入有效的持股數量"
                return
            }
            
            guard let dividendDouble = Double(dividendPerShare), dividendDouble >= 0 else {
                errorMessage = "請輸入有效的股利金額"
                return
            }
            
            // 新增到庫存股
            let stock = Stock(
                id: UUID(),
                symbol: initialSymbol,
                name: initialName,
                shares: sharesInt,
                dividendPerShare: dividendDouble,
                dividendYear: Calendar.current.component(.year, from: Date()),
                isHistorical: false,
                frequency: frequency
            )
            stocks.append(stock)
        } else {
            // 新增到觀察清單
            let listIndex = watchlistNames.firstIndex(of: selectedDestination) ?? 0
            
            
            // 檢查是否已存在於該觀察清單
            if !watchlist.contains(
                where: { $0.symbol == initialSymbol && $0.listNames == listIndex }) {
                let watchStock = WatchStock(
                    symbol: initialSymbol,
                    name: initialName,
                    addedDate: Date(),
                    listIndex: listIndex
                )
                watchlist.append(watchStock)
            } else {
                errorMessage = "此股票已在該觀察清單中"
                return
            }
        }
        
        // 完成後關閉視圖
        dismiss()
        }
    }



#Preview {
    ContentView()
}
