//
//  OverviewView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/4/24.
//  Updated on 2025/5/15.
//

import SwiftUI

struct OverviewView: View {
    @Binding var banks: [Bank]
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]
    
    // 使用 AppStorage
    @AppStorage("targetAmount") private var targetAmount: Double?
    @AppStorage("currentAmount") private var currentAmount: Double?
    @AppStorage("targetYear") private var targetYear: Int?
    
    
    // 狀態變數
    @State private var totalValue: Double = 0
    @State private var annualDividend: Double = 0
    @State private var roi: Double = 0
    @State private var dividendYield: Double = 0
    @State private var isLoading: Bool = true
    @State private var currentPrices: [String: Double] = [:]
    @State private var totalInvestment: Double = 0


    // 服務
    private let portfolioManager = PortfolioManager.shared

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
            // 載入數據
            Task {
                await loadInvestmentData()
            }
            
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
        .onChange(of: stocks) { _, _ in
            // 股票資料變更時重新載入
            Task {
                await loadInvestmentData()
            }
        }
    }
    
    // 載入投資數據
    private func loadInvestmentData() async {
        isLoading = true
        
        // 使用統一的服務載入數據
        currentPrices = await portfolioManager.getCurrentPrices(for: stocks)
        totalValue = await portfolioManager.calculateTotalValue(for: stocks, currentPrices: currentPrices)
        annualDividend = portfolioManager.calculateAnnualDividend(for: stocks)
        roi = await portfolioManager.calculateTotalROI(for: stocks, currentPrices: currentPrices)
        dividendYield = totalValue > 0 ? (annualDividend / totalValue) * 100 : 0
        totalInvestment = portfolioManager.calculateTotalInvestment(for: stocks)

        
        isLoading = false
    }
    
    // 投資總覽卡片
    private var investmentOverviewCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                // 標題和查看全部按鈕
                HStack {
                    Text("投資總覽")
                        .font(.headline)
                    Spacer()
                    NavigationLink(destination: InvestmentOverviewView(stocks: $stocks)) {
                        Text("查看全部")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 8)
                
                // 上方顯示總市值和年化股利
                HStack(spacing: 15) {
                    MainMetricCard(
                        title: "總市值",
                        value: formatCurrency(totalValue),
                        change: formatPercentage(roi),
                        isPositive: roi >= 0
                    )
                    
                    MainMetricCard(
                        title: "年化股利",
                        value: formatCurrency(annualDividend),
                        change: "\(Int(dividendYield * 100) / 100)%",
                        isPositive: true
                    )
                }
                
                // 下方顯示總報酬率和總投資成本
                HStack(spacing: 15) {
                    MainMetricCard(
                        title: "總報酬率",
                        value: formatPercentage(roi),
                        change: formatCurrency(totalValue - totalInvestment),
                        isPositive: roi >= 0
                    )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("總投資成本")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text(formatCurrency(totalInvestment))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.15))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // 目標規劃區塊 - 修改後使用卡片方式呈現
    private var goalPlanningCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("我的規劃")
                        .font(.headline)
                    Spacer()
                    NavigationLink(destination: PlanningListView(stocks: $stocks,banks: $banks)) {
                        Text("查看全部")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                
                // 取得前三個規劃來呈現
                let plans = getRecentPlans(limit: 3)
                
                if plans.isEmpty {
                    // 空狀態視圖
                    VStack(alignment: .center, spacing: 15) {
                        Text("尚未設定投資目標")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("點擊下方按鈕開始設定您的投資規劃")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        NavigationLink(destination: GoalCalculatorView(onSave: { newPlan in
                            // 這裡添加保存新計劃的邏輯
                            // 可以直接保存到UserDefaults或使用相同的邏輯
                            if let planData = UserDefaults.standard.data(forKey: "investmentPlans"),
                               var plans = try? JSONDecoder().decode([InvestmentPlan].self, from: planData) {
                                plans.append(newPlan)
                                if let encodedPlans = try? JSONEncoder().encode(plans) {
                                    UserDefaults.standard.set(encodedPlans, forKey: "investmentPlans")
                                }
                            } else {
                                let plans = [newPlan]
                                if let encodedPlans = try? JSONEncoder().encode(plans) {
                                    UserDefaults.standard.set(encodedPlans, forKey: "investmentPlans")
                                }
                            }
                        })) {
                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.white)
                                Text("建立我的規劃")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
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
                    // 橫向滾動的規劃卡片
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(plans) { plan in
                                PlanCardPreview(plan: plan, stocks: $stocks, banks: $banks)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }

    // 獲取最近的規劃
    private func getRecentPlans(limit: Int) -> [InvestmentPlan] {
        if let planData = UserDefaults.standard.data(forKey: "investmentPlans"),
           let plans = try? JSONDecoder().decode([InvestmentPlan].self, from: planData) {
            return Array(plans.prefix(limit))
        }
        return []
    }

    // 規劃卡片預覽 - 新增組件
    struct PlanCardPreview: View {
        let plan: InvestmentPlan
        
        @Binding var stocks: [Stock]
        @Binding var banks: [Bank]
        
        var body: some View {
            NavigationLink(destination: PlanningDetailView(
                plan: plan,
                onUpdate: { _ in },
                stocks: $stocks,
                banks: $banks
            )) {
                VStack(alignment: .leading, spacing: 8) {
                    // 第一行：規劃標題
                    Text(plan.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    // 第二行：股票代號和名稱
                    Text("\(plan.symbol) \(getStockName(plan.symbol))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    // 第三行：目標金額
                    Text("目標: $\(Int(plan.targetAmount).formattedWithComma)")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    // 第四行：投資年限和頻率
                    Text("\(plan.investmentYears)年・\(getFrequencyText(plan.investmentFrequency))")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
                .padding()
                .cardBackground()
            }
            .buttonStyle(PlainButtonStyle())
        }
        
        // 獲取股票名稱
        private func getStockName(_ symbol: String) -> String {
            // 檢查用戶投資組合
            if let stockInPortfolio = stocks.first(where: { $0.symbol == symbol }) {
                return stockInPortfolio.name
            }
            
            // 沒找到則返回股票代號作為名稱
            return ""
        }
        
        // 格式化頻率文本
        private func getFrequencyText(_ frequency: Int) -> String {
            switch frequency {
            case 1:
                return "每年"
            case 4:
                return "每季"
            case 12:
                return "每月"
            default:
                return "自訂"
            }
        }
    }
    
    // 我的庫存卡片 - 統一使用 GroupBox
    private var myStocksCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("我的庫存")
                        .font(.headline)
                    Spacer()
                    NavigationLink(destination: BankListView(
                        banks: $banks,
                        stocks: $stocks,
                        watchlist: $watchlist
                    )) {
                        Text("查看全部")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                
                // 庫存預覽
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(banks) { bank in
                            BankCardPreview(
                                banks: $banks,
                                stocks: $stocks,
                                watchlist: $watchlist,
                                bank: bank,
                                currentPrices: currentPrices
                            )
                        }
                    }
                }
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

// BankCardPreview 使用統一的 PortfolioManager
struct BankCardPreview: View {
    @Binding var banks: [Bank]
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]
    
    let bank: Bank
    var currentPrices: [String: Double] = [:]
    
    // 狀態變數
    @State private var totalValue: Double = 0
    @State private var annualDividend: Double = 0
    @State private var isLoading: Bool = true
    
    var body: some View {
        NavigationLink(destination: PortfolioView(
            stocks: $stocks,
            watchlist: $watchlist,
            banks: $banks,
            bankId: bank.id,
            bankName: bank.name
        )
        ){
            VStack(alignment: .leading, spacing: 8) {
                Text(bank.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Text("$\(Int(totalValue).formattedWithComma)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    
                    HStack {
                        Text("\(bank.getStocks(from: stocks).count) 支股票")
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
            }
            .padding(12)
            .frame(width: 170, height: 110)
            .cardBackground()
            .onAppear {
                Task {
                    await loadBankData()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 載入銀行數據
    private func loadBankData() async {
        isLoading = true
        
        // 計算總市值
        totalValue = await bank.calculateBankTotalValue(allStocks: stocks)
        
        // 計算年化股利
        annualDividend = bank.calculateAnnualDividend(allStocks: stocks)
        
        isLoading = false
    }
}
