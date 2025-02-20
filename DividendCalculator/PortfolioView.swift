//
//  PortfolioView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/24.
//


import SwiftUI

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("尚未新增任何股票")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("點擊右下角的按鈕開始新增股票")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 100)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Summary Section
struct PortfolioSummarySection: View {
    let stockCount: Int
    let totalAnnualDividend: Double
    
    var body: some View {
        Section {
            VStack {
                HStack {
                    Text("總持股數")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(stockCount) 檔")
                        .foregroundColor(.gray)
                }
                Spacer()
                
                HStack {
                    Text("預估年化股利")
                        .foregroundColor(.white)
                    Spacer()
                    Text("$\(String(format: "%.0f", totalAnnualDividend))")
                        .foregroundColor(.green)
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .padding(.top, 20)
        .padding(.bottom, 20)
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
    
    @State private var isEditing = false
    @State private var showingSearchView = false
    @State private var selectedStockType: StockType = .all
    
    let bankId: UUID
    let bankName: String
    
    // 定義股票類型枚舉
    enum StockType: String, CaseIterable {
        case all = "全部"
        case regularInvestment = "定期定額"
        case normal = "一般持股"
    }
    
    // 替換原有的計算屬性
    private func getBankStocks() -> [Stock] {
        stocks.filter { $0.bankId == bankId }
    }
    
    private func getRegularInvestments() -> [WeightedStockInfo] {
        getBankStocks()
            .filter { $0.regularInvestment != nil }
            .calculateWeightedAverage(forBankId: bankId)
    }
    
    private func getNormalStocks() -> [WeightedStockInfo] {
        getBankStocks()
            .filter { $0.regularInvestment == nil }
            .calculateWeightedAverage(forBankId: bankId)
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
    private func stockListView(stocks: [WeightedStockInfo], isRegularInvestment: Bool) -> some View {
            ForEach(Array(stocks.enumerated()), id: \.element.id) { index, stockInfo in
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
                    leading: isEditing ? 0 : 16,
                    bottom: 4,
                    trailing: 16
                ))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
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
                    .padding(.bottom, 10)
                
                List {
                    // 總覽區塊
                    PortfolioSummarySection(
                        stockCount: getStockCount(),
                        totalAnnualDividend: calculateTotalAnnualDividend()
                    )
                    
                    if getRegularInvestments().isEmpty && getNormalStocks().isEmpty {
                        EmptyStateView()
                    } else {
                        // 根據選擇的類型顯示對應的股票列表
                        switch selectedStockType {
                        case .all:
                            if !getRegularInvestments().isEmpty {
                                Section(header: Text("定期定額").foregroundColor(.blue)) {
                                    stockListView(stocks: getRegularInvestments(), isRegularInvestment: true)
                                }
                            }
                            if !getNormalStocks().isEmpty {
                                Section(header: Text("一般持股").foregroundColor(.white)) {
                                    stockListView(stocks: getNormalStocks(), isRegularInvestment: false)
                                }
                            }
                        case .regularInvestment:
                            stockListView(stocks: getRegularInvestments(), isRegularInvestment: true)
                        case .normal:
                            stockListView(stocks: getNormalStocks(), isRegularInvestment: false)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            }
            
            AddStockFloatingButton(action: {
                showingSearchView = true
            })
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSearchView) {
            SearchStockView(
                stocks: $stocks,
                bankId: bankId
            )
        }
    }
}
    
//    // 新增通用的刪除和移動方法
//    private func deleteSelectedStocks(at offsets: IndexSet) {
//        let stocksToDelete = offsets.map { filteredStocks()[$0] }
//        stocks.removeAll { stock in
//            stocksToDelete.contains { $0.symbol == stock.symbol && stock.bankId == bankId }
//        }
//    }
//    
//    private func moveSelectedStocks(from source: IndexSet, to destination: Int) {
//        var sortOrder = filteredStocks().map { $0.symbol }
//        sortOrder.move(fromOffsets: source, toOffset: destination)
//        
//        let orderDict = Dictionary(uniqueKeysWithValues: sortOrder.enumerated().map { ($0.element, $0.offset) })
//        stocks = stocks.sorted { (stock1, stock2) in
//            guard stock1.bankId == bankId, stock2.bankId == bankId else {
//                return false
//            }
//            let index1 = orderDict[stock1.symbol] ?? 0
//            let index2 = orderDict[stock2.symbol] ?? 0
//            return index1 < index2
//        }
//    }
//}
