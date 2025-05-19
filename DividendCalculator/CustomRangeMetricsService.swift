//
//  CustomRangeMetricsService.swift
//  DividendCalculator
//
//  Created on 2025/3/9.
//

import SwiftUI

// 處理自定義日期範圍的投資指標計算服務
class CustomRangeMetricsService {
    private let stocks: [Stock]
    private let stockService: LocalStockService
    
    init(stocks: [Stock], stockService: LocalStockService = LocalStockService()) {
        self.stocks = stocks
        self.stockService = stockService
    }
    
    // 計算自定義日期範圍的投資指標
    func calculateMetrics(startDate: Date, endDate: Date) async -> InvestmentMetrics {
        var metrics = InvestmentMetrics()
        let portfolioManager = PortfolioManager.shared
        
        // 篩選相關股票
        let relevantStocks = calculateFilteredStocks(startDate: startDate, endDate: endDate)

        
        // 1. 計算總投資成本（篩選在自定義範圍內購買的股票）
        metrics.totalInvestment = portfolioManager.calculateTotalInvestment(for: relevantStocks)

        // 2. 計算年化股利
        metrics.annualDividend = portfolioManager.calculateAnnualDividend(for: relevantStocks)

        // 3. 計算平均殖利率
        metrics.averageYield = metrics.totalInvestment > 0 ? (metrics.annualDividend / metrics.totalInvestment) * 100 : 0
        
        // 4. 計算持股數量
        metrics.stockCount = calculateStockCount(startDate: startDate, endDate: endDate)
        
        // 5. 計算趨勢數據
        metrics.trendData = await calculateTrendData(startDate: startDate, endDate: endDate)
        // 6. 獲取績效排行
        metrics.topPerformingStocks = getTopPerformingStocks(startDate: startDate, endDate: endDate)
        
        // 7. 獲取即將到來的股利資訊
        metrics.upcomingDividends = await getUpcomingDividends(endDate: endDate)
        
        // 8. 計算績效指標
        metrics.performanceMetrics = await calculatePerformanceMetrics(startDate: startDate, endDate: endDate)
        
        // 9. 計算資產分配
        metrics.assetAllocation = await calculateAssetAllocation(startDate: startDate, endDate: endDate)
        
        // 10. 計算月度股利
        metrics.monthlyDividends = await calculateMonthlyDividends(startDate: startDate, endDate: endDate)
        
        // 11. 計算股息成長
        metrics.dividendGrowth = await calculateDividendGrowth(startDate: startDate, endDate: endDate)
        
        // 12. 計算風險指標
        metrics.riskMetrics = await calculateRiskMetrics(startDate: startDate, endDate: endDate)
        
        return metrics
    }
    
    // MARK: - 主要指標計算方法
    
    // 添加通用的計算函數
    private func calculateFilteredStocks(startDate: Date, endDate: Date) -> [Stock] {
        return stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
    }

    private func calculateExecutedTransactions(stock: Stock, startDate: Date, endDate: Date) -> [RegularInvestmentTransaction] {
        return stock.regularInvestment?.transactions?
            .filter { $0.isExecuted && $0.date >= startDate && $0.date <= endDate } ?? []
    }
    
    // 計算總投資成本
    private func calculateTotalInvestment(startDate: Date, endDate: Date) -> Double {
        let relevantStocks = calculateFilteredStocks(startDate: startDate, endDate: endDate)
        return PortfolioManager.shared.calculateTotalInvestment(for: relevantStocks)
    }
    
    // 計算年化股利
    private func calculateAnnualDividend(startDate: Date, endDate: Date) -> Double {
        let relevantStocks = stocks.filter { $0.purchaseDate <= endDate } // 只考慮到結束日期前購買的股票
        return PortfolioManager.shared.calculateAnnualDividend(for: relevantStocks)
    }
    
    // 計算持股數量（不同的股票代號）
    private func calculateStockCount(startDate: Date, endDate: Date) -> Int {
        let stocksInRange = stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
        return Set(stocksInRange.map { $0.symbol }).count
    }
    
    // MARK: - 詳細指標計算方法
    
    // 計算趨勢數據
    private func calculateTrendData(startDate: Date, endDate: Date) async -> [DividendTrend] {
        let calendar = Calendar.current
        var trendData: [DividendTrend] = []
        
        // 計算日期間隔（以月為單位）
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        let monthsBetween = max(1, components.month ?? 1)
        
        // 如果日期範圍過短，使用更小的間隔
        let interval = monthsBetween <= 3 ? 1 :
        monthsBetween <= 12 ? 2 :
        monthsBetween <= 36 ? 6 : 12
        
        var currentDate = startDate
        
        while currentDate <= endDate {
            // 篩選在該日期之前購買的股票
            let relevantStocks = stocks.filter { $0.purchaseDate <= currentDate }
            
            // 計算該日期的總市值和股利相關指標
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
            
            // 根據計算的間隔移至下一個日期點
            if let nextDate = calendar.date(byAdding: .month, value: interval, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return trendData
    }
    
    // 獲取頂級股票
    private func getTopPerformingStocks(startDate: Date, endDate: Date) -> [Stock] {
        // 篩選時間範圍內的股票
        let stocksInRange = stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
        
        // 將相同股票的一般持股和定期定額合併計算
        let combinedStocks = Dictionary(grouping: stocksInRange, by: { $0.symbol })
            .map { (symbol, stocks) -> (String, Double) in
                let totalAnnualDividend = stocks.reduce(0) { sum, stock in
                    let normalDividend = Double(stock.shares) * stock.dividendPerShare * Double(stock.frequency)
                    
                    let regularShares = stock.regularInvestment?.transactions?
                        .filter {
                            $0.isExecuted &&
                            $0.date >= startDate &&
                            $0.date <= endDate
                        }
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
            stocksInRange.first { $0.symbol == symbol }
        }
    }
    
    // 獲取即將到來的股利資訊
    private func getUpcomingDividends(endDate: Date) async -> [UpcomingDividend] {
        var dividends: [UpcomingDividend] = []
        
        // 模擬未來 3 個月的除息日
        let calendar = Calendar.current
        
        // 過濾所有股票
        for stock in stocks.filter({ $0.purchaseDate <= endDate }) {
            // 根據股利頻率決定下一個除息日
            let nextExDate: Date
            switch stock.frequency {
            case 1: // 年配
                // 預設在年中
                var components = calendar.dateComponents([.year], from: endDate)
                components.year = components.year! + (calendar.component(.month, from: endDate) >= 6 ? 1 : 0)
                components.month = 6
                components.day = 15
                nextExDate = calendar.date(from: components) ?? endDate
                
            case 2: // 半年配
                // 預設在 Q2 和 Q4
                var components = calendar.dateComponents([.year, .month], from: endDate)
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
                nextExDate = calendar.date(from: components) ?? endDate
                
            case 4: // 季配
                // 預設在每季末
                var components = calendar.dateComponents([.year, .month], from: endDate)
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
                nextExDate = calendar.date(from: components) ?? endDate
                
            case 12: // 月配
                // 預設在每月中旬
                var components = calendar.dateComponents([.year, .month], from: endDate)
                let currentDay = calendar.component(.day, from: endDate)
                if currentDay >= 15 {
                    if components.month == 12 {
                        components.year = (components.year ?? 0) + 1
                        components.month = 1
                    } else {
                        components.month = (components.month ?? 1) + 1
                    }
                }
                components.day = 15
                nextExDate = calendar.date(from: components) ?? endDate
                
            default:
                continue
            }
            
            // 檢查是否在未來 3 個月內
            if let threeMonthsLater = calendar.date(byAdding: .month, value: 3, to: endDate), nextExDate <= threeMonthsLater {
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
    
    // 計算績效指標
    private func calculatePerformanceMetrics(startDate: Date, endDate: Date) async -> PerformanceMetrics {
        var metrics = PerformanceMetrics()
        
        // 獲取當前總市值
        let currentPrices = await getCurrentPrices()
        
        // 篩選時間範圍內的股票
        let stocksInRange = stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
        
        let totalMarketValue = stocksInRange.reduce(0.0) { sum, stock in
            guard let currentPrice = currentPrices[stock.symbol] else { return sum }
            
            // 一般持股市值
            let normalValue = Double(stock.shares) * currentPrice
            
            // 定期定額市值
            let regularShares = stock.regularInvestment?.transactions?
                .filter {
                    $0.isExecuted &&
                    $0.date >= startDate &&
                    $0.date <= endDate
                }
                .reduce(0) { $0 + $1.shares } ?? 0
            let regularValue = Double(regularShares) * currentPrice
            
            return sum + normalValue + regularValue
        }
        
        // 計算總投資成本
        let totalInvestment = stocksInRange.reduce(0) { total, stock in
            // 一般持股投資成本
            let normalCost = Double(stock.shares) * (stock.purchasePrice ?? 0)
            
            // 定期定額投資成本
            let regularCost = stock.regularInvestment?.transactions?
                .filter {
                    $0.isExecuted &&
                    $0.date >= startDate &&
                    $0.date <= endDate
                }
                .reduce(0) { sum, transaction in
                    sum + transaction.amount
                } ?? 0
            
            return total + normalCost + regularCost
        }
        
        // 計算總報酬
        metrics.totalReturn = totalMarketValue - totalInvestment
        metrics.totalReturnPercentage = totalInvestment > 0 ? (metrics.totalReturn / totalInvestment) * 100 : 0
        
        // 時間加權報酬率（考慮投資時間長短）
        metrics.timeWeightedReturn = calculateTimeWeightedReturn(stocksInRange: stocksInRange, currentPrices: currentPrices)
        
        // 平均持有期間（月）
        let calendar = Calendar.current
        let now = Date()
        let holdingPeriods = stocksInRange.map { stock in
            let purchaseDate = max(stock.purchaseDate, startDate)
            let endingDate = min(now, endDate)
            let components = calendar.dateComponents([.month], from: purchaseDate, to: endingDate)
            return Double(components.month ?? 0)
        }
        metrics.averageHoldingPeriod = holdingPeriods.reduce(0.0, +) / Double(max(1, holdingPeriods.count))
        
        // 計算夏普比率
        metrics.sharpeRatio = calculateSharpeRatio(stocksInRange: stocksInRange, totalReturnPercentage: metrics.totalReturnPercentage)
        
        return metrics
    }
    
    // 計算資產分配
    private func calculateAssetAllocation(startDate: Date, endDate: Date) async -> [AssetAllocation] {
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
            "2891": "金融"
        ]
        
        // 獲取當前價格
        let currentPrices = await getCurrentPrices()
        
        // 篩選時間範圍內的股票
        let stocksInRange = stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
        
        // 計算各產業投資額
        var industryAmounts: [String: Double] = [:]
        var totalAmount: Double = 0
        
        for stock in stocksInRange {
            guard let currentPrice = currentPrices[stock.symbol] else { continue }
            
            // 一般持股市值
            let normalValue = Double(stock.shares) * currentPrice
            
            // 定期定額市值
            let regularShares = stock.regularInvestment?.transactions?
                .filter {
                    $0.isExecuted &&
                    $0.date >= startDate &&
                    $0.date <= endDate
                }
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
        
        return assetAllocation
    }
    
    // 計算月度股利
    private func calculateMonthlyDividends(startDate: Date, endDate: Date) async -> [MonthlyDividend] {
        let calendar = Calendar.current
        
        // 生成自定義範圍內的月份
        var monthlyDividends: [MonthlyDividend] = []
        
        // 計算日期間隔（以月為單位）
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        let monthsBetween = max(1, components.month ?? 1)
        
        // 篩選範圍內的股票
        let stocksInRange = stocks.filter { $0.purchaseDate <= endDate }
        
        // 為範圍內每個月計算股利
        var currentDate = startDate
        for _ in 0..<monthsBetween {
            guard let monthEnd = getEndOfMonth(for: currentDate) else { continue }
            
            // 初始化當月股利
            var normalDividend: Double = 0
            var regularDividend: Double = 0
            
            // 檢查每支股票在該月是否有股利
            for stock in stocksInRange {
                // 根據股利頻率判斷是否在本月發放
                let shouldPayDividend = shouldPayDividendInMonth(for: stock, month: currentDate)
                
                if shouldPayDividend {
                    // 計算一般持股股利（從範圍起始到當前月的持股）
                    if stock.purchaseDate <= monthEnd {
                        normalDividend += Double(stock.shares) * stock.dividendPerShare
                    }
                    
                    // 計算定期定額股利（已執行的交易且在範圍內）
                    let regularShares = stock.regularInvestment?.transactions?
                        .filter {
                            $0.isExecuted &&
                            $0.date <= monthEnd &&
                            $0.date >= startDate
                        }
                        .reduce(0) { $0 + $1.shares } ?? 0
                    regularDividend += Double(regularShares) * stock.dividendPerShare
                }
            }
            
            // 添加到月度股利數據
            monthlyDividends.append(MonthlyDividend(
                month: currentDate,
                amount: normalDividend + regularDividend,
                normalDividend: normalDividend,
                regularDividend: regularDividend
            ))
            
            // 移至下一個月
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = nextMonth
            } else {
                break
            }
        }
        
        return monthlyDividends
    }
    
    // 計算股息成長分析
    // 修改 CustomRangeMetricsService.swift 中的 calculateDividendGrowth 方法
    private func calculateDividendGrowth(startDate: Date, endDate: Date) async -> [DividendGrowth] {
        let calendar = Calendar.current
        
        // 獲取自定義範圍的年份
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        
        var dividendGrowth: [DividendGrowth] = []
        
        // 初始化各年度的年度股利
        var yearlyDividends: [Int: Double] = [:]
        
        // 篩選範圍內的股票
        let stocksInRange = stocks.filter { $0.purchaseDate <= endDate }
        
        // 處理每一年 - 確保 startYear 不大於 endYear
        for year in startYear...max(startYear, endYear) {
            // 獲取該年年底
            var yearEndComponents = DateComponents()
            yearEndComponents.year = year
            yearEndComponents.month = 12
            yearEndComponents.day = 31
            guard let yearEnd = calendar.date(from: yearEndComponents) else { continue }
            
            // 篩選該年底前購買的股票
            let stocksInYearEnd = stocksInRange.filter { $0.purchaseDate <= yearEnd }
            
            // 計算該年度的股利
            let yearlyDividend = stocksInYearEnd.reduce(0.0) { sum, stock in
                // 一般持股年度股利
                let normalDividend = Double(stock.shares) * stock.dividendPerShare * Double(stock.frequency)
                
                // 定期定額年度股利
                let regularShares = stock.regularInvestment?.transactions?
                    .filter {
                        $0.isExecuted &&
                        $0.date <= yearEnd
                    }
                    .reduce(0) { $0 + $1.shares } ?? 0
                let regularDividend = Double(regularShares) * stock.dividendPerShare * Double(stock.frequency)
                
                return sum + normalDividend + regularDividend
            }
            
            yearlyDividends[year] = yearlyDividend
        }
        
        // 計算年度成長率 - 保護範圍不為空
        if startYear < endYear {
            for year in (startYear + 1)...endYear {
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
        } else if !yearlyDividends.isEmpty {
            // 如果開始年份等於或大於結束年份，至少添加一筆記錄
            let year = startYear
            dividendGrowth.append(DividendGrowth(
                year: year,
                annualDividend: yearlyDividends[year] ?? 0,
                growthRate: 0 // 無法計算成長率
            ))
        }
        
        return dividendGrowth
    }
    
    // 計算風險指標
    private func calculateRiskMetrics(startDate: Date, endDate: Date) async -> RiskMetrics {
        var riskMetrics = RiskMetrics()
        
        // 篩選範圍內的股票
        let stocksInRange = stocks.filter { $0.purchaseDate >= startDate && $0.purchaseDate <= endDate }
        
        // 投資組合波動率（基於股票組合特性）
        riskMetrics.portfolioVolatility = calculatePortfolioVolatility(stocks: stocksInRange)
        
        // Beta值（考慮股票行業和特性）
        riskMetrics.betaValue = calculatePortfolioBeta(stocks: stocksInRange)
        
        // 最大回撤（模擬計算）
        riskMetrics.maxDrawdown = calculateMaxDrawdown(stocks: stocksInRange, startDate: startDate, endDate: endDate)
        
        // 行業集中度
        let assetAllocation = await calculateAssetAllocation(startDate: startDate, endDate: endDate)
        if let topIndustryPercentage = assetAllocation.first?.percentage {
            riskMetrics.sectorConcentration = topIndustryPercentage
        } else {
            riskMetrics.sectorConcentration = 0
        }
        
        // 前五大持股比重
        if assetAllocation.count >= 5 {
            let topFivePercentage = assetAllocation.prefix(5).reduce(0.0) { $0 + $1.percentage }
            riskMetrics.topHoldingsWeight = topFivePercentage
        } else {
            riskMetrics.topHoldingsWeight = assetAllocation.reduce(0.0) { $0 + $1.percentage }
        }
        
        return riskMetrics
    }
    
    // 計算投資組合波動率
    private func calculatePortfolioVolatility(stocks: [Stock]) -> Double {
        // 在實際應用中，這裡應計算歷史價格的標準差
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
        // 實際應用中應考慮股票相對於市場的波動
        // 這裡使用簡化版計算
        
        // 定義一些常見股票的 Beta 參考值（相對於加權指數）
        let stockBetas: [String: Double] = [
            "2330": 1.1,  // 台積電，相對波動較大
            "2317": 1.2,  // 鴻海
            "2881": 0.9,  // 富邦金
            "2882": 0.85, // 國泰金
            "1301": 0.8,  // 台塑
            "2412": 0.7   // 中華電，較為穩定
        ]
        
        // 獲取投資組合的加權平均 Beta
        var totalValue = 0.0
        var weightedBeta = 0.0
        
        for stock in stocks {
            let beta = stockBetas[stock.symbol] ?? 1.0 // 預設值
            let value = Double(stock.shares) * (stock.purchasePrice ?? 100.0)
            
            totalValue += value
            weightedBeta += beta * value
        }
        
        return totalValue > 0 ? weightedBeta / totalValue : 1.0
    }
    
    // 計算最大回撤
    private func calculateMaxDrawdown(stocks: [Stock], startDate: Date, endDate: Date) -> Double {
        // 實際應用中應基於歷史價格計算
        // 這裡使用簡化版計算
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
            "2891": "金融"
        ]
        
        return industries[symbol] ?? "其他"
    }
    
    // 輔助方法 - 獲取當前股價
    private func getCurrentPrices() async -> [String: Double] {
        return await PortfolioManager.shared.getCurrentPrices(for: stocks)
    }
    
    // 輔助方法 - 計算時間加權報酬率
    private func calculateTimeWeightedReturn(stocksInRange: [Stock], currentPrices: [String: Double]) -> Double {
        // 這裡實現更精確的時間加權報酬率計算
        // 在實際應用中，這應該考慮每次投資的時間和金額
        
        // 簡化版實現:
        let totalReturn = stocksInRange.reduce(0.0) { total, stock in
            guard let currentPrice = currentPrices[stock.symbol] else { return total }
            
            // 一般持股報酬
            let purchasePrice = stock.purchasePrice ?? currentPrice
            let normalReturn = (currentPrice - purchasePrice) / purchasePrice
            
            // 實際應用中應考慮持有時間權重
            let weightedNormalReturn = normalReturn * 0.9 // 簡化時間加權
            
            return total + weightedNormalReturn
        }
        
        return totalReturn / Double(max(1, stocksInRange.count)) * 100
    }
    
    // 輔助方法 - 計算夏普比率
    private func calculateSharpeRatio(stocksInRange: [Stock], totalReturnPercentage: Double) -> Double {
        // 假設無風險利率為2.0%
        let riskFreeRate = 2.0
        let excessReturn = totalReturnPercentage - riskFreeRate
        
        // 投資組合波動率（在實際應用中應計算標準差）
        // 這裡使用簡化版計算
        let volatility = calculatePortfolioVolatility(stocks: stocksInRange)
        
        return volatility > 0 ? excessReturn / volatility : 0
    }
    
    // 輔助方法 - 獲取月底日期
    private func getEndOfMonth(for date: Date) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: date)
        components.month = components.month! + 1
        components.day = 0
        return calendar.date(from: components)
    }
    
    // 輔助方法 - 判斷特定股票在指定月份是否應該發放股利
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
}
