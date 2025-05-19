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
    @State private var regularTitle: String = ""
    @State private var regularAmount: String = ""
    @State private var regularFrequency: RegularInvestment.Frequency = .monthly
    @State private var regularStartDate = Date()
    @State private var regularEndDate: Date? = nil
    @State private var hasEndDate: Bool = false
    @State private var regularNote: String = ""
    
    // 單獨的載入狀態變數
    @State private var isDividendLoading: Bool = false
    @State private var isFrequencyLoading: Bool = false
    @State private var isPriceLoading: Bool = false
    
    
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
        
        // 優先使用傳入的 bankId
        _selectedBankId = State(initialValue: bankId)
        
        // 如果是從銀行投資組合進入，強制設定為"銀行"
        _selectedDestination = State(initialValue: isFromBankPortfolio ? "銀行" : "銀行")

        
        let defaultWatchlist = UserDefaults.standard.stringArray(forKey: "watchlistNames")?[0] ?? "自選清單1"
        _selectedWatchlist = State(initialValue: defaultWatchlist)
        
        // 輸出初始設置的值
        print("初始化 AddStockView")
        print("傳入的銀行ID: \(bankId)")
        print("選擇的銀行ID: \(bankId)")
        
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
                            .onChange(of: purchaseDate) { oldDate, newDate in
                                if isRegularInvestment {
                                    regularStartDate = newDate
                                }
                                
                                // 當日期變更時重新載入價格
                                Task {
                                    await loadStockPrice()
                                }
                            }
                        
                        if isPriceLoading {
                            HStack {
                                Text("股價")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("載入中...")
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                        } else if !purchasePrice.isEmpty {
                            HStack {
                                Text("股價")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("$\(purchasePrice)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // 定期定額設定區塊
                    if isRegularInvestment {
                        Section(header: Text("定期定額設定")) {
                            TextField("計劃名稱", text: $regularTitle)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .foregroundColor(.white)
                            
                            TextField("每期投資金額", text: $regularAmount)
                                .keyboardType(.numberPad)
                            
                            Picker("投資頻率", selection: $regularFrequency) {
                                ForEach(RegularInvestment.Frequency.allCases, id: \.self) { frequency in
                                    Text(frequency.rawValue).tag(frequency)
                                }
                            }
                            
                            DatePicker("開始日期", selection: $regularStartDate, displayedComponents: .date)
                                .onChange(of: regularStartDate) { oldValue, newDate in
                                    withAnimation {
                                        purchaseDate = newDate
                                    }
                                }
                            
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
                        if isDividendLoading {
                            HStack {
                                Text("每股股利")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("下載中...")
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                        } else if !dividendPerShare.isEmpty {
                            HStack {
                                Text("每股股利")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("$\(dividendPerShare)")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if isFrequencyLoading {
                            HStack {
                                Text("發放頻率")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("更新中...")
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                        } else if let freq = frequency {
                            HStack {
                                Text("發放頻率")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(getFrequencyText(freq))
                                    .foregroundColor(.gray)
                            }
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("新增") {
                    addStock()
                }
                .disabled(shouldDisableAddButton())
            }
        }
        .task {
            await loadStockData()
            
            print("視圖加載時檢查銀行列表:")
                        print("銀行列表數量: \(banks.count)")
                        print("所有銀行 ID: \(banks.map { $0.id })")
                        print("當前選中銀行 ID: \(selectedBankId)")
        }
        .onAppear {
            print("可用的銀行列表:")
            for bank in banks {
                print("銀行: \(bank.name), ID: \(bank.id)")
            }
            print("銀行列表數量: \(banks.count)")
            print("當前選中的銀行ID: \(selectedBankId)")
            print("是否從銀行組合進入: \(isFromBankPortfolio)")
            print("傳入的銀行ID: \(bankId)")
            
            // 檢查banks是否為空，如果為空則打印警告
            if banks.isEmpty {
                print("警告：banks列表為空！")
            }
            
            // 檢查選擇的銀行ID是否存在於banks列表中
            let bankExists = banks.contains { $0.id == selectedBankId }
            print("選中的銀行ID是否存在於banks列表中: \(bankExists)")
        }
    }

    // 使用共用函數來處理API呼叫和錯誤處理
    private func loadStockData() async {
        isDividendLoading = true
        isFrequencyLoading = true
        
        // 同步加載股息和頻率資料
        async let dividendResult = loadDataFromAPI(
            apiCall: { try await APIService.shared.getDividendData(symbol: initialSymbol) },
            processData: { SQLDataProcessor.shared.calculateDividendPerShare(from: $0.data) },
            backupCall: { await localStockService.getTaiwanStockDividend(symbol: initialSymbol) },
            updateUI: { value in
                self.dividendPerShare = String(format: "%.2f", value)
                self.isDividendLoading = false
            },
            logSuccess: { "成功從API獲取股息: \($0)" },
            logFailure: { "獲取股息失敗: \($0)" }
        )
        
        async let frequencyResult = loadDataFromAPI(
            apiCall: { try await APIService.shared.getDividendData(symbol: initialSymbol) },
            processData: { SQLDataProcessor.shared.calculateDividendFrequency(from: $0.data) },
            backupCall: { await localStockService.getTaiwanStockFrequency(symbol: initialSymbol) },
            updateUI: { value in
                self.frequency = value
                self.isFrequencyLoading = false
            },
            logSuccess: { "成功從API獲取頻率: \($0)" },
            logFailure: { "獲取頻率失敗: \($0)" }
        )
        
        // 等待兩個非同步操作完成
        _ = await (dividendResult, frequencyResult)
        
        // 載入股價資料
        await loadStockPrice()
    }

    private func loadStockPrice() async {
        isPriceLoading = true
        
        _ = await loadDataFromAPI(
            apiCall: { try await APIService.shared.getDividendData(symbol: initialSymbol) },
            processData: { dividendResponse -> Double? in
                let record = findNearestDividendRecord(records: dividendResponse.data, date: purchaseDate)
                return record?.ex_dividend_reference_price
            },
            backupCall: { await localStockService.getStockPrice(symbol: initialSymbol, date: purchaseDate) },
            updateUI: { value in
                self.purchasePrice = String(format: "%.2f", value)
                self.isPriceLoading = false
            },
            logSuccess: { "成功取得股價: \($0)" },
            logFailure: { "獲取股價失敗: \($0)" }
        )
    }

    // 通用的資料加載和錯誤處理函數
    private func loadDataFromAPI<T, R>(
        apiCall: () async throws -> T,
        processData: (T) -> R?,
        backupCall: () async -> R?,
        updateUI: @escaping (R) -> Void,
        logSuccess: (R) -> String,
        logFailure: (String) -> String
    ) async -> R? {
        do {
            let response = try await apiCall()
            if let result = processData(response) {
                await MainActor.run { updateUI(result) }
                print(logSuccess(result))
                return result
            }
        } catch {
            print(logFailure(error.localizedDescription))
        }
        
        // 使用本地服務作為備用
        if let backupResult = await backupCall() {
            await MainActor.run { updateUI(backupResult) }
            return backupResult
        }
        
        return nil
    }
    // 輔助方法：查找最接近指定日期的股利記錄
    private func findNearestDividendRecord(records: [DividendRecord], date: Date) -> DividendRecord? {
        // 按時間排序的記錄
        let sortedRecords = records.compactMap { record -> (DividendRecord, Date)? in
            guard let exDate = record.exDividendDateObj else { return nil }
            return (record, exDate)
        }
        .sorted { $0.1 < $1.1 }
        
        // 找到最接近日期的記錄
        var closestRecord: DividendRecord? = nil
        var minDifference = Double.infinity
        
        for (record, exDate) in sortedRecords {
            let difference = abs(exDate.timeIntervalSince(date))
            if difference < minDifference {
                minDifference = difference
                closestRecord = record
            }
        }
        
        return closestRecord
    }
    
    private func addStock() {
        if selectedDestination == "銀行" {
            addToBank()
        } else {
            addToWatchlist()
        }
    }
    
    private func addToBank() {
        print("========================")
        print("AddStockView.addToBank 詳細日誌")
        print("銀行ID: \(bankId)")
        print("選中的銀行ID: \(selectedBankId)")
        print("是否來自銀行投資組合: \(isFromBankPortfolio)")
        print("最終使用的銀行ID: \(isFromBankPortfolio ? bankId : selectedBankId)")
        print("所有銀行: \(banks.map { $0.id })")
        print("股票符號: \(initialSymbol)")
        print("股票名稱: \(initialName)")
        print("股數: \(shares)")
        print("是否為定期定額: \(isRegularInvestment)")
        print("========================")
        
        // 確保銀行ID一致
        let finalBankId = isFromBankPortfolio ? bankId : selectedBankId
        
        
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
            // 計算該股票現有的定期定額計劃數量
            let existingPlansCount = stocks.filter {
                $0.regularInvestment != nil &&
                $0.symbol == initialSymbol &&
                $0.bankId == selectedBankId
            }.count
            
            // 如果沒有輸入標題，則自動生成
            let planTitle = regularTitle.isEmpty ? "計劃 \(existingPlansCount + 1)" : regularTitle
            
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
                bankId: finalBankId,
                regularInvestment: RegularInvestment(
                    title: planTitle,
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
            
            let stockBankId = isFromBankPortfolio ? bankId : selectedBankId
            
            print("新增股票: \(initialSymbol) 到銀行ID: \(stockBankId)")
            print("新增前股票數量: \(stocks.count)")
            
            let newStock = Stock(
                symbol: initialSymbol,
                name: initialName,
                shares: sharesInt,
                dividendPerShare: dividendDouble,
                dividendYear: Calendar.current.component(.year, from: Date()),
                frequency: frequency ?? 1,
                purchaseDate: purchaseDate,
                purchasePrice: priceDouble,
                bankId: stockBankId
            )
            
            var updatedStocks = stocks
            updatedStocks.append(newStock)
            stocks = updatedStocks
            
            print("========================")
            print("股票添加結果")
            print("成功添加: 股票ID \(newStock.id)")
            print("銀行ID: \(newStock.bankId)")
            print("股票數量: \(stocks.count)")
            print("屬於此銀行的股票: \(stocks.filter { $0.bankId == stockBankId }.count)")
            print("========================")
            DispatchQueue.main.async {
                dismiss()
            }
        }
    }
    
    private func addToWatchlist() {
        
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
