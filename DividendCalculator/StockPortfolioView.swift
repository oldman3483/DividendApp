//
//  StockPortfolioView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/24.
//

import SwiftUI

struct StockPortfolioView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    @State private var isEditing = false
    @State private var showingSearchView = false
    @State private var selectedStock: WeightedStockInfo?
    @State private var showingDetail = false
    
    let bankId: UUID
    let bankName: String
    
    private var bankStocks: [Stock] {
        stocks.filter { stock in
            stock.bankId == bankId
        }
    }
    
    private var groupedStocks: [WeightedStockInfo] {
        stocks.calculateWeightedAverage(forBankId: bankId)
    }
    
    private var totalAnnualDividend: Double {
        groupedStocks.reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 總覽區塊
                List {
                    Section {
                        VStack {
                            HStack {
                                Text("總持股數")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(groupedStocks.count) 檔")
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
                    

                    if groupedStocks.isEmpty {
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
                    } else {
                        // 股票列表
                        Section {
                            ForEach(groupedStocks) { stockInfo in
                                ZStack {
                                    StockSummaryRow(
                                        stockInfo: stockInfo,
                                        isEditing: isEditing
                                    )
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
                                        Button(action: {
                                            selectedStock = stockInfo
                                            showingDetail = true
                                        }) {
                                            EmptyView()
                                        }
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
                            .onDelete(perform: deleteStocks)
                            .onMove(perform: moveStocks)
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
                if !groupedStocks.isEmpty {
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
                StockDetailView(
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
    
    private func deleteStocks(at offsets: IndexSet) {
        let stocksToDelete = offsets.map { groupedStocks[$0] }
        stocks.removeAll { stock in
            stocksToDelete.contains { $0.symbol == stock.symbol && stock.bankId == bankId }
        }
    }
    
    private func moveStocks(from source: IndexSet, to destination: Int) {
        var sortOrder = groupedStocks.map { $0.symbol }
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
