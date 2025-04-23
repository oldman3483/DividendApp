//
//  InvestmentOverviewView.swift
//  DividendCalculator
//
//  Created on 2025/3/9.
//  Updated with modular structure
//

import SwiftUI
import Charts

struct InvestmentOverviewView: View {
    @Binding var stocks: [Stock]
    @State private var selectedTimeRange = "1季"
    @State private var selectedAnalysisType = "amount"
    @State private var selectedViewMode = "overview"
    @State private var isLoading = false
    @State private var investmentMetrics = InvestmentMetrics()
    @State private var showCustomDatePicker = false
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var isCustomRangeActive = false
    @State private var metricsService: CustomRangeMetricsService?
    @State private var showReportGenerator = false

    
    private let timeRanges = ["1季", "1年", "3年", "5年", "自訂"]
    private let analysisTypes = ["amount", "yield"]
    private let viewModes = ["overview", "allocation", "monthly", "growth", "risk"]
    private let stockService = LocalStockService()
    
    // 在 InvestmentOverviewView 結構體中添加這個計算屬性
    private var selectedContentView: some View {
        Group {
            switch selectedViewMode {
            case "overview":
                OverviewTabView(
                    stocks: $stocks,
                    metrics: $investmentMetrics,
                    selectedTimeRange: $selectedTimeRange,
                    selectedAnalysisType: $selectedAnalysisType,
                    showReportGenerator: $showReportGenerator,
                    timeRanges: timeRanges,
                    stockService: stockService
                )
                
            case "allocation":
                AllocationTabView(
                    metrics: $investmentMetrics,
                    isLoading: $isLoading
                )
                
            case "monthly":
                MonthlyTabView(
                    metrics: $investmentMetrics,
                    isLoading: $isLoading
                )
                
            case "growth":
                GrowthTabView(
                    metrics: $investmentMetrics,
                    isLoading: $isLoading
                )
                
            case "risk":
                RiskTabView(
                    metrics: $investmentMetrics,
                    isLoading: $isLoading,
                    selectedTimeRange: $selectedTimeRange
                )
                
            default:
                // 處理意外狀況，預設顯示概覽視圖
                OverviewTabView(
                    stocks: $stocks,
                    metrics: $investmentMetrics,
                    selectedTimeRange: $selectedTimeRange,
                    selectedAnalysisType: $selectedAnalysisType,
                    showReportGenerator: $showReportGenerator,
                    timeRanges: timeRanges,
                    stockService: stockService
                )
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 視圖模式選擇器
                    viewModeSelector
                    
                    // 時間區間選擇器
                    if selectedViewMode != "allocation" {
                        timeRangeSelector
                        
                        // 顯示自定義日期範圍
                        if isCustomRangeActive {
                            CustomDateRangeBadgeView(
                                startDate: startDate,
                                endDate: endDate,
                                onTap: {
                                    showCustomDatePicker = true
                                }
                            )
                            .padding(.top, 4)
                        }
                    }
                    
                    // 基於選擇的視圖模式顯示內容
                    selectedContentView
                }
                .padding(.top, 20)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("投資總覽")
                        .navigationTitleStyle()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showReportGenerator = true
                    }) {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showReportGenerator) {
                ReportGeneratorView(stocks: $stocks)
            }
        }
        .task {
            metricsService = CustomRangeMetricsService(stocks: stocks, stockService: stockService)
                // 初始時設置合適的時間範圍
                updateDateRangeForSelection(selectedTimeRange)
                await calculateInvestmentMetrics()
        }
        .onChange(of: selectedTimeRange) { _, newRange in
            if newRange == "自訂" {
                showCustomDatePicker = true
            } else {
                isCustomRangeActive = false
                // 根據選擇的時間範圍設置起始日期
                updateDateRangeForSelection(newRange)
                Task {
                    await calculateInvestmentMetrics()
                }
            }
        }
        .onChange(of: selectedViewMode) { _, newMode in
            Task {
                await loadSpecificMetricsForMode(newMode)
            }
        }
        .overlay {
            if isLoading {
                ProgressView("計算中...")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showCustomDatePicker) {
            CustomDateRangeView(
                startDate: $startDate,
                endDate: $endDate,
                isVisible: $showCustomDatePicker,
                onConfirm: {
                    isCustomRangeActive = true
                    showCustomDatePicker = false
                    // 重新計算指標
                    Task {
                        await calculateInvestmentMetricsForCustomRange()
                    }
                },
                onCancel: {
                    if !isCustomRangeActive {
                        selectedTimeRange = "1季" // 如果之前沒有啟用自定義，則回到預設值
                    }
                    showCustomDatePicker = false
                }
            )
        }
    }
    
    // MARK: - 子視圖
    
    // 視圖模式選擇器
    private var viewModeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                Button(action: { selectedViewMode = "overview" }) {
                    modeButton(icon: "chart.pie.fill", text: "概覽", isSelected: selectedViewMode == "overview")
                }
                
                Button(action: { selectedViewMode = "allocation" }) {
                    modeButton(icon: "chart.pie", text: "分配", isSelected: selectedViewMode == "allocation")
                }
                
                Button(action: { selectedViewMode = "monthly" }) {
                    modeButton(icon: "calendar", text: "月度", isSelected: selectedViewMode == "monthly")
                }
                
                Button(action: { selectedViewMode = "growth" }) {
                    modeButton(icon: "chart.line.uptrend.xyaxis", text: "成長", isSelected: selectedViewMode == "growth")
                }
                
                Button(action: { selectedViewMode = "risk" }) {
                    modeButton(icon: "exclamationmark.triangle", text: "風險", isSelected: selectedViewMode == "risk")
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var timeRangeSelector: some View {
        Picker("時間範圍", selection: $selectedTimeRange) {
            ForEach(timeRanges, id: \.self) { range in
                Text(range).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    // 添加更新日期範圍的方法
    private func updateDateRangeForSelection(_ selection: String) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selection {
        case "1季":
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            endDate = now
        case "1年":
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            endDate = now
        case "3年":
            startDate = calendar.date(byAdding: .year, value: -3, to: now) ?? now
            endDate = now
        case "5年":
            startDate = calendar.date(byAdding: .year, value: -5, to: now) ?? now
            endDate = now
        default:
            break
        }
    }

    // 添加自定義範圍計算方法
    private func calculateInvestmentMetricsForCustomRange() async {
        guard let service = metricsService else { return }
        
        isLoading = true
        
        // 使用服務計算指標
        let metrics = await service.calculateMetrics(startDate: startDate, endDate: endDate)
        
        await MainActor.run {
            self.investmentMetrics = metrics
            self.isLoading = false
        }
    }
    
    private func modeButton(icon: String, text: String, isSelected: Bool) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 18))
            Text(text)
                .font(.system(size: 12))
        }
        .frame(width: 60, height: 60)
        .foregroundColor(isSelected ? .white : .gray)
        .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - 數據方法
    
    // 計算基本投資指標
    private func calculateInvestmentMetrics() async {
        await calculateInvestmentMetricsForCustomRange()
    }
    
    // 根據選擇的視圖模式加載特定指標
    private func loadSpecificMetricsForMode(_ mode: String) async {
        // 如果數據已經加載，則不再重複加載
        switch mode {
        case "allocation":
            if investmentMetrics.assetAllocation.isEmpty {
                await calculateAssetAllocation()
            }
        case "monthly":
            if investmentMetrics.monthlyDividends.isEmpty {
                await calculateMonthlyDividends()
            }
        case "growth":
            if investmentMetrics.dividendGrowth.isEmpty {
                await calculateDividendGrowth()
            }
        case "risk":
            if investmentMetrics.riskMetrics.portfolioVolatility == 0 {
                await calculateRiskMetrics()
            }
        default:
            break
        }
    }
    
    // MARK: - 以下方法是原來的計算方法，保留核心邏輯供子視圖使用
    
    private func calculateTotalInvestment() -> Double {
        stocks.reduce(0) { total, stock in
            // 一般持股投資成本
            let normalCost = Double(stock.shares) * (stock.purchasePrice ?? 0)
            
            // 定期定額投資成本（已執行的交易）
            let regularCost = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { sum, transaction in
                    sum + transaction.amount
                } ?? 0
            
            return total + normalCost + regularCost
        }
    }
    
    private func calculateTotalAnnualDividend() -> Double {
        stocks.reduce(0) { total, stock in
            // 計算一般持股的年化股利
            let normalDividend = Double(stock.shares) * stock.dividendPerShare * Double(stock.frequency)
            
            // 計算定期定額的年化股利（已執行的交易）
            let regularShares = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { sum, transaction in
                    sum + transaction.shares
                } ?? 0
            let regularDividend = Double(regularShares) * stock.dividendPerShare * Double(stock.frequency)
            
            return total + normalDividend + regularDividend
        }
    }
    
    private func getTopPerformingStocks() -> [Stock] {
        // 將相同股票的一般持股和定期定額合併計算
        let combinedStocks = Dictionary(grouping: stocks, by: { $0.symbol })
            .map { (symbol, stocks) -> (String, Double) in
                let totalAnnualDividend = stocks.reduce(0) { sum, stock in
                    let normalDividend = Double(stock.shares) * stock.dividendPerShare * Double(stock.frequency)
                    
                    let regularShares = stock.regularInvestment?.transactions?
                        .filter { $0.isExecuted }
                        .reduce(0) { sum, transaction in
                            sum + transaction.shares
                        } ?? 0
                    let regularDividend = Double(regularShares) * stock.dividendPerShare * Double(stock.frequency)
                    
                    return sum + normalDividend + regularDividend
                }
                return (symbol, totalAnnualDividend)
            }
        
        // 排序並取得前面的股票
        let sortedSymbols = combinedStocks
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
        
        // 為了顯示，我們只需要每個股票的一個實例
        return sortedSymbols.compactMap { symbol in
            stocks.first { $0.symbol == symbol }
        }
    }
    
    private func calculateTrendData() async -> [DividendTrend] {
        let calendar = Calendar.current
        var trendData: [DividendTrend] = []
        
        // 根據選擇的時間範圍決定起始日期
        let now = Date()
        let yearsToShow: Int = {
            switch selectedTimeRange {
            case "1Y": return 1
            case "3Y": return 3
            case "5Y": return 5
            default: return 1
            }
        }()
        
        guard let startDate = calendar.date(byAdding: .year, value: -yearsToShow, to: now) else { return [] }
        var currentDate = startDate
        
        while currentDate <= now {
            // 篩選在該日期之前購買的股票
            let relevantStocks = stocks.filter { $0.purchaseDate <= currentDate }
            
            // 計算該日期的總市值（用於計算殖利率）
            var totalInvestment: Double = 0
            var totalAnnualDividend: Double = 0
            var normalDividend: Double = 0
            var regularDividend: Double = 0
            
            for stock in relevantStocks {
                // 一般持股部分
                let normalInvestment = Double(stock.shares) * (stock.purchasePrice ?? 0)
                let normalAnnual = Double(stock.shares) * stock.dividendPerShare * Double(stock.frequency)
                
                // 定期定額部分（過濾出該日期之前已執行的交易）
                let executedTransactions = stock.regularInvestment?.transactions?
                    .filter { $0.isExecuted && $0.date <= currentDate } ?? []
                
                let regularInvestment = executedTransactions.reduce(0.0) { $0 + $1.amount }
                let regularShares = executedTransactions.reduce(0) { $0 + $1.shares }
                let regularAnnual = Double(regularShares) * stock.dividendPerShare * Double(stock.frequency)
                
                // 累加
                totalInvestment += (normalInvestment + regularInvestment)
                totalAnnualDividend += (normalAnnual + regularAnnual)
                normalDividend += normalAnnual
                regularDividend += regularAnnual
            }
            
            // 計算殖利率
            let yield = totalInvestment > 0 ? (totalAnnualDividend / totalInvestment) * 100 : 0
            
            // 添加到趨勢數據
            trendData.append(DividendTrend(
                date: currentDate,
                annualDividend: totalAnnualDividend,
                yield: yield,
                normalDividend: normalDividend,
                regularDividend: regularDividend
            ))
            
            // 移到下一個月
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = nextMonth
            } else {
                break
            }
        }
        
        return trendData
    }
    
    private func getUpcomingDividends() async -> [UpcomingDividend] {
        var dividends: [UpcomingDividend] = []
        
        // 模擬未來 3 個月的除息日
        let calendar = Calendar.current
        let now = Date()
        
        // 過濾所有股票
        for stock in stocks {
            // 根據股利頻率決定下一個除息日
            let nextExDate: Date
            switch stock.frequency {
            case 1: // 年配
                // 預設在年中
                var components = calendar.dateComponents([.year], from: now)
                components.year = components.year! + (calendar.component(.month, from: now) >= 6 ? 1 : 0)
                components.month = 6
                components.day = 15
                nextExDate = calendar.date(from: components) ?? now
                
            case 2: // 半年配
                // 預設在 Q2 和 Q4
                var components = calendar.dateComponents([.year, .month], from: now)
                let currentMonth = components.month ?? 1
                if currentMonth < 6 {
                    components.month = 6
                } else if currentMonth < 12 {
                    components.month = 12
                } else {
                    components.year = (components.year ?? 0) + 1
                    components.month = 6
                }
                components.day = 15
                nextExDate = calendar.date(from: components) ?? now
                
            case 4: // 季配
                // 預設在每季末
                var components = calendar.dateComponents([.year, .month], from: now)
                let currentMonth = components.month ?? 1
                if currentMonth < 3 {
                    components.month = 3
                } else if currentMonth < 6 {
                    components.month = 6
                } else if currentMonth < 9 {
                    components.month = 9
                } else if currentMonth < 12 {
                    components.month = 12
                } else {
                    components.year = (components.year ?? 0) + 1
                    components.month = 3
                }
                components.day = 15
                nextExDate = calendar.date(from: components) ?? now
                
            case 12: // 月配
                // 預設在每月中旬
                var components = calendar.dateComponents([.year, .month], from: now)
                let currentDay = calendar.component(.day, from: now)
                if currentDay >= 15 {
                    if components.month == 12 {
                        components.year = (components.year ?? 0) + 1
                        components.month = 1
                    } else {
                        components.month = (components.month ?? 1) + 1
                    }
                }
                components.day = 15
                nextExDate = calendar.date(from: components) ?? now
                
            default:
                continue
            }
            
            // 檢查是否在未來 3 個月內
            if nextExDate > now, let threeMonthsLater = calendar.date(byAdding: .month, value: 3, to: now), nextExDate <= threeMonthsLater {
                dividends.append(UpcomingDividend(
                    symbol: stock.symbol,
                    name: stock.name,
                    exDividendDate: nextExDate,
                    dividendAmount: stock.dividendPerShare
                ))
            }
        }
        
        // 根據除息日期排序
        return dividends.sorted { $0.exDividendDate < $1.exDividendDate }
    }
    
    private func calculatePerformanceMetrics() async -> PerformanceMetrics {
        var metrics = PerformanceMetrics()
        
        // 獲取當前總市值
        let currentPrices = await getCurrentPrices()
        let totalMarketValue = stocks.reduce(0.0) { sum, stock in
            guard let currentPrice = currentPrices[stock.symbol] else { return sum }
            
            // 一般持股市值
            let normalValue = Double(stock.shares) * currentPrice
            
            // 定期定額市值
            let regularShares = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { $0 + $1.shares } ?? 0
            let regularValue = Double(regularShares) * currentPrice
            
            return sum + normalValue + regularValue
        }
        
        // 總投資成本
        let totalInvestment = calculateTotalInvestment()
        
        // 計算總報酬
        metrics.totalReturn = totalMarketValue - totalInvestment
        metrics.totalReturnPercentage = totalInvestment > 0 ? (metrics.totalReturn / totalInvestment) * 100 : 0
        
        // 時間加權報酬率（簡化版，實際應考慮每次投資的時間）
        metrics.timeWeightedReturn = metrics.totalReturnPercentage * 0.9 // 簡化計算
        
        // 平均持有期間（月）
        let calendar = Calendar.current
        let now = Date()
        let holdingPeriods = stocks.map { stock in
            let purchaseDate = stock.purchaseDate
            let components = calendar.dateComponents([.month], from: purchaseDate, to: now)
            return Double(components.month ?? 0)
        }
        metrics.averageHoldingPeriod = holdingPeriods.reduce(0.0, +) / Double(max(1, holdingPeriods.count))
        
        // 夏普比率（簡化版，實際需要更複雜的計算）
        // 假設無風險利率為2.0%
        let riskFreeRate = 2.0
        let excessReturn = metrics.totalReturnPercentage - riskFreeRate
        
        // 投資組合標準差（簡化為固定值）
        let portfolioStdDev = 10.0 // 實際應計算標準差
        
        metrics.sharpeRatio = portfolioStdDev > 0 ? excessReturn / portfolioStdDev : 0
        
        return metrics
    }
    
    // 計算資產分配
    private func calculateAssetAllocation() async {
        isLoading = true
        
        // 定義產業類別與顏色
        let industries = [
            "半導體": Color.blue,
            "金融": Color.green,
            "電子": Color.purple,
            "傳產": Color.orange,
            "生技醫療": Color.red,
            "通訊網路": Color.yellow,
            "其他": Color.gray
        ]
        
        // 為每個股票分配產業（簡化版，實際應使用股票的實際產業分類）
        let stockIndustries = [
            "2330": "半導體",
            "2317": "電子",
            "2454": "半導體",
            "2412": "通訊網路",
            "2308": "電子",
            "2881": "金融",
            "2882": "金融",
            "1301": "傳產",
            "1303": "傳產",
            "2891": "金融"
        ]
        
        // 獲取當前價格
        let currentPrices = await getCurrentPrices()
        
        // 計算各產業投資額
        var industryAmounts: [String: Double] = [:]
        var totalAmount: Double = 0
        
        for stock in stocks {
            guard let currentPrice = currentPrices[stock.symbol] else { continue }
            
            // 一般持股市值
            let normalValue = Double(stock.shares) * currentPrice
            
            // 定期定額市值
            let regularShares = stock.regularInvestment?.transactions?
                .filter { $0.isExecuted }
                .reduce(0) { $0 + $1.shares } ?? 0
            let regularValue = Double(regularShares) * currentPrice
            
            let totalValue = normalValue + regularValue
            
            // 獲取產業
            let industry = stockIndustries[stock.symbol] ?? "其他"
            
            // 累加該產業投資額
            industryAmounts[industry, default: 0] += totalValue
            totalAmount += totalValue
        }
        
        // 轉換為百分比並創建資產分配數據
        var assetAllocation: [AssetAllocation] = []
        
        for (industry, amount) in industryAmounts {
            let percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0
            
            assetAllocation.append(AssetAllocation(
                category: industry,
                amount: amount,
                percentage: percentage,
                color: industries[industry] ?? Color.gray
            ))
        }
        
        // 按百分比排序
        assetAllocation.sort { $0.percentage > $1.percentage }
        
        // 更新狀態
        await MainActor.run {
            investmentMetrics.assetAllocation = assetAllocation
            
            // 計算風險指標中的產業集中度
            if let topIndustryPercentage = assetAllocation.first?.percentage {
                investmentMetrics.riskMetrics.sectorConcentration = topIndustryPercentage
            }
            
            // 計算前五大持股佔比
            if assetAllocation.count >= 5 {
                let topFivePercentage = assetAllocation.prefix(5).reduce(0.0) { $0 + $1.percentage }
                investmentMetrics.riskMetrics.topHoldingsWeight = topFivePercentage
            } else {
                investmentMetrics.riskMetrics.topHoldingsWeight = assetAllocation.reduce(0.0) { $0 + $1.percentage }
            }
            
            isLoading = false
        }
    }
    
    // 計算月度股利
    private func calculateMonthlyDividends() async {
        isLoading = true
        
        let calendar = Calendar.current
        let now = Date()
        
        var monthlyDividends: [MonthlyDividend] = []
        
        // 生成未來12個月的日期
        for month in 0..<12 {
            guard let date = calendar.date(byAdding: .month, value: month, to: now) else { continue }
            
            // 初始化當月股利
            var normalDividend: Double = 0
            var regularDividend: Double = 0
            
            // 檢查每支股票在該月是否有股利
            for stock in stocks {
                // 根據股利頻率判斷是否在本月發放
                let shouldPayDividend = shouldPayDividendInMonth(for: stock, month: date)
                
                if shouldPayDividend {
                    // 一般持股股利
                    normalDividend += Double(stock.shares) * stock.dividendPerShare
                    
                    // 定期定額股利（已執行的交易）
                    let regularShares = stock.regularInvestment?.transactions?
                        .filter { $0.isExecuted }
                        .reduce(0) { $0 + $1.shares } ?? 0
                    regularDividend += Double(regularShares) * stock.dividendPerShare
                }
            }
            
            // 添加到月度股利數據
            monthlyDividends.append(MonthlyDividend(
                month: date,
                amount: normalDividend + regularDividend,
                normalDividend: normalDividend,
                regularDividend: regularDividend
            ))
        }
        
        await MainActor.run {
            investmentMetrics.monthlyDividends = monthlyDividends
            isLoading = false
        }
    }
    
    // 判斷特定股票在指定月份是否應該發放股利
    private func shouldPayDividendInMonth(for stock: Stock, month: Date) -> Bool {
        let calendar = Calendar.current
        let monthNumber = calendar.component(.month, from: month)
        
        switch stock.frequency {
        case 1: // 年配
            // 假設年配在6月發放
            return monthNumber == 6
        case 2: // 半年配
            // 假設半年配在6月和12月發放
            return monthNumber == 6 || monthNumber == 12
        case 4: // 季配
            // 假設季配在3,6,9,12月發放
            return monthNumber == 3 || monthNumber == 6 || monthNumber == 9 || monthNumber == 12
        case 12: // 月配
            // 每月都發放
            return true
        default:
            return false
        }
    }
    
    // 計算股息成長分析
    // 修改 InvestmentOverviewView.swift 中的 calculateDividendGrowth 方法

    private func calculateDividendGrowth() async {
        isLoading = true
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let startYear = currentYear - 5 // 分析過去5年
        
        var dividendGrowth: [DividendGrowth] = []
        
        // 初始化各年度的年度股利
        var yearlyDividends: [Int: Double] = [:]
        
        // 模擬歷史股利數據：
        // 逐年計算股利，假設每年投資組合有所變化
        for year in startYear...currentYear {
            // 為了模擬歷史數據，我們根據年份模擬一些股利變化
            // 實際應用中應該使用真實的歷史數據
            let yearFactor = Double(year - startYear) / 5.0 // 用於模擬增長
            
            // 基礎年度股利（根據當前年化股利估算）
            let baseDividend = calculateTotalAnnualDividend() * (0.7 + yearFactor * 0.3)
            
            // 添加一些隨機波動
            let randomFactor = 1.0 + Double.random(in: -0.05...0.05)
            yearlyDividends[year] = baseDividend * randomFactor
        }
        
        // 計算年度成長率，確保 startYear < currentYear
        if startYear < currentYear {
            for year in (startYear + 1)...currentYear {
                let currentYearDividend = yearlyDividends[year] ?? 0
                let previousYearDividend = yearlyDividends[year - 1] ?? 0
                
                var growthRate: Double
                if previousYearDividend > 0 {
                    growthRate = ((currentYearDividend / previousYearDividend) - 1) * 100
                } else {
                    growthRate = -100 // 表示無法計算
                }
                
                dividendGrowth.append(DividendGrowth(
                    year: year,
                    annualDividend: currentYearDividend,
                    growthRate: growthRate
                ))
            }
        } else {
            // 如果沒有足夠的年份範圍，至少添加當前年份的數據
            dividendGrowth.append(DividendGrowth(
                year: currentYear,
                annualDividend: yearlyDividends[currentYear] ?? 0,
                growthRate: 0 // 無法計算成長率
            ))
        }
        
        await MainActor.run {
            investmentMetrics.dividendGrowth = dividendGrowth
            isLoading = false
        }
    }
    
    // 計算風險指標
    private func calculateRiskMetrics() async {
        isLoading = true
        
        var riskMetrics = RiskMetrics()
        
        // 投資組合波動率（簡化為一個固定百分比，實際應計算標準差）
        riskMetrics.portfolioVolatility = Double.random(in: 10...20)
        
        // Beta值（簡化為一個固定值，實際應對比大盤計算）
        riskMetrics.betaValue = Double.random(in: 0.8...1.2)
        
        // 最大回撤（簡化為一個固定百分比，實際應計算歷史最大跌幅）
        riskMetrics.maxDrawdown = Double.random(in: 5...15)
        
        // 行業集中度（在計算資產分配時已更新）
        if riskMetrics.sectorConcentration == 0 {
            riskMetrics.sectorConcentration = Double.random(in: 20...40)
        }
        
        // 前五大持股比重（在計算資產分配時已更新）
        if riskMetrics.topHoldingsWeight == 0 {
            riskMetrics.topHoldingsWeight = Double.random(in: 30...60)
        }
        
        await MainActor.run {
            investmentMetrics.riskMetrics = riskMetrics
            isLoading = false
        }
    }
    
    // 獲取當前股價
    private func getCurrentPrices() async -> [String: Double] {
        var prices: [String: Double] = [:]
        
        // 獲取每支股票的最新價格
        for stock in stocks {
            if let price = await stockService.getStockPrice(symbol: stock.symbol, date: Date()) {
                prices[stock.symbol] = price
            }
        }
        
        return prices
    }
}

// MARK: - InvestmentMetrics 數據結構

// 投資指標結構
struct InvestmentMetrics {
    var totalInvestment: Double = 0
    var annualDividend: Double = 0
    var averageYield: Double = 0
    var stockCount: Int = 0
    var trendData: [DividendTrend] = []
    var topPerformingStocks: [Stock] = []
    var upcomingDividends: [UpcomingDividend] = []
    var assetAllocation: [AssetAllocation] = []
    var monthlyDividends: [MonthlyDividend] = []
    var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    var dividendGrowth: [DividendGrowth] = []
    var riskMetrics: RiskMetrics = RiskMetrics()
}

// 股利趨勢資料結構
struct DividendTrend: Identifiable {
    let id = UUID()
    let date: Date
    let annualDividend: Double
    let yield: Double
    let normalDividend: Double
    let regularDividend: Double
}

// 即將到來的股利資料結構
struct UpcomingDividend: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let exDividendDate: Date
    let dividendAmount: Double
}

// 資產分配結構
struct AssetAllocation: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
    let color: Color
}

// 月度股利收入結構
struct MonthlyDividend: Identifiable {
    let id = UUID()
    let month: Date
    let amount: Double
    let normalDividend: Double
    let regularDividend: Double
}

// 績效指標結構
struct PerformanceMetrics {
    var totalReturn: Double = 0
    var totalReturnPercentage: Double = 0
    var timeWeightedReturn: Double = 0
    var sharpeRatio: Double = 0
    var averageHoldingPeriod: Double = 0
}

// 股息成長分析結構
struct DividendGrowth: Identifiable {
    let id = UUID()
    let year: Int
    let annualDividend: Double
    let growthRate: Double
}

// 風險指標結構
struct RiskMetrics {
    var portfolioVolatility: Double = 0
    var betaValue: Double = 0
    var maxDrawdown: Double = 0
    var sectorConcentration: Double = 0
    var topHoldingsWeight: Double = 0
}

// MARK: - 擴展
extension Int {
    var formattedWithComma: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}
