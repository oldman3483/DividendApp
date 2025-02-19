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
            let regularInvestments = getRegularInvestments()
            let normalStocks = getNormalStocks()
            
            return regularInvestments.reduce(0) { $0 + $1.calculateTotalAnnualDividend() } +
            normalStocks.reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
            
        case .regularInvestment:
            let regularInvestments = getRegularInvestments()
            return regularInvestments.reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
            
        case .normal:
            let normalStocks = getNormalStocks()
            return normalStocks.reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
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
    // 過濾股票的方法
    private func filteredStocks() -> [WeightedStockInfo] {
        switch selectedStockType {
        case .all:
            return getRegularInvestments() + getNormalStocks()
        case .regularInvestment:
            return getRegularInvestments()
        case .normal:
            return getNormalStocks()
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
                    
                    if filteredStocks().isEmpty {
                        EmptyStateView()
                    } else {
                        Section {
                            StockListSection(
                                stockInfos: filteredStocks(),
                                isEditing: isEditing,
                                onDelete: deleteSelectedStocks,
                                onMove: moveSelectedStocks
                            )
                            .overlay {
                                ForEach(filteredStocks()) { stockInfo in
                                    NavigationLink(
                                        destination: PortfolioDetailView(
                                            stocks: $stocks,
                                            symbol: stockInfo.symbol,
                                            bankId: bankId
                                        )
                                    ) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                }
                            }
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
        // 其餘程式碼保持不變
    }
    
    // 新增通用的刪除和移動方法
    private func deleteSelectedStocks(at offsets: IndexSet) {
        let stocksToDelete = offsets.map { filteredStocks()[$0] }
        stocks.removeAll { stock in
            stocksToDelete.contains { $0.symbol == stock.symbol && stock.bankId == bankId }
        }
    }
    
    private func moveSelectedStocks(from source: IndexSet, to destination: Int) {
        var sortOrder = filteredStocks().map { $0.symbol }
        sortOrder.move(fromOffsets: source, toOffset: destination)
        
        let orderDict = Dictionary(uniqueKeysWithValues: sortOrder.enumerated().map { ($0.element, $0.offset) })
        stocks = stocks.sorted { (stock1, stock2) in
            guard stock1.bankId == bankId, stock2.bankId == bankId else {
                return false
            }
            let index1 = orderDict[stock1.symbol] ?? 0
            let index2 = orderDict[stock2.symbol] ?? 0
            return index1 < index2
        }
    }
}
