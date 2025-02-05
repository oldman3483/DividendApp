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
    let bankId: UUID
    
    @State private var shares: String = ""
    @State private var dividendPerShare: String = ""
    @State private var frequency: Int?
    @State private var selectedDestination = "銀行"
    @State private var errorMessage: String = ""
    @State private var purchaseDate = Date()
    @State private var purchasePrice: String = ""
    @State private var isLoadingPrice: Bool = false
    @State private var selectedBankId: UUID
    @State private var selectedWatchlist: String

    
    private let localStockService = LocalStockService()
    
    
    // 取得所有銀行列表
    @State private var banks: [Bank] = {
        if let savedBanks = UserDefaults.standard.data(forKey: "banks"),
            let decodedBanks = try? JSONDecoder().decode([Bank].self, from: savedBanks) {
            return decodedBanks
        }
        return []
    }()
    
    // 新增取得觀察清單名稱的計算屬性
    private var watchlistNames: [String] {
        UserDefaults.standard.stringArray(forKey: "watchlistNames") ?? ["自選清單1"]
    }
    
    // 新增一個帶初始值的建構函式
    
    init(
        stocks: Binding<[Stock]>,
        watchlist: Binding<[WatchStock]>,
        initialSymbol: String = "",
        initialName: String = "",
        bankId: UUID
        
    ) {
        self._stocks = stocks
        self._watchlist = watchlist
        self.initialSymbol = initialSymbol
        self.initialName = initialName
        self.bankId = bankId
        
        
        let defaultWatchlist = UserDefaults.standard.stringArray(forKey: "watchlistNames")?[0] ?? "自選清單1"
        _selectedWatchlist = State(initialValue: defaultWatchlist)
        _selectedBankId = State(initialValue: bankId)
        
        if let savedBanks = UserDefaults.standard.data(forKey: "banks"),
           let decodedBanks = try? JSONDecoder().decode([Bank].self, from: savedBanks) {
            _banks = State(initialValue: decodedBanks)
        }
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
                        Text("銀行").tag("銀行")
                        Text("觀察清單").tag("觀察清單")
                    }
                    
                    if selectedDestination == "銀行" {
                        Picker("選擇銀行", selection: $selectedBankId) {
                            ForEach(banks) { bank in
                                Text(bank.name).tag(bank.id)
                            }
                        }
                    } else {
                        Picker("選擇觀察清單", selection: $selectedWatchlist) {
                            ForEach(watchlistNames, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                    }
                }
                
                // 第三個區段：只在選擇庫存股時顯示
                if selectedDestination == "銀行" {
                    Section(header: Text("庫存資訊")) {
                        TextField("持股數量", text: $shares)
                            .keyboardType(.numberPad)
                        
                        HStack {
                            Text("每股股利")
                            Spacer()
                            Text(dividendPerShare.isEmpty ? "讀取中..." : "$\(dividendPerShare)")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("發放頻率")
                            Spacer()
                            Text(getFrequencyText(frequency))
                            .foregroundColor(.gray)
                        }
                        
                        
                        DatePicker(
                            "買入日期",
                            selection: $purchaseDate,
                            displayedComponents: .date
                        )
                        .onChange(of: purchaseDate) { oldValue, newValue in
                            Task {
                                await loadStockPrice()
                            }
                        }
                        
                        HStack {
                            Text("收盤價")
                            Spacer()
                            if isLoadingPrice {
                                ProgressView()
                            } else {
                                Text(purchasePrice.isEmpty ? "讀取中..." : "$\(purchasePrice)")
                                    .foregroundColor(.gray)
                            }
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
                .disabled(selectedDestination == "銀行" && shares.isEmpty)
            )
        }
        .task {
            
            
            if let dividend = await localStockService.getTaiwanStockDividend(symbol: initialSymbol) {
                dividendPerShare = String(format: "%.2f", dividend)
            }
            if let freq = await localStockService.getTaiwanStockFrequency(symbol: initialSymbol) {
                frequency = freq
            }
            await loadStockPrice()
        }
    }

    
    private func loadStockPrice() async {
        isLoadingPrice = true
        if let price = await localStockService.getStockPrice(symbol: initialSymbol, date: purchaseDate) {
            purchasePrice = String(format: "%.2f", price)
        }
        isLoadingPrice = false
    }
    
    private func getFrequencyText(_ frequency: Int?) -> String {
        guard let frequency = frequency else {
            return "讀取中..."
        }
        
        switch frequency {
        case 1:
            return "年配"
        case 2:
            return "半年配"
        case 4:
            return "季配"
        case 12:
            return "月配"
        default:
            return "未知"
        }
    }
    
    
    private func addStock() {
        
        print("Adding stock with bankId: \(bankId)")

        // 重置錯誤訊息
        errorMessage = ""
        
        
        // 根據選擇的目的地執行不同的驗證和新增邏輯
        if selectedDestination == "銀行" {
            // 驗證庫存股特有的欄位
            guard let sharesInt = Int(shares), sharesInt > 0 else {
                errorMessage = "請輸入有效的持股數量"
                return
            }
            
            guard let dividendDouble = Double(dividendPerShare), dividendDouble >= 0 else {
                errorMessage = "請輸入有效的股利金額"
                return
            }
            
            guard let unwrappedFrequency = frequency else {
                errorMessage = "無法取得發放頻率"
                return
            }
            guard let priceDouble = Double(purchasePrice), priceDouble > 0 else {
                // 修改這裡
                errorMessage = "請輸入有效的股價"
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
                frequency: unwrappedFrequency,
                purchaseDate: purchaseDate,
                purchasePrice: priceDouble,
                bankId: bankId
                
            )
            stocks.append(stock)
            print("Stock added: \(stock)")
            
        } else {
            // 新增到觀察清單
            let listIndex = watchlistNames.firstIndex(of: selectedWatchlist) ?? 0
            
            
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
