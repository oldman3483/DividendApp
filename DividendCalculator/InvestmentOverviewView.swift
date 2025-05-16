//
//  InvestmentOverviewView.swift
//  DividendCalculator
//
//  Created on 2025/3/9.
//  Updated with modular structure and StockValueService integration
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
    @State private var currentPrices: [String: Double] = [:]

    private let timeRanges = ["1季", "1年", "3年", "5年", "自訂"]
    private let analysisTypes = ["amount", "yield"]
    private let viewModes = ["overview", "allocation", "monthly", "growth", "risk"]
    private let stockService = LocalStockService()
    private let stockValueService = StockValueService.shared
    
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
                        Image(systemName: "square.and.arrow.up")
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
    
    // 計算基本投資指標 - 使用 StockValueService
    private func calculateInvestmentMetrics() async {
        isLoading = true
        
        // 篩選在自定義範圍內購買的股票
        let relevantStocks = stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
        
        // 獲取當前價格數據
        currentPrices = await stockValueService.getCurrentPrices(for: stocks)
        
        // 計算總投資成本
        investmentMetrics.totalInvestment = stockValueService.calculateTotalInvestment(for: relevantStocks, before: endDate)
        
        // 計算年化股利
        investmentMetrics.annualDividend = stockValueService.calculateAnnualDividend(for: relevantStocks, before: endDate)
        
        // 計算平均殖利率
        investmentMetrics.averageYield = investmentMetrics.totalInvestment > 0 ?
            (investmentMetrics.annualDividend / investmentMetrics.totalInvestment) * 100 : 0
        
        // 計算持股數量（不同的股票代號）
        investmentMetrics.stockCount = Set(relevantStocks.map { $0.symbol }).count
        
        // 計算趨勢數據
        investmentMetrics.trendData = await calculateTrendData()
        
        // 獲取頂級股票
        investmentMetrics.topPerformingStocks = getTopPerformingStocks()
        
        // 獲取即將到來的股利資訊
        investmentMetrics.upcomingDividends = await getUpcomingDividends()
        
        // 計算績效指標
        await calculatePerformanceMetrics()
        
        // 計算資產分配
        await calculateAssetAllocation()
        
        // 計算月度股利
        await calculateMonthlyDividends()
        
        // 計算股息成長
        await calculateDividendGrowth()
        
        // 計算風險指標
        await calculateRiskMetrics()
        
        isLoading = false
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
    
    // 計算趨勢數據 - 使用 StockValueService
    private func calculateTrendData() async -> [DividendTrend] {
        let calendar = Calendar.current
        var trendData: [DividendTrend] = []
        
        // 計算日期間隔（以月為單位）
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        let monthsBetween = max(1, components.month ?? 1)
        
        // 確定合適的時間間隔
        let interval = monthsBetween <= 3 ? 1 :
                      monthsBetween <= 12 ? 2 :
                      monthsBetween <= 36 ? 6 : 12
        
        var currentDate = startDate
        
        while currentDate <= endDate {
            // 篩選在該日期之前購買的股票
            let relevantStocks = stocks.filter { $0.purchaseDate <= currentDate }
            
            // 計算該日期的總投資成本
            let totalInvestment = stockValueService.calculateTotalInvestment(for: relevantStocks, before: currentDate)
            
            // 計算該日期的年化股利
            let annualDividend = stockValueService.calculateAnnualDividend(for: relevantStocks, before: currentDate)
            
            // 獲取該日期的當前價格
            let prices = await stockValueService.getCurrentPrices(for: relevantStocks, on: currentDate)
            
            // 計算一般持股和定期定額的股利
            let normalStocks = relevantStocks.filter { $0.regularInvestment == nil }
            let regularStocks = relevantStocks.filter { $0.regularInvestment != nil }
            
            let normalDividend = stockValueService.calculateAnnualDividend(for: normalStocks, before: currentDate)
            let regularDividend = stockValueService.calculateAnnualDividend(for: regularStocks, before: currentDate)
            
            // 計算殖利率
            let yield = totalInvestment > 0 ? (annualDividend / totalInvestment) * 100 : 0
            
            // 添加到趨勢數據
            trendData.append(DividendTrend(
                date: currentDate,
                annualDividend: annualDividend,
                yield: yield,
                normalDividend: normalDividend,
                regularDividend: regularDividend
            ))
            
            // 根據計算的間隔移至下一個日期點
            if let nextDate = calendar.date(byAdding: .month, value: interval, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return trendData
    }
    
    // 獲取頂級股票 - 使用 StockValueService
    private func getTopPerformingStocks() -> [Stock] {
        // 篩選在時間範圍內的股票
        let relevantStocks = stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
        
        // 將相同股票的一般持股和定期定額合併計算
        let combinedStocks = Dictionary(grouping: relevantStocks, by: { $0.symbol })
            .map { (symbol, stocks) -> (String, Double) in
                let totalAnnualDividend = stockValueService.calculateAnnualDividend(for: stocks, before: endDate)
                return (symbol, totalAnnualDividend)
            }
        
        // 排序並取得前面的股票
        let sortedSymbols = combinedStocks
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
        
        // 為了顯示，我們只需要每個股票的一個實例
        return sortedSymbols.compactMap { symbol in
            relevantStocks.first { $0.symbol == symbol }
        }
    }
    
    // 獲取即將到來的股利資訊
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
    
    // 計算績效指標 - 使用 StockValueService
    private func calculatePerformanceMetrics() async {
        // 篩選在時間範圍內購買的股票
        let relevantStocks = stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
        
        // 使用 StockValueService 計算總市值
        let totalValue = await stockValueService.calculateTotalValue(
            for: relevantStocks,
            currentPrices: currentPrices,
            date: endDate
        )
        
        // 計算總投資成本
        let totalInvestment = stockValueService.calculateTotalInvestment(for: relevantStocks, before: endDate)
        
        // 計算總報酬
        investmentMetrics.performanceMetrics.totalReturn = totalValue - totalInvestment
        investmentMetrics.performanceMetrics.totalReturnPercentage = totalInvestment > 0 ?
            (investmentMetrics.performanceMetrics.totalReturn / totalInvestment) * 100 : 0
        
        // 時間加權報酬率
        investmentMetrics.performanceMetrics.timeWeightedReturn = await calculateTimeWeightedReturn(relevantStocks: relevantStocks)
        
        // 平均持有期間（月）
        let calendar = Calendar.current
        let now = Date()
        let holdingPeriods = relevantStocks.map { stock in
            let purchaseDate = max(stock.purchaseDate, startDate)
            let endingDate = min(now, endDate)
            let components = calendar.dateComponents([.month], from: purchaseDate, to: endingDate)
            return Double(components.month ?? 0)
        }
        
        investmentMetrics.performanceMetrics.averageHoldingPeriod = holdingPeriods.isEmpty ? 0 :
            holdingPeriods.reduce(0.0, +) / Double(holdingPeriods.count)
        
        // 計算夏普比率
        investmentMetrics.performanceMetrics.sharpeRatio = calculateSharpeRatio(
            relevantStocks: relevantStocks,
            totalReturnPercentage: investmentMetrics.performanceMetrics.totalReturnPercentage
        )
    }
    
    // 時間加權報酬率 - 使用 StockValueService
    private func calculateTimeWeightedReturn(relevantStocks: [Stock]) async -> Double {
        // 獲取當前價格
        let prices = await stockValueService.getCurrentPrices(for: relevantStocks, on: endDate)
        
        // 簡化版實現
        let totalReturn = relevantStocks.reduce(0.0) { total, stock in
            guard let currentPrice = prices[stock.symbol],
                  let purchasePrice = stock.purchasePrice else { return total }
            
            // 一般持股報酬
            let normalReturn = (currentPrice - purchasePrice) / purchasePrice
            
            // 實際應考慮持有時間權重
            let weightedNormalReturn = normalReturn * 0.9 // 簡化時間加權
            
            return total + weightedNormalReturn
        }
        
        return totalReturn / Double(max(1, relevantStocks.count)) * 100
    }
    
    // 計算資產分配 - 使用 StockValueService
    private func calculateAssetAllocation() async {
        // 篩選在時間範圍內購買的股票
        let relevantStocks = stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
        
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
        
        // 為每個股票分配產業
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
            "2891": "金融",
            "0050": "其他"
        ]
        
        // 獲取當前價格
        let currentPrices = await stockValueService.getCurrentPrices(for: relevantStocks, on: endDate)
        
        // 計算各產業投資額
        var industryAmounts: [String: Double] = [:]
        var totalAmount: Double = 0
        
        for stock in relevantStocks {
            guard let currentPrice = currentPrices[stock.symbol] else { continue }
            
            // 使用 StockValueService 計算股票市值
            let stockValue = await stockValueService.calculateTotalValue(
                for: [stock],
                currentPrices: [stock.symbol: currentPrice],
                date: endDate
            )
            
            // 獲取產業
            let industry = stockIndustries[stock.symbol] ?? "其他"
            
            // 累加該產業投資額
            industryAmounts[industry, default: 0] += stockValue
            totalAmount += stockValue
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
        
        // 更新指標
        investmentMetrics.assetAllocation = assetAllocation
        
        // 更新風險指標中的產業集中度
        if let topIndustryPercentage = assetAllocation.first?.percentage {
            investmentMetrics.riskMetrics.sectorConcentration = topIndustryPercentage
        }
        
        // 更新前五大持股比重
        if assetAllocation.count >= 5 {
            let topFivePercentage = assetAllocation.prefix(5).reduce(0.0) { $0 + $1.percentage }
            investmentMetrics.riskMetrics.topHoldingsWeight = topFivePercentage
        } else {
            investmentMetrics.riskMetrics.topHoldingsWeight = assetAllocation.reduce(0.0) { $0 + $1.percentage }
        }
    }
    
    // 計算月度股利
    private func calculateMonthlyDividends() async {
        let calendar = Calendar.current
        let now = Date()
        
        var monthlyDividends: [MonthlyDividend] = []
        
        // 生成未來12個月的日期
        for month in 0..<12 {
            guard let date = calendar.date(byAdding: .month, value: month, to: now) else { continue }
            
            // 初始化當月股利
            var normalDividend: Double = 0
            var regularDividend: Double = 0
            
            // 篩選在該日期前購買的股票
            let relevantStocks = stocks.filter { $0.purchaseDate <= date }
            
            // 檢查每支股票在該月是否有股利
            for stock in relevantStocks {
                // 根據股利頻率判斷是否在本月發放
                let shouldPayDividend = shouldPayDividendInMonth(for: stock, month: date)
                
                if shouldPayDividend {
                    // 使用 StockValueService 計算股利
                    if stock.regularInvestment == nil {
                        // 一般持股股利
                        normalDividend += stockValueService.calculateAnnualDividend(for: [stock], before: date) / Double(stock.frequency)
                    } else {
                        // 定期定額股利
                        regularDividend += stockValueService.calculateAnnualDividend(for: [stock], before: date) / Double(stock.frequency)
                    }
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
        
        investmentMetrics.monthlyDividends = monthlyDividends
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
                
                // 計算股息成長分析 - 使用 StockValueService
                private func calculateDividendGrowth() async {
                    let calendar = Calendar.current
                    let currentYear = calendar.component(.year, from: Date())
                    let startYear = currentYear - 5 // 分析過去5年
                    
                    var dividendGrowth: [DividendGrowth] = []
                    
                    // 初始化各年度的年度股利
                    var yearlyDividends: [Int: Double] = [:]
                    
                    // 模擬歷史股利數據
                    for year in startYear...currentYear {
                        // 為了模擬歷史數據，我們根據年份模擬一些股利變化
                        let yearFactor = Double(year - startYear) / 5.0 // 用於模擬增長
                        
                        // 基礎年度股利（根據當前年化股利估算）
                        let baseDividend = stockValueService.calculateAnnualDividend(for: stocks) * (0.7 + yearFactor * 0.3)
                        
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
                    
                    investmentMetrics.dividendGrowth = dividendGrowth
                }
                
                // 計算風險指標 - 使用 StockValueService
                private func calculateRiskMetrics() async {
                    // 篩選在時間範圍內購買的股票
                    let relevantStocks = stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
                    
                    // 投資組合波動率（基於股票組合特性）
                    investmentMetrics.riskMetrics.portfolioVolatility = calculatePortfolioVolatility(stocks: relevantStocks)
                    
                    // Beta值（考慮股票行業和特性）
                    investmentMetrics.riskMetrics.betaValue = calculatePortfolioBeta(stocks: relevantStocks)
                    
                    // 最大回撤（模擬計算）
                    investmentMetrics.riskMetrics.maxDrawdown = calculateMaxDrawdown(
                        stocks: relevantStocks,
                        startDate: startDate,
                        endDate: endDate
                    )
                }
                
                // 計算投資組合波動率
                private func calculatePortfolioVolatility(stocks: [Stock]) -> Double {
                    // 簡化版：根據股票數量和類型估算波動率
                    let baseVolatility = 10.0 // 基礎波動率
                    let stockTypeFactor = stocks.count > 10 ? 0.8 : 1.2 // 股票種類多，波動率往往較低
                    
                    // 檢查是否有高波動性行業的股票
                    let highVolatilityIndustries = ["半導體", "生技醫療", "網路科技"]
                    let hasHighVolatilityStocks = stocks.contains { stock in
                        let industry = getStockIndustry(symbol: stock.symbol)
                        return highVolatilityIndustries.contains(industry)
                    }
                    
                    let industryFactor = hasHighVolatilityStocks ? 1.2 : 0.9
                    
                    return baseVolatility * stockTypeFactor * industryFactor
                }
                
                // 計算投資組合 Beta
                private func calculatePortfolioBeta(stocks: [Stock]) -> Double {
                    // 定義一些常見股票的 Beta 參考值（相對於加權指數）
                    let stockBetas: [String: Double] = [
                        "2330": 1.1,  // 台積電，相對波動較大
                        "2317": 1.2,  // 鴻海
                        "2881": 0.9,  // 富邦金
                        "2882": 0.85, // 國泰金
                        "1301": 0.8,  // 台塑
                        "2412": 0.7,  // 中華電，較為穩定
                        "0050": 1.0   // 台灣50指數ETF
                    ]
                    
                    // 使用 StockValueService 獲取投資組合的加權平均 Beta
                    var totalValue = 0.0
                    var weightedBeta = 0.0
                    
                    // 計算每支股票的總市值和加權 Beta
                    for stock in stocks {
                        let beta = stockBetas[stock.symbol] ?? 1.0 // 預設值
                        
                        // 使用購買價格估算市值
                        let value = Double(stock.totalShares) * (stock.purchasePrice ?? 100.0)
                        
                        totalValue += value
                        weightedBeta += beta * value
                    }
                    
                    return totalValue > 0 ? weightedBeta / totalValue : 1.0
                }
                
                // 計算最大回撤
                private func calculateMaxDrawdown(stocks: [Stock], startDate: Date, endDate: Date) -> Double {
                    // 簡化版計算
                    let baseMDD = 15.0 // 基礎回撤率
                    
                    // 考慮投資組合特性
                    let stockCount = Set(stocks.map { $0.symbol }).count
                    let diversificationFactor = stockCount > 10 ? 0.7 : (stockCount > 5 ? 0.85 : 1.0)
                    
                    // 考慮時間範圍
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.month], from: startDate, to: endDate)
                    let monthsBetween = max(1, components.month ?? 1)
                    let timeFactor = monthsBetween > 36 ? 1.2 : (monthsBetween > 12 ? 1.0 : 0.8)
                    
                    return baseMDD * diversificationFactor * timeFactor
                }
                
                // 模擬獲取股票所屬行業
                private func getStockIndustry(symbol: String) -> String {
                    // 實際應用中應從真實資料獲取
                    let industries = [
                        "2330": "半導體",
                        "2317": "電子",
                        "2454": "半導體",
                        "2412": "通訊網路",
                        "2308": "電子",
                        "2881": "金融",
                        "2882": "金融",
                        "1301": "傳產",
                        "1303": "傳產",
                        "2891": "金融",
                        "0050": "其他"
                    ]
                    
                    return industries[symbol] ?? "其他"
                }
                
                // 計算夏普比率
                private func calculateSharpeRatio(relevantStocks: [Stock], totalReturnPercentage: Double) -> Double {
                    // 假設無風險利率為2.0%
                    let riskFreeRate = 2.0
                    let excessReturn = totalReturnPercentage - riskFreeRate
                    
                    // 投資組合波動率（在實際應用中應計算標準差）
                    let volatility = calculatePortfolioVolatility(stocks: relevantStocks)
                    
                    return volatility > 0 ? excessReturn / volatility : 0
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
