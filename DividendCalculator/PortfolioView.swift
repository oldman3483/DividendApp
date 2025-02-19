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
    @State private var selectedStock: WeightedStockInfo?
    @State private var showingDetail = false
    
    let bankId: UUID
    let bankName: String
    
    private var bankStocks: [Stock] {
        stocks.filter { $0.bankId == bankId }
    }
    
    // 分離一般持股和定期定額
    private var regularInvestments: [WeightedStockInfo] {
        let filtered =  stocks.filter { $0.regularInvestment != nil }
            .calculateWeightedAverage(forBankId: bankId)
        
        print("定期定額股票數量: \(filtered.count)")
        print("所有股票: \(stocks.count)")
        print("目前 bankId: \(bankId)")
        print("定期定額股票詳情: \(filtered)")
        
        return filtered
    }
    
    private var normalStocks: [WeightedStockInfo] {
        stocks.filter { $0.regularInvestment == nil }
            .calculateWeightedAverage(forBankId: bankId)
    }
    
    private var totalAnnualDividend: Double {
        let regularDividend = regularInvestments.reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
        let normalDividend = normalStocks.reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
        return regularDividend + normalDividend
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                List {
                    // 總覽區塊
                    PortfolioSummarySection(
                        stockCount: regularInvestments.count + normalStocks.count,
                        totalAnnualDividend: totalAnnualDividend
                    )
                    
                    if regularInvestments.isEmpty && normalStocks.isEmpty {
                        EmptyStateView()
                    } else {
                        // 定期定額區塊
                        if !regularInvestments.isEmpty {
                            Section(header:
                                        Text("定期定額")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(.top, 20)
                            ) {
                                StockListSection(
                                    stockInfos: regularInvestments,
                                    isEditing: isEditing,
                                    onDelete: deleteRegularStocks,
                                    onMove: moveRegularStocks
                                )
                                .overlay {
                                    ForEach(regularInvestments) { stockInfo in
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
                        
                        // 一般持股區塊
                        if !normalStocks.isEmpty {
                            Section(header:
                                        Text("一般持股")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            ) {
                                StockListSection(
                                    stockInfos: normalStocks,
                                    isEditing: isEditing,
                                    onDelete: deleteNormalStocks,
                                    onMove: moveNormalStocks
                                )
                                .overlay {
                                    ForEach(normalStocks) { stockInfo in
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
                if !regularInvestments.isEmpty || !normalStocks.isEmpty {
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
        .sheet(isPresented: $showingDetail) {
            if let stockInfo = selectedStock {
                PortfolioDetailView(
                    stocks: $stocks,
                    symbol: stockInfo.symbol,
                    bankId: bankId
                )
            }
        }
        .sheet(isPresented: $showingSearchView) {
            SearchStockView(
                stocks: $stocks,
                bankId: bankId
            )
        }
    }
    
    private func deleteRegularStocks(at offsets: IndexSet) {
        let stocksToDelete = offsets.map { regularInvestments[$0] }
        stocks.removeAll { stock in
            stocksToDelete.contains { $0.symbol == stock.symbol && stock.bankId == bankId && stock.regularInvestment != nil }
        }
    }
    
    private func moveRegularStocks(from source: IndexSet, to destination: Int) {
        var sortOrder = regularInvestments.map { $0.symbol }
        sortOrder.move(fromOffsets: source, toOffset: destination)
        
        let orderDict = Dictionary(uniqueKeysWithValues: sortOrder.enumerated().map { ($0.element, $0.offset) })
        stocks = stocks.sorted { (stock1, stock2) in
            guard stock1.bankId == bankId, stock2.bankId == bankId,
                  stock1.regularInvestment != nil, stock2.regularInvestment != nil else {
                return false
            }
            let index1 = orderDict[stock1.symbol] ?? 0
            let index2 = orderDict[stock2.symbol] ?? 0
            return index1 < index2
        }
    }
    
    private func deleteNormalStocks(at offsets: IndexSet) {
        let stocksToDelete = offsets.map { normalStocks[$0] }
        stocks.removeAll { stock in
            stocksToDelete.contains { $0.symbol == stock.symbol && stock.bankId == bankId && stock.regularInvestment == nil }
        }
    }
    
    private func moveNormalStocks(from source: IndexSet, to destination: Int) {
        var sortOrder = normalStocks.map { $0.symbol }
        sortOrder.move(fromOffsets: source, toOffset: destination)
        
        let orderDict = Dictionary(uniqueKeysWithValues: sortOrder.enumerated().map { ($0.element, $0.offset) })
        stocks = stocks.sorted { (stock1, stock2) in
            guard stock1.bankId == bankId, stock2.bankId == bankId,
                  stock1.regularInvestment == nil, stock2.regularInvestment == nil else {
                return false
            }
            let index1 = orderDict[stock1.symbol] ?? 0
            let index2 = orderDict[stock2.symbol] ?? 0
            return index1 < index2
        }
    }
}
