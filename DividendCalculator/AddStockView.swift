//
//  AddStockView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import SwiftUI

struct AddStockView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]
    @Binding var banks: [Bank]
    
    let initialSymbol: String
    let initialName: String
    let bankId: UUID
    let isFromBankPortfolio: Bool
    
    // 一般購買相關
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
    
    // 定期定額相關
    @State private var isRegularInvestment: Bool = false
    @State private var regularAmount: String = ""
    @State private var regularFrequency: RegularInvestment.Frequency = .monthly
    @State private var regularStartDate = Date()
    @State private var regularEndDate: Date? = nil
    @State private var hasEndDate: Bool = false
    @State private var regularNote: String = ""
    
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
        
        // 如果銀行列表不為空，優先選擇第一個銀行
        let initialBank = banks.wrappedValue.first ?? Bank(name: "預設銀行")
        _selectedBankId = State(initialValue: initialBank.id)
        
        let defaultWatchlist = UserDefaults.standard.stringArray(forKey: "watchlistNames")?[0] ?? "自選清單1"
        _selectedWatchlist = State(initialValue: defaultWatchlist)
    }
    
    private func shouldDisableAddButton() -> Bool {
        if selectedDestination == "銀行" {
            if isRegularInvestment {
                return regularAmount.isEmpty ||
                       (hasEndDate && regularEndDate == nil)
            } else {
                return shares.isEmpty
            }
        }
        return false
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
                        if !isRegularInvestment {
                            Picker("選擇目標", selection: $selectedDestination) {
                                ForEach(destinations, id: \.self) { destination in
                                    Text(destination)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        if selectedDestination == "銀行" {
                            Picker("選擇銀行", selection: $selectedBankId) {
                                ForEach(banks) { bank in
                                    Text(bank.name).tag(bank.id)
                                }
                            }
                        } else if !isRegularInvestment {
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
                        Toggle("定期定額", isOn: $isRegularInvestment)
                            .onChange(of: isRegularInvestment) { _, isEnabled in
                                if isEnabled {
                                    selectedDestination = "銀行"
                                    shares = ""
                                    regularStartDate = purchaseDate
                                }
                            }
                        
                        if !isRegularInvestment {
                            TextField("持股數量", text: $shares)
                                .keyboardType(.numberPad)
                        }
                        
                        DatePicker("買入日期", selection: $purchaseDate, displayedComponents: .date)
                            .onChange(of: purchaseDate) { _, newDate in
                                if isRegularInvestment {
                                    regularStartDate = newDate
                                }
                            }
                        
                        if !purchasePrice.isEmpty {
                            HStack {
                                Text("股價")
                                Spacer()
                                Text("$\(purchasePrice)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // 定期定額設定區塊
                    if isRegularInvestment {
                        Section(header: Text("定期定額設定")) {
                            TextField("每期投資金額", text: $regularAmount)
                                .keyboardType(.numberPad)
                            
                            Picker("投資頻率", selection: $regularFrequency) {
                                ForEach(RegularInvestment.Frequency.allCases, id: \.self) { frequency in
                                    Text(frequency.rawValue).tag(frequency)
                                }
                            }
                            
                            DatePicker("開始日期", selection: $regularStartDate, displayedComponents: .date)
                            
                            Toggle("設定結束日期", isOn: $hasEndDate)
                            
                            if hasEndDate {
                                DatePicker("結束日期",
                                         selection: .init(
                                            get: { regularEndDate ?? regularStartDate },
                                            set: { regularEndDate = $0 }
                                         ),
                                         in: regularStartDate...,
                                         displayedComponents: .date)
                            }
                            
                            TextField("備註", text: $regularNote)
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
                    .disabled(shouldDisableAddButton())
                }
            }
        }
        .task {
            await loadStockData()
        }
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
        
        if banks.isEmpty {
            let defaultBank = Bank(name: "預設銀行")
            banks.append(defaultBank)
            selectedBankId = defaultBank.id
        }
        
        // 定期定額模式的驗證
        if isRegularInvestment {
            
            print("開始新增定期定額股票")
            print("當前銀行ID: \(selectedBankId)")
            print("所有銀行: \(banks.map { $0.id })")
            
            guard let regularAmountDouble = Double(regularAmount),
                  regularAmountDouble > 0 else {
                errorMessage = "請輸入有效的定期定額金額"
                return
            }
            
            // 創建新的定期定額投資股票
            let newStock = Stock(
                symbol: initialSymbol,
                name: initialName,
                shares: 0, // 初始持股為 0，等待計算
                dividendPerShare: Double(dividendPerShare) ?? 0,
                dividendYear: Calendar.current.component(.year, from: Date()),
                frequency: frequency ?? 1,
                purchaseDate: regularStartDate,
                purchasePrice: nil, // 等待計算加權平均價格
                bankId: selectedBankId,
                regularInvestment: RegularInvestment(
                    amount: regularAmountDouble,
                    frequency: regularFrequency,
                    startDate: regularStartDate,
                    endDate: hasEndDate ? regularEndDate : nil,
                    isActive: true,
                    note: regularNote
                )
            )
            
            // 計算並更新定期定額交易
            Task {
                var updatedStock = newStock
                await updatedStock.updateRegularInvestmentTransactions(stockService: localStockService)
                
                await MainActor.run {
                    
                    print("嘗試新增股票")
                    print("股票銀行ID: \(newStock.bankId)")
                    print("當前 stocks 數量: \(stocks.count)")
                    
                    // 直接添加股票，不使用 contains 檢查
                    stocks.append(updatedStock)
                    
                    print("定期定額股票新增成功")
                   
                    dismiss()
                }
            }
        } else {
            // 一般購買模式（保持原有邏輯）
            guard let sharesInt = Int(shares),
                  sharesInt > 0 else {
                errorMessage = "請輸入有效的持股數量"
                return
            }
            
            guard let dividendDouble = Double(dividendPerShare),
                  let priceDouble = Double(purchasePrice) else {
                errorMessage = "無法取得股利或股價資訊"
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
    }
    
    private func addToWatchlist() {
        // 獲取選中的觀察清單名稱
//        let defaultWatchlist = UserDefaults.standard.stringArray(forKey: "watchlistNames") ?? ["自選清單1"]
        
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
