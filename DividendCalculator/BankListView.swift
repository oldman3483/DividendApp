//
//   BankListView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/31.
//

import SwiftUI

struct BankListView: View {
    @Binding var banks: [Bank]
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]
    @State private var showingAddBank = false
    @State private var isEditing = false
    @State private var showingRenameAlert = false
    @State private var bankToRename: Bank?
    @State private var newBankName = ""
    @State private var errorMessage: String = ""
    @State private var showingErrorAlert = false
    @State private var portfolioMetrics = PortfolioMetrics()
    
    private let stockService = LocalStockService()
    
    // 投資組合指標結構
    private struct PortfolioMetrics {
        var totalValue: Double = 0
        var dailyChange: Double = 0
        var dailyChangePercentage: Double = 0
        var totalProfitLoss: Double = 0
        var totalROI: Double = 0
        var totalAnnualDividend: Double = 0
        var dividendYield: Double = 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 投資組合總覽
                    bankListSummaryView
                    
                    if banks.isEmpty {
                        // 空狀態
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        // 銀行卡片列表
                        bankListContent
                    }
                }
                
                // 新增銀行按鈕
                AddBankButton(action: { showingAddBank = true })
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("我的銀行")
                        .navigationTitleStyle()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !banks.isEmpty {
                        Button(isEditing ? "完成" : "編輯") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddBank) {
            AddBankView(banks: $banks)
        }
        .alert("重新命名", isPresented: $showingRenameAlert) {
            TextField("新名稱", text: $newBankName)
                .autocorrectionDisabled(true)
            Button("取消", role: .cancel) { resetRenameState() }
            Button("確定") { renameSelectedBank() }
        } message: {
            Text("請輸入新的名稱")
        }
        .alert("錯誤", isPresented: $showingErrorAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await updatePortfolioMetrics()
        }
        .onChange(of: stocks) { _, _ in
            Task {
                await updatePortfolioMetrics()
            }
        }
    }
    
    // MARK: - 子視圖
    
    // 投資組合總覽視圖
    private var bankListSummaryView: some View {
        BankListSummaryView(
            totalValue: portfolioMetrics.totalValue,
            totalProfitLoss: portfolioMetrics.totalProfitLoss,
            totalROI: portfolioMetrics.totalROI,
            dailyChange: portfolioMetrics.dailyChange,
            dailyChangePercentage: portfolioMetrics.dailyChangePercentage,
            annualDividend: portfolioMetrics.totalAnnualDividend,
            dividendYield: portfolioMetrics.dividendYield
        )
        .padding(.horizontal, 12)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
    
    // 空狀態視圖
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("尚未新增任何銀行")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("點擊右下角的按鈕開始新增銀行")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
        }
    }
    
    // 銀行列表
    private var bankListContent: some View {
        List {
            ForEach(banks) { bank in
                bankCardView(for: bank)
                    .listRowInsets(EdgeInsets(
                        top: 4,
                        leading: isEditing ? 0 : 16,
                        bottom: 4,
                        trailing: 16
                    ))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete(perform: isEditing ? deleteBank : nil)
            .onMove(perform: moveBanks)
        }
        .listStyle(PlainListStyle())
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .padding(.horizontal, 0)
        .padding(.vertical, 8)
    }
    
    // 銀行卡片視圖
    private func bankCardView(for bank: Bank) -> some View {
        ZStack {
            // 卡片背景
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.15))
                .shadow(color: Color.white.opacity(0.05), radius: 4, x: 0, y: 2)
            
            if isEditing {
                // 編輯模式
                Button(action: {
                    bankToRename = bank
                    newBankName = bank.name
                    showingRenameAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                        
                        Text(bank.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            } else {
                // 一般模式
                HStack {
                    Text(bank.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 8)
            }
            
            NavigationLink(
                destination: PortfolioView(
                    stocks: $stocks,
                    watchlist: $watchlist,
                    banks: $banks,
                    bankId: bank.id,
                    bankName: bank.name
                )
            ) {
                EmptyView()
            }
            .opacity(0)
        }
        .frame(height: 44)
    }
    
    // MARK: - Helper Methods
    private func updatePortfolioMetrics() async {
        var metrics = PortfolioMetrics()
        
        // 篩選出屬於用戶所有銀行的股票
        let bankStocks = stocks.filter { stock in
            banks.contains { bank in
                bank.id == stock.bankId
            }
        }
        
        // 使用 StockValueService 獲取當前價格和前一日價格
        let stockValueService = StockValueService.shared
        let currentPrices = await stockValueService.getCurrentPrices(for: bankStocks)
        let previousPrices = await stockValueService.getPreviousDayPrices(for: bankStocks)
        
        // 計算總市值
        metrics.totalValue = await stockValueService.calculateTotalValue(for: bankStocks, currentPrices: currentPrices)
        
        // 計算總投資成本
        let totalInvestment = stockValueService.calculateTotalInvestment(for: bankStocks)
        
        // 計算當日損益和漲跌幅
        let (dailyChange, dailyChangePercentage) = stockValueService.calculateDailyChange(
            for: bankStocks,
            currentPrices: currentPrices,
            previousPrices: previousPrices
        )
        metrics.dailyChange = dailyChange
        metrics.dailyChangePercentage = dailyChangePercentage
        
        // 計算總報酬和報酬率
        metrics.totalProfitLoss = metrics.totalValue - totalInvestment
        metrics.totalROI = totalInvestment > 0 ? (metrics.totalProfitLoss / totalInvestment) * 100 : 0
        
        // 計算年化股利和股利率
        metrics.totalAnnualDividend = stockValueService.calculateAnnualDividend(for: bankStocks)
        metrics.dividendYield = metrics.totalValue > 0 ? (metrics.totalAnnualDividend / metrics.totalValue) * 100 : 0
        
        // 在主線程更新UI
        await MainActor.run {
            self.portfolioMetrics = metrics
        }
    }
    
    private func deleteBank(at offsets: IndexSet) {
        let banksToDelete = offsets.map { banks[$0] }
        stocks.removeAll { stock in
            banksToDelete.contains { $0.id == stock.bankId }
        }
        banks.remove(atOffsets: offsets)
    }
    
    private func moveBanks(from source: IndexSet, to destination: Int) {
        banks.move(fromOffsets: source, toOffset: destination)
    }
    
    private func renameSelectedBank() {
        let trimmedName = newBankName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "銀行名稱不能為空"
            showingErrorAlert = true
            return
        }
        
        if let bank = bankToRename,
           let bankIndex = banks.firstIndex(where: { $0.id == bank.id }) {
            if banks.contains(where: { $0.name == trimmedName && $0.id != bank.id }) {
                errorMessage = "已存在相同名稱的銀行"
                showingErrorAlert = true
                return
            }
            
            let updatedBank = Bank(
                id: banks[bankIndex].id,
                name: trimmedName,
                createdDate: banks[bankIndex].createdDate
            )
            
            banks[bankIndex] = updatedBank
            resetRenameState()
        }
    }
    
    private func resetRenameState() {
        bankToRename = nil
        newBankName = ""
        showingRenameAlert = false
    }
}
