//
//  OverviewView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/4/24.
//

import SwiftUI

struct OverviewView: View {
    @Binding var banks: [Bank]
    @Binding var stocks: [Stock]
    
    // 使用 AppStorage
    @AppStorage("targetAmount") private var targetAmount: Double?
    @AppStorage("currentAmount") private var currentAmount: Double?
    @AppStorage("targetYear") private var targetYear: Int?
    
    // 股票服務
    private let stockService = LocalStockService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 投資總覽卡片
                    investmentOverviewCard
                    
                    // 目標規劃區塊
                    goalPlanningCard
                    
                    // 我的庫存區塊
                    myStocksCard
                    
                    // 投資摘要區塊
                    investmentSummaryCard
                    
                    // 投資規劃區塊
                    goalCalculatorCard
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("總覽")
                        .navigationTitleStyle()
                }
            }
        }
        .onAppear {
            // 添加清除數據的通知觀察者
            NotificationCenter.default.addObserver(
                forName: Notification.Name("ClearAllData"),
                object: nil,
                queue: .main
            ) { _ in
                // 重置我的規劃數據
                self.targetAmount = 1_000_000
                self.currentAmount = 0  // 設置為0，因為清除所有數據
                self.targetYear = 2028
            }
        }
        .onDisappear {
            // 移除觀察者
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    
    // 投資總覽卡片 - 使用 GroupBox 和細分的 MainMetricCard
    private var investmentOverviewCard: some View {
        GroupBox {
            HStack(spacing: 15) {
                MainMetricCard(
                    title: "總市值",
                    value: formatCurrency(calculateTotalValue()),
                    change: formatPercentage(calculateROI()),
                    isPositive: calculateROI() >= 0
                )
                
                MainMetricCard(
                    title: "年化股利",
                    value: formatCurrency(calculateAnnualDividend()),
                    change: "\(Int(calculateDividendYield() * 100) / 100)%",
                    isPositive: true
                )
            }
            .padding(.vertical, 8)
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // 目標規劃卡片 - 統一使用 GroupBox
    private var goalPlanningCard: some View {
        GroupBox {
            if targetAmount == nil || currentAmount == nil || targetYear == nil {
                // 空狀態視圖
                VStack(alignment: .center, spacing: 15) {
                    Text("尚未設定投資目標")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("點擊下方按鈕開始設定您的投資規劃")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    NavigationLink(destination: GoalCalculatorView()) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.white)
                            Text("建立我的規劃")
                                .font(.system(size: 15))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .padding(.top, 10)
                }
                .padding()
            } else {
                // 已設定目標時的視圖 (與原先相同)
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("我的規劃")
                            .font(.headline)
                        Spacer()
                        NavigationLink(destination: GoalCalculatorView()) {
                            Text("詳細規劃")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // 進度條
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 20)
                                .cornerRadius(10)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * CGFloat((currentAmount ?? 0) / (targetAmount ?? 1)), height: 20)
                                .cornerRadius(10)
                        }
                    }
                    .frame(height: 20)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("目標金額")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text("$\(Int(targetAmount ?? 0).formattedWithComma)")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("預計達成")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text("\(targetYear ?? 0)年")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text("已投資: $\(Int(currentAmount ?? 0).formattedWithComma)")
                        .font(.system(size: 15))
                        .foregroundColor(.green)
                }
                .padding()
            }
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // 我的庫存卡片 - 統一使用 GroupBox
    private var myStocksCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("我的庫存")
                        .font(.headline)
                    Spacer()
                    NavigationLink(destination: BankListView(banks: $banks, stocks: $stocks)) {
                        Text("查看全部")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                
                // 庫存預覽
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(banks) { bank in
                            BankCardPreview(bank: bank, stocks: stocks)
                        }
                    }
                }
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // 投資摘要卡片 - 統一使用 GroupBox 和間距
    private var investmentSummaryCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                Text("投資摘要")
                    .font(.headline)
                
                HStack {
                    Text("風險評級")
                        .foregroundColor(.gray)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("中等")
                            .foregroundColor(.yellow)
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("資產配置")
                        .font(.system(size: 15, weight: .medium))
                        .padding(.bottom, 2)
                    
                    assetAllocationRow(name: "半導體", percentage: 40)
                    assetAllocationRow(name: "金融", percentage: 25)
                    assetAllocationRow(name: "電子", percentage: 20)
                    assetAllocationRow(name: "其他", percentage: 15)
                }
                .padding(.top, 4)
                
                HStack {
                    Text("近期股利預測")
                        .foregroundColor(.gray)
                    Spacer()
                    Text("$15,000")
                        .foregroundColor(.green)
                }
                .padding(.top, 5)
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // 投資規劃卡片 - 與其他卡片一致的樣式
    private var goalCalculatorCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                Text("投資目標規劃器")
                    .font(.headline)
                
                Text("設定您的投資目標，我們將協助您計算所需的投資步驟")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                NavigationLink(destination: GoalCalculatorView()) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.white)
                        Text("開始設定我的投資規劃")
                            .font(.system(size: 15))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // MARK: - 輔助視圖
    
    // 資產配置行
    private func assetAllocationRow(name: String, percentage: Int) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(getColorForAsset(name))
                        .frame(width: geometry.size.width * CGFloat(percentage) / 100, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(percentage)%")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    // MARK: - 輔助方法
    
    // 計算總市值
    private func calculateTotalValue() -> Double {
        let currentPrices = getCurrentPrices()
        return stocks.reduce(0) { total, stock in
            guard let currentPrice = currentPrices[stock.symbol] else { return total }
            
            // 一般持股市值
            let normalValue = Double(stock.shares) * currentPrice
            
            // 定期定額市值（已執行的交易）
            let regularValue = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { sum, transaction in
                    sum + (Double(transaction.shares) * currentPrice)
                } ?? 0
                
            return total + normalValue + regularValue
        }
    }
    
    // 計算年化股利
    private func calculateAnnualDividend() -> Double {
        stocks.reduce(0) { total, stock in
            // 一般持股的年化股利
            let normalDividend = Double(stock.shares) * stock.dividendPerShare * Double(stock.frequency)
            
            // 定期定額的年化股利（已執行的交易）
            let regularShares = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { sum, transaction in
                    sum + transaction.shares
                } ?? 0
            let regularDividend = Double(regularShares) * stock.dividendPerShare * Double(stock.frequency)
            
            return total + normalDividend + regularDividend
        }
    }
    
    // 計算投資報酬率
    private func calculateROI() -> Double {
        let totalValue = calculateTotalValue()
        
        let totalInvestment = stocks.reduce(0) { total, stock in
            // 一般持股成本
            let normalCost = Double(stock.shares) * (stock.purchasePrice ?? 0)
            
            // 定期定額成本（已執行的交易）
            let regularCost = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { sum, transaction in
                    sum + transaction.amount
                } ?? 0
                
            return total + normalCost + regularCost
        }
        
        return totalInvestment > 0 ? ((totalValue - totalInvestment) / totalInvestment) * 100 : 0
    }
    
    // 計算股利殖利率
    private func calculateDividendYield() -> Double {
        let totalValue = calculateTotalValue()
        let annualDividend = calculateAnnualDividend()
        
        return totalValue > 0 ? (annualDividend / totalValue) * 100 : 0
    }
    
    // 獲取當前股價
    private func getCurrentPrices() -> [String: Double] {
        var prices: [String: Double] = [:]
        
        // 由於是非同步方法，這裡假設值並返回
        for stock in stocks {
            prices[stock.symbol] = Double.random(in: 90...120)
        }
        
        return prices
    }
    
    // 格式化金額
    private func formatCurrency(_ value: Double) -> String {
        return "$\(Int(value).formattedWithComma)"
    }
    
    // 格式化百分比
    private func formatPercentage(_ value: Double) -> String {
        return String(format: "%.1f%%", abs(value))
    }
    
    // 根據資產類型獲取顏色
    private func getColorForAsset(_ name: String) -> Color {
        switch name {
        case "半導體":
            return .blue
        case "金融":
            return .green
        case "電子":
            return .purple
        case "其他":
            return .orange
        default:
            return .gray
        }
    }
}

// BankListSummaryView 中的 MainMetricCard 風格
struct BankCardPreview: View {
    let bank: Bank
    let stocks: [Stock]
    
    // 該銀行的股票
    private var bankStocks: [Stock] {
        stocks.filter { $0.bankId == bank.id }
    }
    
    // 計算總市值
    private var totalValue: Double {
        let currentPrices = getCurrentPrices()
        return bankStocks.reduce(0) { total, stock in
            guard let currentPrice = currentPrices[stock.symbol] else { return total }
            
            // 一般持股市值
            let normalValue = Double(stock.shares) * currentPrice
            
            // 定期定額市值（已執行的交易）
            let regularValue = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { sum, transaction in
                    sum + (Double(transaction.shares) * currentPrice)
                } ?? 0
                
            return total + normalValue + regularValue
        }
    }
    
    // 計算年化股利
    private var annualDividend: Double {
        bankStocks.reduce(0) { total, stock in
            // 一般持股的年化股利
            let normalDividend = Double(stock.shares) * stock.dividendPerShare * Double(stock.frequency)
            
            // 定期定額的年化股利（已執行的交易）
            let regularShares = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { sum, transaction in
                    sum + transaction.shares
                } ?? 0
            let regularDividend = Double(regularShares) * stock.dividendPerShare * Double(stock.frequency)
            
            return total + normalDividend + regularDividend
        }
    }
    
    var body: some View {
        NavigationLink(destination: PortfolioView(stocks: .constant(stocks), bankId: bank.id, bankName: bank.name)) {
            VStack(alignment: .leading, spacing: 8) {
                Text(bank.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("$\(Int(totalValue).formattedWithComma)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
                
                HStack {
                    Text("\(bankStocks.count) 支股票")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down.forward.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text("$\(Int(annualDividend).formattedWithComma)")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(12)
            .frame(width: 170, height: 110)
            .cardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 獲取當前股價的輔助方法
    private func getCurrentPrices() -> [String: Double] {
        var prices: [String: Double] = [:]
        
        bankStocks.forEach { stock in
            prices[stock.symbol] = Double.random(in: 90...120)
        }
        
        return prices
    }
}

#Preview {
    ContentView()
}
