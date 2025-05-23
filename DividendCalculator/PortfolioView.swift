//
//  PortfolioView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/24.
//


import SwiftUI


// MARK: - Summary Section
struct PortfolioSummarySection: View {
    let stockCount: Int
    let totalAnnualDividend: Double
    let totalInvestment: Double
    let dailyChange: Double  // 添加當日損益
    let dailyChangePercentage: Double  // 添加當日損益百分比
    
    var body: some View {
        Section {
            VStack(spacing: 15) {
                HStack {
                    Text("總持股數")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(stockCount) 檔")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("總投資成本")
                        .foregroundColor(.white)
                    Spacer()
                    Text("$\(Int(totalInvestment).formattedWithComma)")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("預估年化股利")
                        .foregroundColor(.white)
                    Spacer()
                    Text("$\(String(format: "%.0f", totalAnnualDividend))")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("當日損益")
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("$\(Int(dailyChange).formattedWithComma)")
                            .foregroundColor(dailyChange >= 0 ? .green : .red)
                        Text("(\(String(format: "%.2f", dailyChangePercentage))%)")
                            .font(.caption)
                            .foregroundColor(dailyChange >= 0 ? .green : .red)
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Stock List Section
struct StockListSection: View {
    let stockInfos: [WeightedStockInfo]
    let isEditing: Bool
    let onDelete: ((IndexSet) -> Void)?
    let onMove: ((IndexSet, Int) -> Void)?
    
    var body: some View {
        Section {
            ForEach(stockInfos) { stockInfo in
                ZStack {
                    StockSummaryRow(stockInfo: stockInfo, isEditing: isEditing)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 16)
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isEditing ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(
                            color: isEditing ? Color.blue.opacity(0.1) : Color.white.opacity(0.05),
                            radius: isEditing ? 8 : 4,
                            x: 0,
                            y: isEditing ? 4 : 2
                        )
                }
                .listRowInsets(EdgeInsets(
                    top: 4,
                    leading: isEditing ? 0 : 16,
                    bottom: 4,
                    trailing: 16
                ))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: onDelete)
            .onMove(perform: onMove)
        }
    }
}

struct StockDetailView: View {
    @Binding var stocks: [Stock]
    let symbol: String
    let bankId: UUID
    let isRegularInvestment: Bool
    
    var body: some View {
        if isRegularInvestment {
            RegularInvestmentPlansView(stocks: $stocks, symbol: symbol, bankId: bankId)
        } else {
            NormalStockDetailView(stocks: $stocks, symbol: symbol, bankId: bankId)
        }
    }
}

// MARK: - Main Portfolio View
struct PortfolioView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]
    @Binding var banks: [Bank]
    
    @State private var isEditing = false
    @State private var showingSearchView = false
    @State private var selectedStockType: StockType = .all
    @State private var portfolioMetrics = PortfolioMetrics()
    @State private var cachedTotalAnnualDividend: Double = 0
    @State private var cachedTotalInvestment: Double = 0
    @State private var cachedStockCount: Int = 0
    @State private var dataInitialized = false
    
    
    let bankId: UUID
    let bankName: String
    
    //服務
    private let portfolioManager = PortfolioManager.shared
    
    // 定義股票類型枚舉
    enum StockType: String, CaseIterable {
        case all = "全部"
        case regularInvestment = "定期定額"
        case normal = "一般持股"
    }
    
    // PortfolioMetrics結構體
    private struct PortfolioMetrics {
        var totalValue: Double = 0
        var dailyChange: Double = 0
        var dailyChangePercentage: Double = 0
        var totalProfitLoss: Double = 0
        var totalROI: Double = 0
        var totalAnnualDividend: Double = 0
        var dividendYield: Double = 0
    }
    
    
    private func getBankStocks() -> [Stock] {
        return PortfolioManager.shared.getStocksForBank(bankId: bankId, allStocks: stocks)
    }

    private func getRegularInvestments() -> [WeightedStockInfo] {
        return PortfolioManager.shared.getWeightedRegularInvestments(bankId: bankId, allStocks: stocks)
    }

    private func getNormalStocks() -> [WeightedStockInfo] {
        return PortfolioManager.shared.getWeightedNormalStocks(bankId: bankId, allStocks: stocks)
    }
    
    private func calculateTotalAnnualDividend() -> Double {
        switch selectedStockType {
        case .all:
            return getRegularInvestments().reduce(0) { $0 + $1.calculateTotalAnnualDividend() } +
            getNormalStocks().reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
        case .regularInvestment:
            return getRegularInvestments().reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
        case .normal:
            return getNormalStocks().reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
        }
    }
    
    private func calculateTotalInvestment() -> Double {
        return portfolioManager.calculateTotalInvestment(for: getBankStocks())
    }
    
    
    private func getStockCount() -> Int {
        switch selectedStockType {
        case .all:
            return getRegularInvestments().count + getNormalStocks().count
        case .regularInvestment:
            return getRegularInvestments().count
        case .normal:
            return getNormalStocks().count
        }
    }
    // 股票類型選擇器
    private var stockTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(StockType.allCases, id: \.self) { type in
                    Button(action: {
                        withAnimation {
                            selectedStockType = type
                        }
                    }) {
                        Text(type.rawValue)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(selectedStockType == type ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color.clear)
    }
    
    private func createStockRow(stockInfo: WeightedStockInfo, isRegularInvestment: Bool) -> some View {
        ZStack {
            StockSummaryRow(stockInfo: stockInfo, isEditing: isEditing)
                .padding(.vertical, 4)
                .padding(.horizontal, 16)
                .background(Color(white: 0.15))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isEditing ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(
                    color: isEditing ? Color.blue.opacity(0.1) : Color.white.opacity(0.05),
                    radius: isEditing ? 8 : 4,
                    x: 0,
                    y: isEditing ? 4 : 2
                )
            
            if !isEditing {
                NavigationLink(
                    destination: StockDetailView(
                        stocks: $stocks,
                        symbol: stockInfo.symbol,
                        bankId: bankId,
                        isRegularInvestment: isRegularInvestment
                    )
                ) {
                    EmptyView()
                }
                .opacity(0)
            }
        }
        .listRowInsets(EdgeInsets(
            top: 4,
            leading: 0, // 確保左側邊距為0，讓刪除按鈕可見
            bottom: 4,
            trailing: 16
        ))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    
    // 新增刪除和移動方法
    private func deleteRegularStocks(at offsets: IndexSet) {
        let regularStocks = getRegularInvestments()
        let symbolsToDelete = offsets.map { regularStocks[$0].symbol }
        stocks.removeAll { stock in
            symbolsToDelete.contains(stock.symbol) && stock.bankId == bankId && stock.regularInvestment != nil
        }
    }
    
    private func deleteNormalStocks(at offsets: IndexSet) {
        let normalStocks = getNormalStocks()
        let symbolsToDelete = offsets.map { normalStocks[$0].symbol }
        stocks.removeAll { stock in
            symbolsToDelete.contains(stock.symbol) && stock.bankId == bankId && stock.regularInvestment == nil
        }
    }
    
    private func moveRegularStocks(from source: IndexSet, to destination: Int) {
        var regularStocks = getRegularInvestments()
        regularStocks.move(fromOffsets: source, toOffset: destination)
        
        // 更新排序
        let sortedSymbols = regularStocks.map { $0.symbol }
        stocks = stocks.sorted { stock1, stock2 in
            guard stock1.bankId == bankId, stock2.bankId == bankId,
                  stock1.regularInvestment != nil, stock2.regularInvestment != nil else {
                return false
            }
            
            guard let index1 = sortedSymbols.firstIndex(of: stock1.symbol),
                  let index2 = sortedSymbols.firstIndex(of: stock2.symbol) else {
                return false
            }
            
            return index1 < index2
        }
    }
    
    private func moveNormalStocks(from source: IndexSet, to destination: Int) {
        var normalStocks = getNormalStocks()
        normalStocks.move(fromOffsets: source, toOffset: destination)
        
        // 更新排序
        let sortedSymbols = normalStocks.map { $0.symbol }
        stocks = stocks.sorted { stock1, stock2 in
            guard stock1.bankId == bankId, stock2.bankId == bankId,
                  stock1.regularInvestment == nil, stock2.regularInvestment == nil else {
                return false
            }
            
            guard let index1 = sortedSymbols.firstIndex(of: stock1.symbol),
                  let index2 = sortedSymbols.firstIndex(of: stock2.symbol) else {
                return false
            }
            
            return index1 < index2
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 添加股票類型選擇器
                stockTypeSelector
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                List {
                    // 總覽區塊
                    PortfolioSummarySection(
                        stockCount: cachedStockCount,
                        totalAnnualDividend: cachedTotalAnnualDividend,
                        totalInvestment: cachedTotalInvestment,
                        dailyChange: portfolioMetrics.dailyChange,
                        dailyChangePercentage: portfolioMetrics.dailyChangePercentage
                    )
                    
                    if getRegularInvestments().isEmpty && getNormalStocks().isEmpty {
                        EmptyStateView(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "尚未新增任何股票",
                            subtitle: "點擊右下角的按鈕開始新增股票"
                        )
                    } else {
                        // 根據選擇的類型顯示對應的股票列表
                        switch selectedStockType {
                        case .all:
                            if !getRegularInvestments().isEmpty {
                                Section(header: Text("定期定額").foregroundColor(.blue)) {
                                    ForEach(Array(getRegularInvestments().enumerated()), id: \.element.id) { index, stockInfo in
                                        createStockRow(stockInfo: stockInfo, isRegularInvestment: true)
                                    }
                                    .onDelete(perform: isEditing ? deleteRegularStocks : nil)
                                    .onMove { from, to in
                                        moveRegularStocks(from: from, to: to)
                                    }
                                }
                            }
                            if !getNormalStocks().isEmpty {
                                Section(header: Text("一般持股").foregroundColor(.white)) {
                                    ForEach(Array(getNormalStocks().enumerated()), id: \.element.id) { index, stockInfo in
                                        createStockRow(stockInfo: stockInfo, isRegularInvestment: false)
                                    }
                                    .onDelete(perform: isEditing ? deleteNormalStocks : nil)
                                    .onMove { from, to in
                                        moveNormalStocks(from: from, to: to)
                                    }
                                }
                            }
                        case .regularInvestment:
                            ForEach(Array(getRegularInvestments().enumerated()), id: \.element.id) { index, stockInfo in
                                createStockRow(stockInfo: stockInfo, isRegularInvestment: true)
                            }
                            .onDelete(perform: isEditing ? deleteRegularStocks : nil)
                            
                            .onMove { from, to in
                                moveRegularStocks(from: from, to: to)
                            }
                        case .normal:
                            ForEach(Array(getNormalStocks().enumerated()), id: \.element.id) { index, stockInfo in
                                createStockRow(stockInfo: stockInfo, isRegularInvestment: false)
                            }
                            .onDelete(perform: isEditing ? deleteNormalStocks : nil)
                            .onMove { from, to in
                                moveNormalStocks(from: from, to: to)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            }
            
            FloatingActionButton(action: {
                showingSearchView = true
            })
        }
        .onAppear {
            if !dataInitialized {
                initializeCachedData()
                dataInitialized = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(bankName)
                    .navigationTitleStyle()
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if !getRegularInvestments().isEmpty || !getNormalStocks().isEmpty {
                    Button(isEditing ? "完成" : "編輯") {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingSearchView) {
            SearchStockView(
                stocks: $stocks,
                watchlist: $watchlist,
                banks: $banks,
                bankId: bankId
            )
        }
        .task {
            await updatePortfolioMetrics()
        }
        // 添加下拉刷新功能
        .refreshable {
            await forceRefresh()
        }
    }
    
    // 初始化緩存數據
    private func initializeCachedData() {
        cachedTotalAnnualDividend = calculateTotalAnnualDividend()
        cachedTotalInvestment = calculateTotalInvestment()
        cachedStockCount = getStockCount()
    }
        
        
        
        // 強制更新指標
    private func forceUpdateMetrics() async {
        let metrics = await PortfolioManager.shared.getBankPortfolioMetrics(
            bankId: bankId,
            allStocks: stocks
        )
        
        await MainActor.run {
            self.portfolioMetrics.totalValue = metrics.totalValue
            self.portfolioMetrics.dailyChange = metrics.dailyChange
            self.portfolioMetrics.dailyChangePercentage = metrics.dailyChangePercentage
            self.portfolioMetrics.totalProfitLoss = metrics.totalProfitLoss
            self.portfolioMetrics.totalROI = metrics.totalROI
            self.portfolioMetrics.totalAnnualDividend = metrics.annualDividend
            self.portfolioMetrics.dividendYield = metrics.dividendYield
            
            // 更新緩存值
            self.cachedTotalAnnualDividend = metrics.annualDividend
            self.cachedTotalInvestment = metrics.totalInvestment
            self.cachedStockCount = metrics.stockCount
        }
    }
        
        // 手動刷新
    private func forceRefresh() async {
        await forceUpdateMetrics()
    }
    
    
    
    // 計算當日損益及百分比 - 簡化版本
    private func calculateDailyChange() -> (Double, Double) {
        return (portfolioMetrics.dailyChange, portfolioMetrics.dailyChangePercentage)
    }
    
    private func updatePortfolioMetrics() async {
        await forceUpdateMetrics()
    }
}
    
