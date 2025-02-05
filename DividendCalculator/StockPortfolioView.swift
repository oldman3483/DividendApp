//
//  StockPortfolioView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/24.
//


import SwiftUI

// 自定義修飾符：處理編輯模式的視覺效果
struct EditModeViewModifier: ViewModifier {
    let isEditing: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEditing ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .shadow(
                color: isEditing ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1),
                radius: isEditing ? 8 : 2,
                x: 0,
                y: isEditing ? 4 : 1
            )
            .animation(.easeInOut(duration: 0.3), value: isEditing)
    }
}

struct StockPortfolioView: View {
    // MARK: - 屬性
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    @Binding var isEditing: Bool
    
    let bankId: UUID
    let bankName: String
    
    @State private var selectedStock: WeightedStockInfo?
    @State private var showingDetail = false
    @State private var searchText: String = ""

    
    
    // MARK: - 計算屬性
    
    private var bankStocks: [Stock] {
        stocks.filter { stock in
            stock.bankId == bankId
        }
    }
    private var groupedStocks: [WeightedStockInfo] {
        print("Debug - Current bankId: \(bankId)")
        print("Debug - All stocks: \(stocks)")
        let filteredStocks = stocks.filter { $0.bankId == bankId }
        print("Debug - Filtered stocks: \(filteredStocks)")
        return stocks.calculateWeightedAverage(forBankId: bankId)
    }
    
    private var totalAnnualDividend: Double {
        groupedStocks.reduce(0) { $0 + $1.calculateTotalAnnualDividend() }
    }
    
    
    
    // MARK: - 視圖主體
    var body: some View {
        NavigationStack {
                List {
                    // 總覽區塊
                    Section {
                        HStack {
                            Text("總持股數")
                            Spacer()
                            Text("\(groupedStocks.count) 檔")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("預估年化股利")
                            Spacer()
                            Text("$\(String(format: "%.0f", totalAnnualDividend))")
                                .foregroundColor(.green)
                        }
                    }
                    .listRowBackground(Color.clear)
                    
                    // 股票列表區塊
                    Section {
                        ForEach(groupedStocks, id: \.symbol) { stockInfo in
                            Group {
                                if isEditing {
                                    // 編輯模式視圖
                                    StockSummaryRow(
                                        stockInfo: stockInfo,
                                        isEditing: true
                                    )
                                } else {
                                    // 一般模式視圖
                                    Button(action: {
                                        selectedStock = stockInfo
                                        showingDetail = true
                                    }) {
                                        StockSummaryRow(stockInfo: stockInfo, isEditing: false)
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                            .modifier(EditModeViewModifier(isEditing: isEditing))
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete(perform: isEditing ? deleteStocks : nil)
                        .onMove(perform: isEditing ? moveStocks : nil)
                    }
                    .listRowBackground(Color.clear)
                }
                .environment(\.editMode, .constant(isEditing ? /*EditMode*/.active : /*EditMode*/.inactive))
                .padding(.top, 20)  // 新增這一行
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(bankName)
                            .navigationTitleStyle()
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditing ? "完成" : "編輯") {
                            withAnimation {
                            isEditing.toggle()
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
                    StockDetailView(stockInfo: stockInfo)
                }
            }
        }
    }
    
    private func deleteStock(_ stockInfo: WeightedStockInfo) {
        stocks.removeAll { stock in
            stockInfo.symbol == stock.symbol && stock.bankId == bankId
        }
    }
    // MARK: - 輔助方法
    private func deleteStocks(at offsets: IndexSet) {
        let stocksToDelete = offsets.map { groupedStocks[$0] }
        stocks.removeAll { stock in
            stocksToDelete.contains { weightedStock in
                weightedStock.symbol == stock.symbol && stock.bankId == bankId
            }
        }
    }
    
    // 更新移動方法
    private func moveStocks(from source: IndexSet, to destination: Int) {
        var sortOrder = groupedStocks.map { $0.symbol }
        sortOrder.move(fromOffsets: source, toOffset: destination)
        
        // 建立排序順序字典
        let orderDict = Dictionary(uniqueKeysWithValues: sortOrder.enumerated().map { ($0.element, $0.offset) })
        
        // 根據新的順序排序股票

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

// MARK: - 股票摘要行視圖
struct StockSummaryRow: View {
    let stockInfo: WeightedStockInfo
    let isEditing: Bool

    
    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .regular))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // 第一行：股票代號和名稱
                HStack {
                    Text(stockInfo.symbol)
                        .font(.headline)
                    Text(stockInfo.name)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(stockInfo.totalShares)股")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // 第二行：股利信息
                HStack {
                    VStack(alignment: .leading) {
                        Text("加權股利")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("$\(String(format: "%.2f", stockInfo.weightedDividendPerShare))")
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("年化股利")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("$\(String(format: "%.0f", stockInfo.calculateTotalAnnualDividend()))")
                            .foregroundColor(.green)
                    }
                }
            }
            // 非編輯模式顯示箭頭，編輯模式顯示編輯圖示
            if !isEditing {
//                Menu {
//                    Button(role: .destructive) {
//                        onDelete?()
//                    } label: {
//                        Label("刪除", systemImage: "trash")
//                    }
//                } label: {
//                    Image(systemName: "ellipsis.circle")
//                        .foregroundColor(.blue)
//                }
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
//            } else {
//                Image(systemName: "chevron.right")
//                    .foregroundColor(.gray)
//                    .font(.system(size: 14, weight: .semibold))
//                Image(systemName: "pencil")
//                    .foregroundColor(.blue)
//                    .bodyStyle()
//                    .contextMenu {
//                        Button(role: .destructive) {
//                            onDelete?()
//                        } label: {
//                            Label("刪除", systemImage: "trash")
//                        }
//                    }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}

