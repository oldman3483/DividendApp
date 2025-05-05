//
//  StockRepository.swift
//  DividendCalculator
//

import Foundation

/// 股票資料倉庫 - 整合本地和遠端資料來源
class StockRepository {
    // MARK: - 單例模式
    static let shared = StockRepository()
    
    // 服務
    private let localService = LocalStockService()
    private let apiService = APIService.shared
    
    // 緩存
    private var stockCache: [String: StockInfoResponse] = [:]
    private var dividendCache: [String: [DividendRecord]] = [:]
    private var priceCache: [String: [Date: Double]] = [:]
    
    private init() {}
    
    // MARK: - 公開方法
    
    /// 搜索股票
    func searchStocks(query: String) async -> [SearchStock] {
        // 檢查是否處於離線模式
        if isInOfflineMode() {
            // 使用本地搜索
            return await localService.searchStocks(query: query)
        }
        
        // 使用本地搜索，後續可改為API搜索
        return await localService.searchStocks(query: query)
    }
    
    /// 獲取股票資訊
    func getStockInfo(symbol: String) async -> (name: String?, dividendPerShare: Double?, frequency: Int?) {
        // 如果處於離線模式，直接使用本地數據
        if isInOfflineMode() {
            let name = await localService.getTaiwanStockInfo(symbol: symbol)
            let dividend = await localService.getTaiwanStockDividend(symbol: symbol)
            let frequency = await localService.getTaiwanStockFrequency(symbol: symbol)
            
            return (name, dividend, frequency)
        }
        
        // 嘗試獲取股利資料
        do {
            // 如果緩存中沒有，則從API獲取
            if dividendCache[symbol] == nil {
                let response = try await apiService.getDividendData(symbol: symbol)
                dividendCache[symbol] = response.data
            }
            
            // 使用股利資料計算每股股利和頻率
            if let dividendRecords = dividendCache[symbol], !dividendRecords.isEmpty {
                // 獲取最近兩年的股利記錄
                let recentRecords = dividendRecords.filter { record in
                    guard let year = Int(record.dividendYear) else { return false }
                    let currentYear = Calendar.current.component(.year, from: Date())
                    return year >= currentYear - 2
                }
                
                // 計算每股股利 (使用最近年度的總股利)
                let latestRecord = recentRecords.max(by: { a, b in
                    guard let yearA = Int(a.dividendYear), let yearB = Int(b.dividendYear) else {
                        return false
                    }
                    return yearA < yearB
                })
                
                let dividendPerShare = latestRecord?.totalDividend ?? 0
                
                // 計算發放頻率 (根據最近兩年的記錄判斷)
                let frequency = determineFrequency(from: recentRecords)
                
                // 從本地資料獲取股票名稱
                let name = await localService.getTaiwanStockInfo(symbol: symbol)
                
                return (name, dividendPerShare, frequency)
            }
        } catch {
            print("無法獲取股利資料，使用本地資料作為備用: \(error.localizedDescription)")
        }
        
        // 備用：使用本地資料
        let name = await localService.getTaiwanStockInfo(symbol: symbol)
        let dividend = await localService.getTaiwanStockDividend(symbol: symbol)
        let frequency = await localService.getTaiwanStockFrequency(symbol: symbol)
        
        return (name, dividend, frequency)
    }
    
    /// 獲取股利歷史
    func getDividendHistory(symbol: String, years: Int = 3) async -> [DividendData] {
        // 嘗試從API獲取
        do {
            // 如果緩存中沒有，則從API獲取
            if dividendCache[symbol] == nil {
                let response = try await apiService.getDividendData(symbol: symbol)
                dividendCache[symbol] = response.data
            }
            
            // 將API數據轉換為應用程序模型
            if let dividendRecords = dividendCache[symbol] {
                let filteredRecords = filterRecordsByYears(dividendRecords, years: years)
                return mapToDividendData(from: filteredRecords)
            }
        } catch {
            print("獲取股利歷史失敗，使用模擬數據: \(error.localizedDescription)")
        }
        
        // 備用：生成模擬數據
        return await generateSimulatedDividendHistory(symbol: symbol, years: years)
    }
    
    /// 獲取指定日期的股票價格
    func getStockPrice(symbol: String, date: Date) async -> Double? {
        // 嘗試從緩存獲取
        if let symbolCache = priceCache[symbol], let price = symbolCache[date] {
            return price
        }
        
        // 這裡應該從數據庫獲取股價數據
        // 暫時使用本地服務的模擬數據
        return await localService.getStockPrice(symbol: symbol, date: date)
    }
    
    // 檢查是否處於離線模式
    func isInOfflineMode() -> Bool {
        // 可以檢查網絡狀態或者從 UserDefaults 中獲取設置
        return !NetworkMonitor().isConnected
    }
    
    // MARK: - 私有輔助方法
    
    // 從股利記錄判斷發放頻率
    private func determineFrequency(from records: [DividendRecord]) -> Int {
        // 統計不同期間的記錄
        var yearly = 0
        var halfYearly = 0
        var quarterly = 0
        
        for record in records {
            if record.dividendPeriod.contains("全年") {
                yearly += 1
            } else if record.dividendPeriod.contains("半年") {
                halfYearly += 1
            } else if record.dividendPeriod.contains("季") {
                quarterly += 1
            }
        }
        
        // 根據統計結果判斷頻率
        if quarterly > 0 {
            return 4 // 季配
        } else if halfYearly > 0 {
            return 2 // 半年配
        } else {
            return 1 // 年配
        }
    }
    
    // 按年份過濾記錄
    private func filterRecordsByYears(_ records: [DividendRecord], years: Int) -> [DividendRecord] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let minYear = currentYear - years
        
        return records.filter { record in
            guard let year = Int(record.dividendYear) else { return false }
            return year >= minYear
        }
    }
    
    // 將API股利記錄轉換為應用程序模型
    private func mapToDividendData(from records: [DividendRecord]) -> [DividendData] {
        return records.compactMap { record -> DividendData? in
            guard let exDate = record.exDividendDateObj else { return nil }
            let payDate = record.distributionDateObj ?? exDate
            
            return DividendData(
                id: UUID(),
                date: exDate,
                amount: record.totalCashDividend,
                exDividendDate: exDate,
                paymentDate: payDate
            )
        }
    }
    
    /// 生成模擬的股利歷史數據
    private func generateSimulatedDividendHistory(symbol: String, years: Int) async -> [DividendData] {
        var dividendHistory: [DividendData] = []
        
        // 獲取基準股利
        let baseDividend = await localService.getTaiwanStockDividend(symbol: symbol) ?? 2.0
        let frequency = await localService.getTaiwanStockFrequency(symbol: symbol) ?? 1
        
        let calendar = Calendar.current
        let today = Date()
        let currentYear = calendar.component(.year, from: today)
        
        // 根據頻率生成歷史數據
        for year in (currentYear - years)...currentYear {
            for period in 0..<frequency {
                let month = 12 / frequency * period + 1
                
                var dateComponents = DateComponents()
                dateComponents.year = year
                dateComponents.month = month
                dateComponents.day = 15
                
                guard let recordDate = calendar.date(from: dateComponents),
                      let exDate = calendar.date(byAdding: .day, value: -14, to: recordDate),
                      let payDate = calendar.date(byAdding: .day, value: 30, to: recordDate) else {
                    continue
                }
                
                // 模擬股利波動
                let dividendVariation = Double.random(in: -0.2...0.2)
                let amount = baseDividend / Double(frequency) * (1 + dividendVariation)
                
                dividendHistory.append(DividendData(
                    id: UUID(),
                    date: recordDate,
                    amount: amount,
                    exDividendDate: exDate,
                    paymentDate: payDate
                ))
            }
        }
        
        return dividendHistory.sorted(by: { $0.date > $1.date })
    }
}
