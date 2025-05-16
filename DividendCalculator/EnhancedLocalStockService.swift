//
//  EnhancedLocalStockService.swift
//  DividendCalculator
//
//  Created on 2025/3/6.
//

import Foundation

/// 增強版的 LocalStockService
/// 整合本地資料和 API 數據
class EnhancedLocalStockService {
    // MARK: - 單例模式
    static let shared = EnhancedLocalStockService()
    
    // 原始本地服務
    private let localService = LocalStockService()
    
    // 資料倉庫
    private let repository = StockRepository.shared
    
    // API 服務
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - 公開方法
    
    /// 搜尋股票
    func searchStocks(query: String) async -> [SearchStock] {
        return await repository.searchStocks(query: query)
    }
    
    /// 獲取股票名稱
    func getTaiwanStockInfo(symbol: String) async -> String? {
        let stockInfo = await repository.getStockInfo(symbol: symbol)
        return stockInfo.name
    }
    
    /// 獲取股利資訊
    func getTaiwanStockDividend(symbol: String) async -> Double? {
        do {
            // 從 API 獲取股息資料，添加重試邏輯
            var retryCount = 0
            let maxRetries = 2
            
            while retryCount <= maxRetries {
                do {
                    let dividendResponse = try await apiService.getDividendData(symbol: symbol)
                    
                    // 使用 SQLDataProcessor 處理資料
                    let dividendPerShare = SQLDataProcessor.shared.calculateDividendPerShare(from: dividendResponse.data)
                    
                    // 如果股利為0，可能是資料有誤，使用本地資料作為備用
                    if dividendPerShare <= 0 && retryCount < maxRetries {
                        print("警告：API返回的股利為0，重試...")
                        retryCount += 1
                        continue
                    }
                    
                    return dividendPerShare
                } catch {
                    print("嘗試 #\(retryCount + 1) 獲取股息資料失敗: \(error.localizedDescription)")
                    retryCount += 1
                    
                    // 如果已重試到最大次數，跳出循環
                    if retryCount > maxRetries {
                        break
                    }
                    
                    // 添加延遲
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }

            // 所有嘗試失敗，使用本地服務作為備用
            print("所有嘗試獲取股息資料失敗，使用本地數據")
            return await localService.getTaiwanStockDividend(symbol: symbol)
        }
    }
    
    /// 獲取股利頻率
    func getTaiwanStockFrequency(symbol: String) async -> Int? {
        do {
            // 從 API 獲取股息資料，添加重試邏輯
            var retryCount = 0
            let maxRetries = 2
            
            while retryCount <= maxRetries {
                do {
                    let dividendResponse = try await apiService.getDividendData(symbol: symbol)
                    
                    // 使用 SQLDataProcessor 處理資料
                    let frequency = SQLDataProcessor.shared.calculateDividendFrequency(from: dividendResponse.data)
                    
                    // 驗證結果
                    if frequency == 0 && retryCount < maxRetries {
                        print("警告：計算出的頻率為0，重試...")
                        retryCount += 1
                        continue
                    }
                    
                    return frequency
                } catch {
                    print("嘗試 #\(retryCount + 1) 獲取頻率資料失敗: \(error.localizedDescription)")
                    retryCount += 1
                    
                    // 如果已重試到最大次數，跳出循環
                    if retryCount > maxRetries {
                        break
                    }
                    
                    // 添加延遲
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
            
            // 所有嘗試失敗，使用本地服務作為備用
            print("所有嘗試獲取頻率資料失敗，使用本地數據")
            return await localService.getTaiwanStockFrequency(symbol: symbol)
        }
    }
    
    /// 獲取股票價格
    func getStockPrice(symbol: String, date: Date) async -> Double? {
        do {
            // 嘗試直接從資料庫獲取股票價格
            // 我們目前模擬資料庫不包含價格數據，後續可補充
            
            // 獲取資料庫的股利數據，並使用除息參考價作為參考
            let dividendResponse = try await apiService.getDividendData(symbol: symbol)
            
            // 查找最近的除息日資料
            let relevantRecord = findNearestDividendRecord(records: dividendResponse.data, date: date)
            
            if let record = relevantRecord, let referencePrice = record.exDividendReferencePrice {
                // 基於除息參考價，加上随機波動
                let randomFactor = Double.random(in: -0.05...0.05)
                return referencePrice * (1.0 + randomFactor)
            }
        } catch {
            print("從資料庫獲取股價失敗: \(error.localizedDescription)")
        }
        
        // 備用方案：使用本地服務生成模擬價格
        return await localService.getStockPrice(symbol: symbol, date: date)
    }
    
    
    /// 獲取股利歷史
    func getDividendHistory(symbol: String, years: Int = 3) async -> [DividendData] {
        return await repository.getDividendHistory(symbol: symbol, years: years)
    }
    
    /// 獲取股利發放時間表
    // In EnhancedLocalStockService.swift
    // Modify the getDividendSchedule method

    func getDividendSchedule(symbol: String) async -> [DividendData] {
        do {
            // 嘗試從資料庫獲取
            let dividendResponse = try await apiService.getDividendData(symbol: symbol)
            
            // 過濾出未來的股利發放記錄
            return DataMapper.mapToDividendSchedule(from: dividendResponse.data)
        } catch {
            print("獲取股利時間表失敗: \(error.localizedDescription)")
            
            // 使用本地模擬數據作為備用
            return await generateSimulatedDividendSchedule(symbol: symbol)
        }
    }

    // 添加這個模擬方法來生成股利時間表
    private func generateSimulatedDividendSchedule(symbol: String) async -> [DividendData] {
        var schedule: [DividendData] = []
        
        // 獲取基本股利資訊
        let dividendPerShare = await localService.getTaiwanStockDividend(symbol: symbol) ?? 2.0
        let frequency = await localService.getTaiwanStockFrequency(symbol: symbol) ?? 1
        
        let calendar = Calendar.current
        let today = Date()
        
        // 根據頻率生成未來的股利發放時間表
        for i in 0..<3 { // 生成未來3期
            // 計算除息日和發放日
            let monthsToAdd = 12 / frequency * (i + 1)
            
            guard let futureDate = calendar.date(byAdding: .month, value: monthsToAdd, to: today) else {
                continue
            }
            
            // 設置為當月15日
            var components = calendar.dateComponents([.year, .month], from: futureDate)
            components.day = 15
            
            guard let exDate = calendar.date(from: components),
                  let payDate = calendar.date(byAdding: .day, value: 30, to: exDate) else {
                continue
            }
            
            // 每股股利根據期數稍微變化
            let amount = dividendPerShare / Double(frequency) * (1.0 + Double(i) * 0.05)
            
            schedule.append(DividendData(
                id: UUID(),
                date: exDate,
                amount: amount,
                exDividendDate: exDate,
                paymentDate: payDate
            ))
        }
        
        return schedule.sorted { $0.exDividendDate < $1.exDividendDate }
    }
    
    /// 獲取產業列表
    func getIndustries() async -> [String] {
        // 檢查是否處於離線模式
        if isInOfflineMode() {
            // 使用預設產業列表
            return getDefaultIndustries()
        }
        
        // 嘗試從 API 獲取產業列表
        do {
            let industries = try await StockAPIService.shared.getIndustries()
            return industries
        } catch {
            print("獲取產業列表失敗，使用預設列表: \(error.localizedDescription)")
            return getDefaultIndustries()
        }
    }

    /// 獲取產業內的股票
    func getStocksByIndustry(industry: String) async -> [SearchStock] {
        // 檢查是否處於離線模式
        if isInOfflineMode() {
            // 使用本地搜索，模擬產業過濾
            return await repository.searchStocks(query: "")
                .filter { _ in Double.random(in: 0...1) < 0.3 }
                .prefix(10)
                .map { $0 }
        }
        
        // 從 API 獲取特定產業的股票
        do {
            let stocksInfo = try await StockAPIService.shared.getStocksByIndustry(industry: industry)
            return stocksInfo.map { SearchStock(symbol: $0.symbol, name: $0.name) }
        } catch {
            print("獲取產業股票失敗，使用隨機模擬數據: \(error.localizedDescription)")
            return await repository.searchStocks(query: "")
                .filter { _ in Double.random(in: 0...1) < 0.3 }
                .prefix(10)
                .map { $0 }
        }
    }

    // 新增輔助方法: 檢查是否處於離線模式
    private func isInOfflineMode() -> Bool {
        return !NetworkMonitor().isConnected || UserDefaults.standard.bool(forKey: "offlineMode")
    }

    // 新增輔助方法: 獲取預設產業列表
    private func getDefaultIndustries() -> [String] {
        return [
            "半導體", "電子零組件", "電腦及周邊設備", "光電", "通信網路",
            "電子通路", "資訊服務", "其他電子", "金融保險", "建材營造",
            "航運", "生技醫療", "食品", "紡織纖維", "鋼鐵", "觀光"
        ]
    }
    
    /// 更新定期定額股票的交易數據
    func updateRegularInvestmentTransactions(stock: inout Stock) async {
        // 保留原有的更新邏輯，但使用新的資料來源
        guard var regularInvestment = stock.regularInvestment,
              regularInvestment.isActive else {
            print("定期定額未啟用或不存在")
            return
        }
        
        // 獲取所有投資日期
        let investmentDates = regularInvestment.calculateInvestmentDates()
        
        // 計算交易紀錄
        var transactions: [RegularInvestmentTransaction] = regularInvestment.transactions ?? []
        
        for date in investmentDates {
            // 檢查此日期是否已經有交易紀錄
            let existingTransaction = transactions.first { $0.date == date }
            
            // 如果這個日期還沒有交易紀錄，且日期不超過結束日期（如果有設定的話）
            if existingTransaction == nil,
               regularInvestment.endDate.map({ date <= $0 }) ?? true {
                // 嘗試從資料庫獲取該日期的股價
                if let price = await getStockPrice(symbol: stock.symbol, date: date) {
                    let shares = Int(regularInvestment.amount / price)
                    let transaction = RegularInvestmentTransaction(
                        date: date,
                        amount: regularInvestment.amount,
                        shares: shares,
                        price: price,
                        isExecuted: date <= Date()
                    )
                    transactions.append(transaction)
                }
            }
        }
        
        // 排序交易紀錄，確保時間順序
        transactions.sort { $0.date < $1.date }
        
        // 更新定期定額的交易紀錄
        regularInvestment.transactions = transactions
        stock.regularInvestment = regularInvestment
    }
    
    // MARK: - 私有輔助方法
    
    /// 查找最接近指定日期的股利記錄
    private func findNearestDividendRecord(records: [DividendRecord], date: Date) -> DividendRecord? {
        // 按時間排序的記錄
        let sortedRecords = records.compactMap { record -> (DividendRecord, Date)? in
            guard let exDate = record.exDividendDateObj else { return nil }
            return (record, exDate)
        }
        .sorted { $0.1 < $1.1 }
        
        // 找到最接近日期的記錄
        var closestRecord: DividendRecord? = nil
        var minDifference = Double.infinity
        
        for (record, exDate) in sortedRecords {
            let difference = abs(exDate.timeIntervalSince(date))
            if difference < minDifference {
                minDifference = difference
                closestRecord = record
            }
        }
        
        return closestRecord
    }
}
