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
    @Binding var banks: [Bank]
    
    let initialSymbol: String
    let initialName: String
    let bankId: UUID
    let isFromBankPortfolio: Bool

    
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
    private let destinations = ["銀行", "觀察清單"]
    
    init(stocks: Binding<[Stock]>, watchlist: Binding<[WatchStock]>, banks: Binding<[Bank]>,
         initialSymbol: String = "", initialName: String = "", bankId: UUID, isFromBankPortfolio: Bool = false) {
        self._stocks = stocks
        self._watchlist = watchlist
        self._banks = banks
        self.initialSymbol = initialSymbol
        self.initialName = initialName
        self.bankId = bankId
        self.isFromBankPortfolio = isFromBankPortfolio
        
        let defaultWatchlist = UserDefaults.standard.stringArray(forKey: "watchlistNames")?[0] ?? "自選清單1"
        _selectedWatchlist = State(initialValue: defaultWatchlist)
        _selectedBankId = State(initialValue: bankId)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 股票信息區塊
                Section(header: Text("股票資訊")) {
                    HStack {
                        Text("股票代號：")
                        Text(initialSymbol)
                            .foregroundColor(.blue)
                    }
                    HStack {
                        Text("公司名稱：")
                        Text(initialName)
                            .foregroundColor(.gray)
                    }
                }
                
                // 根據來源決定是否顯示選擇目的地區塊

                if !isFromBankPortfolio {
                    
                    Section(header: Text("新增至")) {
                        Picker("選擇目標", selection: $selectedDestination) {
                            ForEach(destinations, id: \.self) { destination in
                                Text(destination)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if selectedDestination == "銀行" {
                            // 銀行列表選擇器
                            Picker("選擇銀行", selection: $selectedBankId) {
                                ForEach(banks) { bank in
                                    Text(bank.name).tag(bank.id)
                                }
                            }
                        } else {
                            // 觀察清單選擇器
                            let watchlistNames = UserDefaults.standard.stringArray(forKey: "watchlistNames") ?? ["自選清單1"]
                            Picker("選擇觀察清單", selection: $selectedWatchlist) {
                                ForEach(watchlistNames, id: \.self) { listName in
                                    Text(listName)
                                }
                            }
                        }
                    }
                }
                
                // 只在選擇"銀行"時或從銀行投資組合進入時顯示交易和股利資訊
                if selectedDestination == "銀行" || isFromBankPortfolio {
                    // 交易信息區塊
                    Section(header: Text("交易資訊")) {
                        TextField("持股數量", text: $shares)
                            .keyboardType(.numberPad)
                        
                        DatePicker("買入日期", selection: $purchaseDate, displayedComponents: .date)
                        
                        if !purchasePrice.isEmpty {
                            HStack {
                                Text("股價")
                                Spacer()
                                Text("$\(purchasePrice)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // 股利信息區塊
                    Section(header: Text("股利資訊")) {
                        if !dividendPerShare.isEmpty {
                            HStack {
                                Text("每股股利")
                                Spacer()
                                Text("$\(dividendPerShare)")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if let freq = frequency {
                            HStack {
                                Text("發放頻率")
                                Spacer()
                                Text(getFrequencyText(freq))
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新增") {
                        addStock()
                    }
                    .disabled(isFromBankPortfolio || selectedDestination == "銀行" ? shares.isEmpty : false)
                }
            }
        }
        .task {
            await loadStockData()
        }
//        .dismissKeyboardOnTap()
    }
    
    private func getFrequencyText(_ frequency: Int) -> String {
        switch frequency {
        case 1: return "年配"
        case 2: return "半年配"
        case 4: return "季配"
        case 12: return "月配"
        default: return "未知"
        }
    }
    
    private func loadStockData() async {
        if let dividend = await localStockService.getTaiwanStockDividend(symbol: initialSymbol) {
            dividendPerShare = String(format: "%.2f", dividend)
        }
        if let freq = await localStockService.getTaiwanStockFrequency(symbol: initialSymbol) {
            frequency = freq
        }
        await loadStockPrice()
    }
    
    private func loadStockPrice() async {
        isLoadingPrice = true
        if let price = await localStockService.getStockPrice(symbol: initialSymbol, date: purchaseDate) {
            purchasePrice = String(format: "%.2f", price)
        }
        isLoadingPrice = false
    }
    
    private func addStock() {
        if selectedDestination == "銀行" {
            addToBank()
        } else {
            addToWatchlist()
        }
    }
    
    private func addToBank() {
        guard let sharesInt = Int(shares) else {
            errorMessage = "請輸入有效的持股數量"
            return
        }
        
        guard let dividendDouble = Double(dividendPerShare) else {
            errorMessage = "無法取得股利資訊"
            return
        }
        
        guard let priceDouble = Double(purchasePrice) else {
            errorMessage = "無法取得股價資訊"
            return
        }
        
        let newStock = Stock(
            symbol: initialSymbol,
            name: initialName,
            shares: sharesInt,
            dividendPerShare: dividendDouble,
            dividendYear: Calendar.current.component(.year, from: Date()),
            frequency: frequency ?? 1,
            purchaseDate: purchaseDate,
            purchasePrice: priceDouble,
            bankId: selectedBankId
        )
        
        stocks.append(newStock)
        dismiss()
    }
    
    private func addToWatchlist() {
        // 获取选中的观察清单索引
        let watchlistNames = UserDefaults.standard.stringArray(forKey: "watchlistNames") ?? ["自選清單1"]
        let selectedIndex = watchlistNames.firstIndex(of: selectedWatchlist) ?? 0
        
        // 检查是否已存在
        let exists = watchlist.contains { $0.symbol == initialSymbol && $0.listName == selectedWatchlist }
        
        if exists {
            errorMessage = "此股票已在觀察清單中"
            return
        }
        
        let newWatchStock = WatchStock(
            symbol: initialSymbol,
            name: initialName,
            listName: selectedWatchlist
        )
        
        watchlist.append(newWatchStock)
        dismiss()
    }
}

#Preview {
    ContentView()
}
