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
    @State private var showingAddBank = false
    @State private var isEditing = false
    @State private var showingRenameAlert = false
    @State private var bankToRename: Bank?
    @State private var newBankName = ""
    @State private var errorMessage: String = ""
    @State private var showingErrorAlert = false
    
    // 新增狀態屬性來存儲計算值
    @State private var portfolioMetrics: PortfolioMetrics = PortfolioMetrics()
    private let stockService = LocalStockService()
    
    // 定義一個結構來存儲投資組合指標
    private struct PortfolioMetrics {
        var totalValue: Double = 0
        var dailyChange: Double = 0
        var dailyChangePercentage: Double = 0
        var totalProfitLoss: Double = 0
        var totalROI: Double = 0
        var totalAnnualDividend: Double = 0
        var dividendYield: Double = 0
    }

    private var portfolioSummary: some View {
        VStack(spacing: 15) {
            HStack {
                Text("投資組合總覽")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // 總市值
                summaryCard(
                    title: "總市值",
                    value: "$\(Int(portfolioMetrics.totalValue).formattedWithComma)",
                    change: String(format: "%.1f%%", abs(portfolioMetrics.dailyChangePercentage)),
                    isPositive: portfolioMetrics.dailyChangePercentage >= 0
                )
                
                // 總投資報酬
                summaryCard(
                    title: "總投資報酬",
                    value: "$\(Int(portfolioMetrics.totalProfitLoss).formattedWithComma)",
                    change: String(format: "%.1f%%", abs(portfolioMetrics.totalROI)),
                    isPositive: portfolioMetrics.totalProfitLoss >= 0
                )
                
                // 當日損益
                summaryCard(
                    title: "當日損益",
                    value: "$\(Int(abs(portfolioMetrics.dailyChange)).formattedWithComma)",
                    change: String(format: "%.2f%%", abs(portfolioMetrics.dailyChangePercentage)),
                    isPositive: portfolioMetrics.dailyChange >= 0
                )
                
                // 年化股利收益率
                summaryCard(
                    title: "年化股利率",
                    value: String(format: "%.1f%%", portfolioMetrics.dividendYield),
                    subValue: "年化股利 $\(Int(portfolioMetrics.totalAnnualDividend).formattedWithComma)",
                    showChange: false
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private func summaryCard(
        title: String,
        value: String,
        change: String? = nil,
        subValue: String? = nil,
        isPositive: Bool = true,
        showChange: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            if showChange, let change = change {
                HStack(spacing: 4) {
                    Image(systemName: isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 10))
                    Text(change)
                        .font(.system(size: 12))
                }
                .foregroundColor(isPositive ? .green : .red)
            }
            
            if let subValue = subValue {
                Text(subValue)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .flashAnimation(isPositive: isPositive)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                        portfolioSummary
                            .padding(.top)
                    List {
                        // 添加一個空白 Section 來處理頂部間距
                        Section {
                            EmptyView()
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .frame(height: 0)
                        
                        ForEach(banks) { bank in
                            ZStack {
                                BankCardView(
                                    bank: bank,
                                    isEditing: isEditing,
                                    onRename: { bank in
                                        bankToRename = bank
                                        newBankName = bank.name
                                        showingRenameAlert = true
                                    }
                                )
                                if !isEditing {
                                    NavigationLink(
                                        destination: StockPortfolioView(
                                            stocks: $stocks,
                                            bankId: bank.id,
                                            bankName: bank.name
                                        )
                                    ) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                }
                            }
                            .listRowBackground(Color.black)
                            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteBank)
                        .onMove(perform: moveBanks)
                    }
                    .listStyle(PlainListStyle())
                    .listRowSpacing(10)
                    .background(Color.black)
                }
                
                if banks.isEmpty {
                    VStack {
                        Text("尚未新增任何銀行")
                            .font(.headline)
                            .foregroundColor(.white)
                            .offset(y:100)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
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
                        .foregroundColor(.white)
                    }
                }
            }
            .padding(.top, 25)
        }
        .sheet(isPresented: $showingAddBank) {
            AddBankView(banks: $banks)
        }
        .alert("重新命名銀行", isPresented: $showingRenameAlert) {
            TextField("銀行名稱", text: $newBankName)
                .autocorrectionDisabled(true)
            Button("取消", role: .cancel) {
                resetRenameState()
            }
            Button("確定") {
                renameSelectedBank()
            }
        } message: {
            Text("請輸入新的銀行名稱")
        }
        .alert("錯誤", isPresented: $showingErrorAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
        .task {
            await updatePortfolioMetrics()
        }
        .onChange(of: stocks) { _, _ in
            Task {
                await updatePortfolioMetrics()
            }
        }
    }
    
    // 新增更新投資組合指標的方法
    private func updatePortfolioMetrics() async {
        var metrics = PortfolioMetrics()
        
        let bankStocks = stocks.filter { stock in
            banks.contains { bank in
                bank.id == stock.bankId
            }
        }
        
        for stock in bankStocks {
            if let currentPrice = await stockService.getStockPrice(symbol: stock.symbol, date: Date()) {
                let stockValue = Double(stock.shares) * currentPrice
                metrics.totalValue += stockValue
                
                // 計算總損益
                let profitLoss = stock.calculateProfitLoss(currentPrice: currentPrice)
                metrics.totalProfitLoss += profitLoss
                
                // 獲取昨日價格來計算當日損益
                if let yesterdayPrice = await stockService.getStockPrice(
                    symbol: stock.symbol,
                    date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                ) {
                    // 計算當日損益
                    let dailyPriceChange = currentPrice - yesterdayPrice
                    metrics.dailyChange += Double(stock.shares) * dailyPriceChange
                }
                
                // 計算報酬率
                metrics.totalROI = (metrics.totalProfitLoss / metrics.totalValue) * 100
            }
            
            // 計算年化股利
            metrics.totalAnnualDividend += stock.calculateAnnualDividend()
        }
        
        // 計算百分比
        if metrics.totalValue > 0 {
            metrics.dailyChangePercentage = (metrics.dailyChange / metrics.totalValue) * 100
            metrics.dividendYield = (metrics.totalAnnualDividend / metrics.totalValue) * 100
        }
        
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

#Preview {
    ContentView()
}


