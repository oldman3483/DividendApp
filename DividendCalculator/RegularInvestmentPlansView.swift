//
//  RegularInvestmentPlansView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/20.
//

import SwiftUI

struct RegularInvestmentPlansView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    let symbol: String
    let bankId: UUID
    
    // 添加編輯狀態
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var stockToDelete: Stock?
    
    // 計算屬性，但拆分為更簡單的函數
    private var regularInvestmentStocks: [Stock] {
        stocks.filter {
            $0.symbol == symbol &&
            $0.bankId == bankId &&
            $0.regularInvestment != nil
        }
    }
    
    // 預先計算各種總額，避免在視圖渲染時多次計算
    private func calculateTotalAmount() -> Double {
        regularInvestmentStocks.reduce(0.0) { $0 + ($1.regularInvestment?.amount ?? 0) }
    }
    
    private func calculateExecutedAmount() -> Double {
        regularInvestmentStocks.reduce(0.0) { sum, stock in
            sum + (stock.regularInvestment?.transactions?.filter { $0.isExecuted }.reduce(0.0) { $0 + $1.amount } ?? 0)
        }
    }
    
    private func calculatePendingAmount() -> Double {
        regularInvestmentStocks.reduce(0.0) { sum, stock in
            sum + (stock.regularInvestment?.transactions?.filter { !$0.isExecuted }.reduce(0.0) { $0 + $1.amount } ?? 0)
        }
    }
    
    private func calculateExecutedShares() -> Int {
        regularInvestmentStocks.reduce(0) { sum, stock in
            sum + (stock.regularInvestment?.transactions?.filter { $0.isExecuted }.reduce(0) { $0 + $1.shares } ?? 0)
        }
    }
    
    private func calculatePendingShares() -> Int {
        regularInvestmentStocks.reduce(0) { sum, stock in
            sum + (stock.regularInvestment?.transactions?.filter { !$0.isExecuted }.reduce(0) { $0 + $1.shares } ?? 0)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 基本資訊卡片 - 放在 List 外部
            summaryCard
                .padding(.horizontal)
                .padding(.vertical, 10)
            
            // 定期定額計劃列表 - 使用 List 來支持移動功能
            List {
                ForEach(regularInvestmentStocks) { stock in
                    NavigationLink(
                        destination: RegularInvestmentDetailView(
                            stocks: $stocks,
                            symbol: symbol,
                            bankId: bankId,
                            planId: stock.id
                        )
                    ) {
                        RegularInvestmentPlanCard(stock: stock, isEditing: isEditing)
                            .contentShape(Rectangle())
                            .padding(.vertical, 4)
                    }
                    .disabled(isEditing)
                    .listRowInsets(EdgeInsets(
                        top: 4,
                        leading: isEditing ? 0 : 16,
                        bottom: 4,
                        trailing: 16
                    ))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteRegularInvestmentPlans)
                .onMove(perform: moveRegularInvestmentPlans)
            }
            .listStyle(PlainListStyle())
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        }
        .navigationTitle("定期定額計畫")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.black.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !regularInvestmentStocks.isEmpty {
                    Button(isEditing ? "完成" : "編輯") {
                        withAnimation {
                            isEditing.toggle()
                        }
                    }
                }
            }
        }
        .alert("確認刪除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {
                stockToDelete = nil
            }
            Button("刪除", role: .destructive) {
                if let stock = stockToDelete {
                    deleteRegularInvestmentPlan(stock: stock)
                }
                stockToDelete = nil
            }
        } message: {
            Text("確定要刪除這個定期定額計劃嗎？")
        }
    }
    
    // 摘要卡片作為獨立視圖
    private var summaryCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // 股票基本資訊
                HStack {
                    Text(symbol)
                        .font(.title2)
                        .bold()
                    Text(regularInvestmentStocks.first?.name ?? "")
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)
                
                // 使用預先計算的值
                DetailRow(
                    title: "每期總投資",
                    value: String(format: "$ %.0f", calculateTotalAmount())
                )
                
                DetailRow(
                    title: "已執行投資",
                    value: String(format: "$ %.0f", calculateExecutedAmount()),
                    valueColor: .green
                )
                
                // 只在有待執行金額時顯示
                let pendingAmount = calculatePendingAmount()
                if pendingAmount > 0 {
                    DetailRow(
                        title: "待執行投資",
                        value: String(format: "$ %.0f", pendingAmount),
                        valueColor: .gray
                    )
                }
                
                // 執行狀態分隔線
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.vertical, 4)
                
                DetailRow(
                    title: "已執行股數",
                    value: "\(calculateExecutedShares()) 股",
                    valueColor: .green
                )
                
                // 只在有待執行股數時顯示
                let pendingShares = calculatePendingShares()
                if pendingShares > 0 {
                    DetailRow(
                        title: "待執行股數",
                        value: "\(pendingShares) 股",
                        valueColor: .gray
                    )
                }
            }
            .padding(.vertical, 8)
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // 刪除多個定期定額計劃
    private func deleteRegularInvestmentPlans(at offsets: IndexSet) {
        // 轉換偏移量為實際的股票
        let stocksToDelete = offsets.map { regularInvestmentStocks[$0] }
        
        // 刪除選定的計劃
        withAnimation {
            for stock in stocksToDelete {
                stocks.removeAll { $0.id == stock.id }
            }
            
            // 如果移除後沒有定期定額計劃，則退出編輯模式
            if regularInvestmentStocks.isEmpty {
                isEditing = false
            }
        }
    }
    
    // 移動定期定額計劃
    private func moveRegularInvestmentPlans(from source: IndexSet, to destination: Int) {
        // 創建一個包含預期順序的新數組
        var updatedStocks = regularInvestmentStocks
        updatedStocks.move(fromOffsets: source, toOffset: destination)
        
        // 遍歷共享的 stocks 數組，重新排列相關的項目
        var newStocks = stocks
        
        // 先移除所有相關的定期定額計劃
        newStocks.removeAll { stock in
            stock.symbol == symbol && stock.bankId == bankId && stock.regularInvestment != nil
        }
        
        // 再按新的順序添加回來
        for stock in updatedStocks {
            newStocks.append(stock)
        }
        
        // 更新綁定的 stocks 數組
        stocks = newStocks
    }
    
    // 單獨刪除定期定額計劃 (供 Alert 使用)
    private func deleteRegularInvestmentPlan(stock: Stock) {
        withAnimation {
            // 從 stocks 中移除該計劃
            stocks.removeAll { $0.id == stock.id }
            
            // 如果移除後沒有定期定額計劃，則退出編輯模式
            if regularInvestmentStocks.isEmpty {
                isEditing = false
            }
        }
    }
}
    


struct RegularInvestmentPlanCard: View {
    let stock: Stock
    var isEditing: Bool = false
    
    var body: some View {
        // 根據編輯模式決定顯示哪個視圖
        if isEditing {
            // 編輯模式下的精簡版卡片
            simplifiedCardContent
        } else {
            // 正常模式下的完整卡片
            fullCardContent
        }
    }
    
    // 精簡版卡片內容
    private var simplifiedCardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 標題
            Text(stock.regularInvestment?.title ?? "計畫")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            // 每期金額
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("每期金額")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(Int(stock.regularInvestment?.amount ?? 0).formattedWithComma)")
                        .font(.system(size: 17, weight: .medium))
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("投資頻率")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(stock.regularInvestment?.frequency.rawValue ?? "")
                        .font(.system(size: 15))
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(white: 0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isEditing ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .shadow(
            color: isEditing ? Color.blue.opacity(0.2) : Color.white.opacity(0.05),
            radius: isEditing ? 5 : 3,
            x: 0,
            y: isEditing ? 2 : 1
        )
        .padding(.horizontal, isEditing ? 5 : 0)
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
    
    // 完整卡片內容 (保留原有的實現)
    private var fullCardContent: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // 標題
                HStack {
                    Text(stock.regularInvestment?.title ?? "")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.bottom, 4)
                
                // 第一行：金額和頻率
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("每期金額")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("$\(Int(stock.regularInvestment?.amount ?? 0).formattedWithComma)")
                            .font(.system(size: 17, weight: .medium))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("投資頻率")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(stock.regularInvestment?.frequency.rawValue ?? "")
                            .font(.system(size: 15))
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // 第二行：日期和狀態
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("開始日期")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(formatDate(stock.regularInvestment?.startDate))
                            .font(.system(size: 14))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("狀態")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(stock.regularInvestment?.executionStatus.description ?? "未啟用")
                            .font(.system(size: 14))
                            .foregroundColor(stock.regularInvestment?.executionStatus.color ?? .gray)
                    }
                }
                
                // 第三行：已執行投資和股數
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("已執行投資")
                            .font(.caption)
                            .foregroundColor(.gray)
                        let executedAmount = stock.regularInvestment?.transactions?
                            .filter { $0.isExecuted }
                            .reduce(0.0) { $0 + $1.amount } ?? 0
                        Text("$\(Int(executedAmount).formattedWithComma)")
                            .font(.system(size: 15))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("已執行股數")
                            .font(.caption)
                            .foregroundColor(.gray)
                        let executedShares = stock.regularInvestment?.transactions?
                            .filter { $0.isExecuted }
                            .reduce(0) { $0 + $1.shares } ?? 0
                        Text("\(executedShares) 股")
                            .font(.system(size: 15))
                            .foregroundColor(.green)
                    }
                }
                
                // 第四行：待執行投資和股數（如果有的話）
                let pendingAmount = stock.regularInvestment?.transactions?
                    .filter { !$0.isExecuted }
                    .reduce(0.0) { $0 + $1.amount } ?? 0
                let pendingShares = stock.regularInvestment?.transactions?
                    .filter { !$0.isExecuted }
                    .reduce(0) { $0 + $1.shares } ?? 0
                
                if pendingAmount > 0 || pendingShares > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("待執行投資")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("$\(Int(pendingAmount).formattedWithComma)")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("待執行股數")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("\(pendingShares) 股")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // 備註（如果有的話）
                if let note = stock.regularInvestment?.note,
                   !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
        }
        .groupBoxStyle(TransparentGroupBox())
        .foregroundColor(.white)
        .cardBackground()
        // 點擊時的反饋效果
        .contentShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
        // hover 效果
        .hoverEffect(.highlight)
    }
}
