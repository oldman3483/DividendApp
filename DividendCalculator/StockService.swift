////
////  StockService.swift
////  DividendCalculator
////
////  Created on 2025/5/5.
////
//
//import SwiftUI
//
//class StockService {
//    // MARK: - 單例模式
//    static let shared = StockService()
//    
//    // 服務依賴
//    private let apiService = APIService.shared
//    private let repository = StockRepository.shared
//    
//    // 模擬資料（僅在離線模式或 API 失敗時使用）
//    private let mockStocks = [
//        ("2330", "台積電", 2.75, 4, 550.0),
//        ("2317", "鴻海", 5.0, 1, 120.0),
//        ("2454", "聯發科", 3.0, 4, 850.0),
//        ("2412", "中華電", 4.5, 4, 120.0),
//        ("2308", "台達電", 3.5, 4, 290.0),
//        ("2881", "富邦金", 3.0, 2, 75.0),
//        ("2882", "國泰金", 2.5, 2, 45.0),
//        ("1301", "台塑", 4.0, 1, 110.0),
//        ("1303", "南亞", 3.2, 1, 85.0),
//        ("2891", "中信金", 2.8, 2, 25.0),
//        ("0050", "元大台灣50", 2.0, 4, 120.0)
//    ]
//    
//    // 波動性參數（僅用於模擬價格）
//    private let volatilityRange: ClosedRange<Double> = -0.05...0.05
//    private let trendBias: ClosedRange<Double> = -0.02...0.03
//    
//    // 記錄每個股票的最後價格（用於模擬連續的價格變動）
//    private var lastPrices = [String: Double]()
//    
//    private init() {}
//    
//    // MARK: - 公開方法
//    
//    /// 搜尋股票
//    func searchStocks(query: String) async -> [SearchStock] {
//        // 嘗試從 API 獲取數據
//        if !isOfflineMode() {
//            do {
//                // 這裡可以添加真實的 API 搜索邏輯
//                // 暫時還是使用模擬數據
//                return mockStockSearch(query: query)
//            } catch {
//                print("API 搜索失敗，使用模擬數據: \(error.localizedDescription)")
//            }
//        }
//        
//        // 使用模擬數據作為備用
//        return mockStockSearch(query: query)
//    }
//    
//    /// 取得股票基本資訊
//    func getStockInfo(symbol: String) async -> String? {
//        // 嘗試從 API 獲取數據
//        if !isOfflineMode() {
//            do {
//                // 這裡可以添加真實的 API 邏輯
//                // 暫時還是使用模擬數據
//                return mockStocks.first { $0.0 == symbol }?.1
//            } catch {
//                print("API 獲取股票資訊失敗，使用模擬數據: \(error.localizedDescription)")
//            }
//        }
//        
//        // 使用模擬數據作為備用
//        return mockStocks.first { $0.0 == symbol }?.1
//    }
//    
//    /// 取得股利資訊
//    func getStockDividend(symbol: String) async -> Double? {
//        // 嘗試從 API 獲取股息資料
//        if !isOfflineMode() {
//            do {
//                let dividendResponse = try await apiService.getDividendData(symbol: symbol)
//                
//                // 使用 SQLDataProcessor 處理資料
//                let dividendPerShare = SQLDataProcessor.shared.calculateDividendPerShare(from: dividendResponse.data)
//                
//                // 如果股利為 0，可能是資料有誤，使用模擬資料作為備用
//                if dividendPerShare <= 0 {
//                    print("警告：API 返回的股利為 0，使用模擬數據")
//                    return mockStocks.first { $0.0 == symbol }?.2
//                }
//                
//                return dividendPerShare
//            } catch {
//                print("從 API 獲取股息資料失敗: \(error.localizedDescription)")
//            }
//        }
//        
//        // 使用模擬數據作為備用
//        return mockStocks.first { $0.0 == symbol }?.2
//    }
//    
//    /// 獲取股利頻率
//    func getStockFrequency(symbol: String) async -> Int? {
//        // 嘗試從 API 獲取股息資料
//        if !isOfflineMode() {
//            do {
//                let dividendResponse = try await apiService.getDividendData(symbol: symbol)
//                
//                // 使用 SQLDataProcessor 處理資料
//                let frequency = SQLDataProcessor.shared.calculateDividendFrequency(from: dividendResponse.data)
//                
//                // 驗證結果
//                if frequency == 0 {
//                    print("警告：計算出的頻率為 0，使用模擬數據")
//                    return mockStocks.first { $0.0 == symbol }?.3
//                }
//                
//                return frequency
//            } catch {
//                print("從 API 獲取頻率資料失敗: \(error.localizedDescription)")
//            }
//        }
//        
//        // 使用模擬數據作為備用
//        return mockStocks.first { $0.0 == symbol }?.3
//    }
//    
//    /// 獲取股票價格
//    func getStockPrice(symbol: String, date: Date) async -> Double? {
//        // 嘗試從 API 獲取股價資料
//        if !isOfflineMode() {
//            do {
//                // 嘗試直接從資料庫獲取股票價格
//                // 在這裡可以添加真實資料庫查詢邏輯
//                
//                // 獲取資料庫的股利數據，並使用除息參考價作為參考
//                let dividendResponse = try await apiService.getDividendData(symbol: symbol)
//                
//                // 查找最近的除息日資料
//                let relevantRecord = findNearestDividendRecord(records: dividendResponse.data, date: date)
//                
//                if let record = relevantRecord, let referencePrice = record.ex_dividend_reference_price {
//                    // 基於除息參考價，加上随機波動
//                    let randomFactor = Double.random(in: -0.05...0.05)
//                    return referencePrice * (1.0 + randomFactor)
//                }
//            } catch {
//                print("從資料庫獲取股價失敗: \(error.localizedDescription)")
//            }
//        }
//        
//        // 備用方案：使用模擬價格生成
//        return generateMockPrice(symbol: symbol, date: date)
//    }
//    
//    /// 獲取股利歷史
//    func getDividendHistory(symbol: String, years: Int = 3) async -> [DividendData] {
//        // 嘗試從 API 獲取股利歷史
//        if !isOfflineMode() {
//            do {
//                let dividendResponse = try await apiService.getDividendData(symbol: symbol)
//                return DataMapper.mapToDividendData(from: dividendResponse.data)
//            } catch {
//                print("獲取股利歷史失敗: \(error.localizedDescription)")
//            }
//        }
//        
//        // 使用模擬數據作為備用
//        return await generateSimulatedDividendHistory(symbol: symbol, years: years)
//    }
//    
//    /// 獲取股利發放時間表
//    func getDividendSchedule(symbol: String) async -> [DividendData] {
//        // 嘗試從 API 獲取
//        if !isOfflineMode() {
//            do {
//                let dividendResponse = try await apiService.getDividendData(symbol: symbol)
//                
//                // 過濾出未來的股利發放記錄
//                return DataMapper.mapToDividendSchedule(from: dividendResponse.data)
//            } catch {
//                print("獲取股利時間表失敗: \(error.localizedDescription)")
//            }
//        }
//        
//        // 使用模擬數據作為備用
//        return await generateSimulatedDividendSchedule(symbol: symbol)
//    }
//    
//    /// 更新定期定額股票的交易數據
//    func updateRegularInvestmentTransactions(stock: inout Stock) async {
//        guard var regularInvestment = stock.regularInvestment,
//              regularInvestment.isActive else {
//            print("定期定額未啟用或不存在")
//            return
//        }
//        
//        // 獲取所有投資日期
//        let investmentDates = regularInvestment.calculateInvestmentDates()
//        
//        // 計算交易紀錄
//        var transactions: [RegularInvestmentTransaction] = regularInvestment.transactions ?? []
//        
//        for date in investmentDates {
//            // 檢查此日期是否已經有交易紀錄
//            let existingTransaction = transactions.first { $0.date == date }
//            
//            // 如果這個日期還沒有交易紀錄，且日期不超過結束日期（如果有設定的話）
//            if existingTransaction == nil,
//               regularInvestment.endDate.map({ date <= $0 }) ?? true {
//                // 嘗試獲取該日期的股價
//                if let price = await getStockPrice(symbol: stock.symbol, date: date) {
//                    let shares = Int(regularInvestment.amount / price)
//                    let transaction = RegularInvestmentTransaction(
//                        date: date,
//                        amount: regularInvestment.amount,
//                        shares: shares,
//                        price: price,
//                        isExecuted: date <= Date()
//                    )
//                    transactions.append(transaction)
//                }
//            }
//        }
//        
//        // 排序交易紀錄，確保時間順序
//        transactions.sort { $0.date < $1.date }
//        
//        // 更新定期定額的交易紀錄
//        regularInvestment.transactions = transactions
//        stock.regularInvestment = regularInvestment
//    }
//    
//    // MARK: - 私有方法
//    
//    /// 檢查是否處於離線模式
//    private func isOfflineMode() -> Bool {
//        return !NetworkMonitor().isConnected || UserDefaults.standard.bool(forKey: "offlineMode")
//    }
//    
//    /// 模擬股票搜索
//    private func mockStockSearch(query: String) -> [SearchStock] {
//        return mockStocks
//            .filter { stockInfo in
//                let (symbol, name, _, _, _) = stockInfo
//                return symbol.lowercased().contains(query.lowercased()) ||
//                       name.lowercased().contains(query.lowercased())
//            }
//            .map { SearchStock(symbol: $0.0, name: $0.1) }
//    }
//    
//    /// 模擬股票價格生成
//    private func generateMockPrice(symbol: String, date: Date) -> Double {
//        // 取得基礎價格
//        let basePrice = mockStocks.first { $0.0 == symbol }?.4 ?? 0
//        
//        // 如果沒有最後價格，初始化為基礎價格
//        if lastPrices[symbol] == nil {
//            lastPrices[symbol] = basePrice
//        }
//        
//        // 獲取最後價格
//        let lastPrice = lastPrices[symbol] ?? basePrice
//        
//        // 生成隨機波動
//        let randomVolatility = Double.random(in: volatilityRange)
//        let trendComponent = Double.random(in: trendBias)
//        
//        // 計算新價格，綜合考慮波動性和趨勢
//        let variation = randomVolatility + trendComponent
//        var newPrice = lastPrice * (1 + variation)
//        
//        // 加入價格限制，避免價格過度偏離基礎價格
//        let maxDeviation = basePrice * 0.2 // 最大允許偏離基準價格的 20%
//        let minPrice = basePrice - maxDeviation
//        let maxPrice = basePrice + maxDeviation
//        newPrice = min(max(newPrice, minPrice), maxPrice)
//        
//        // 更新最後價格
//        lastPrices[symbol] = newPrice
//        
//        return newPrice
//    }
//    
//    /// 生成模擬的股利歷史數據
//    private func generateSimulatedDividendHistory(symbol: String, years: Int) async -> [DividendData] {
//        var dividendHistory: [DividendData] = []
//        
//        // 獲取基準股利
//        let baseDividend = await getStockDividend(symbol: symbol) ?? 2.0
//        let frequency = await getStockFrequency(symbol: symbol) ?? 1
//        
//        let calendar = Calendar.current
//        let today = Date()
//        let currentYear = calendar.component(.year, from: today)
//        
//        // 根據頻率生成歷史數據
//        for year in (currentYear - years)...currentYear {
//            for period in 0..<frequency {
//                let month = 12 / frequency * period + 1
//                
//                var dateComponents = DateComponents()
//                dateComponents.year = year
//                dateComponents.month = month
//                dateComponents.day = 15
//                
//                guard let recordDate = calendar.date(from: dateComponents),
//                      let exDate = calendar.date(byAdding: .day, value: -14, to: recordDate),
//                      let payDate = calendar.date(byAdding: .day, value: 30, to: recordDate) else {
//                    continue
//                }
//                
//                // 模擬股利波動
//                let dividendVariation = Double.random(in: -0.2...0.2)
//                let amount = baseDividend / Double(frequency) * (1 + dividendVariation)
//                
//                dividendHistory.append(DividendData(
//                    id: UUID(),
//                    date: recordDate,
//                    amount: amount,
//                    exDividendDate: exDate,
//                    paymentDate: payDate
//                ))
//            }
//        }
//        
//        return dividendHistory.sorted(by: { $0.date > $1.date })
//    }
//    
//    /// 生成模擬的股利時間表
//    private func generateSimulatedDividendSchedule(symbol: String) async -> [DividendData] {
//        var schedule: [DividendData] = []
//        
//        // 獲取基本股利資訊
//        let dividendPerShare = await getStockDividend(symbol: symbol) ?? 2.0
//        let frequency = await getStockFrequency(symbol: symbol) ?? 1
//        
//        let calendar = Calendar.current
//        let today = Date()
//        
//        // 根據頻率生成未來的股利發放時間表
//        for i in 0..<3 { // 生成未來3期
//            // 計算除息日和發放日
//            let monthsToAdd = 12 / frequency * (i + 1)
//            
//            guard let futureDate = calendar.date(byAdding: .month, value: monthsToAdd, to: today) else {
//                continue
//            }
//            
//            // 設置為當月15日
//            var components = calendar.dateComponents([.year, .month], from: futureDate)
//            components.day = 15
//            
//            guard let exDate = calendar.date(from: components),
//                  let payDate = calendar.date(byAdding: .day, value: 30, to: exDate) else {
//                continue
//            }
//            
//            // 每股股利根據期數稍微變化
//            let amount = dividendPerShare / Double(frequency) * (1.0 + Double(i) * 0.05)
//            
//            schedule.append(DividendData(
//                id: UUID(),
//                date: exDate,
//                amount: amount,
//                exDividendDate: exDate,
//                paymentDate: payDate
//            ))
//        }
//        
//        return schedule.sorted { $0.exDividendDate < $1.exDividendDate }
//    }
//    
//    /// 查找最接近指定日期的股利記錄
//    private func findNearestDividendRecord(records: [DividendRecord], date: Date) -> DividendRecord? {
//        // 按時間排序的記錄
//        let sortedRecords = records.compactMap { record -> (DividendRecord, Date)? in
//            guard let exDate = record.exDividendDateObj else { return nil }
//            return (record, exDate)
//        }
//        .sorted { $0.1 < $1.1 }
//        
//        // 找到最接近日期的記錄
//        var closestRecord: DividendRecord? = nil
//        var minDifference = Double.infinity
//        
//        for (record, exDate) in sortedRecords {
//            let difference = abs(exDate.timeIntervalSince(date))
//            if difference < minDifference {
//                minDifference = difference
//                closestRecord = record
//            }
//        }
//        
//        return closestRecord
//    }
//}
