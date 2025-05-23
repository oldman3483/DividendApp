//
//  ContentView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//  Updated on 2025/3/6 with API integration
//

import SwiftUI

// 全局股價服務，作為單例來提供一致的價格數據
class GlobalStockPriceService {
    static let shared = GlobalStockPriceService()
    
    private let stockService = LocalStockService()
    private var priceCache: [String: [String: Double]] = [:] // symbol -> date -> price
    private let dateFormatter = DateFormatter()
    
    private init() {
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    // 獲取指定日期的股價，確保相同的日期和股票代號總是返回相同的價格
    func getStockPrice(symbol: String, date: Date) async -> Double? {
        let dateString = dateFormatter.string(from: date)
        
        // 檢查緩存
        if let symbolCache = priceCache[symbol], let price = symbolCache[dateString] {
            return price
        }
        
        // 從本地服務獲取價格
        if let price = await stockService.getStockPrice(symbol: symbol, date: date) {
            // 添加到緩存
            if priceCache[symbol] == nil {
                priceCache[symbol] = [:]
            }
            priceCache[symbol]?[dateString] = price
            return price
        }
        
        return nil
    }
    
    // 獲取多個股票的當前價格
    func getCurrentPrices(for symbols: [String]) async -> [String: Double] {
        var prices: [String: Double] = [:]
        let today = Date()
        
        for symbol in symbols {
            if let price = await getStockPrice(symbol: symbol, date: today) {
                prices[symbol] = price
            }
        }
        
        return prices
    }
    
    // 清除緩存（例如在日期變更時）
    func clearCache() {
        priceCache.removeAll()
    }
}

struct ContentView: View {
    // MARK: - 狀態變數
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("autoUpdateStocks") private var autoUpdateStocks = true

    @State private var stocks: [Stock] = []
    @State private var watchlist: [WatchStock] = []
    @State private var searchText: String = ""
    @State private var isEditing = false
    @State private var selectedBankId: UUID = UUID()
    @State private var banks: [Bank] = []
    @State private var showingLogoutAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showingErrorAlert = false
    @State private var isOnline = true
    @State private var showOfflineIndicator = false
    @State private var showTestResult: Bool = false
    @State private var testResultMessage: String = ""
    
    // API 相關狀態
    @State private var isOnlineMode = true // 是否使用在線數據模式
    
    // 添加網絡監視器
    @StateObject private var networkMonitor = NetworkMonitor()
    
    @AppStorage("userId") private var userId = ""
    @AppStorage("loginMethod") private var loginMethod = ""
    @AppStorage("offlineMode") private var offlineMode = false
    
    
    let stockService = LocalStockService() // 保留本地服務用於模擬價格變動
    let repository = StockRepository.shared // 添加 repository 用於 API 數據
    
    private let globalStockService = GlobalStockPriceService.shared
    
    // MARK: - 視圖
    var body: some View {
        if !isLoggedIn {
            LoginView()
        } else {
            mainContent
                .onAppear {
                    setupInitialState()
                }
                .overlay {
                    if isLoading {
                        ProgressView("資料讀取中...")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .alert("錯誤", isPresented: $showingErrorAlert) {
                    Button("確定", role: .cancel) { }
                } message: {
                    Text(errorMessage ?? "發生未知錯誤")
                }
        }
    }
    
    // MARK: - 主要內容視圖
    private var mainContent: some View {
        let searchBar = SearchBarView(
            searchText: $searchText,
            stocks: $stocks,
            watchlist: $watchlist,
            banks: $banks,
            bankId: selectedBankId
        )
        
        let mainContent = MainTabView(
            stocks: $stocks,
            watchlist: $watchlist,
            banks: $banks,
            selectedBankId: $selectedBankId
        )
        
        return ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: -45) {
                searchBar.zIndex(1)
                mainContent
            }
        }
        .alert("登出確認", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("登出", role: .destructive) { handleLogout() }
        } message: {
            Text("確定要登出嗎？")
        }
        .onAppear {
            setupInitialState()
            // 添加清除數據的通知觀察者
            NotificationCenter.default.addObserver(
                forName: Notification.Name("ClearAllData"),
                object: nil,
                queue: .main
            ) { _ in
                self.resetAllData()
            }
        }
        .onDisappear {
            // 移除觀察者
            NotificationCenter.default.removeObserver(self)
        }
        .onChange(of: stocks) { oldValue, newValue in
            if oldValue != newValue {
                saveData()
            }
        }
        .onChange(of: watchlist) { oldValue, newValue in saveData() }
        .onChange(of: banks) { oldValue, newValue in
            if let firstBank = newValue.first {
                selectedBankId = firstBank.id
            }
            saveData()
        }
        .onChange(of: networkMonitor.isConnected) { oldValue, newValue in
            isOnline = newValue
            showOfflineIndicator = !newValue
            
            // 如果網絡恢復連接，嘗試與服務器同步數據
            if newValue && !oldValue {
                Task {
                    await synchronizeDataWithServer()
                }
            }
        }
    }
    
    // MARK: - 方法
    private func setupInitialState() {
        setupAppearance()
        
        // 清理舊的價格緩存
        stockService.cleanOldPriceCache()
        
        // 重置價格緩存
        GlobalStockPriceService.shared.clearCache()
        
        // 使用 Task 來進行非同步加載
        Task {
            isLoading = true
            
            // 檢查網絡連接狀態和離線模式設置
            isOnlineMode = networkMonitor.isConnected && !offlineMode
            
            if isOnlineMode && autoUpdateStocks {
                // 嘗試從 API 加載數據
                await loadDataFromAPI()
            } else {
                // 從本地緩存加載資料
                loadLocalData()
                // 如果是手動設置的離線模式，顯示提示
                if offlineMode {
                    showOfflineIndicator = true
                }
            }
            
            // 在獲取完成後確保有銀行
            if banks.isEmpty {
                // 如果沒有銀行資料，創建一個預設銀行
                let defaultBank = Bank(name: "預設銀行")
                banks = [defaultBank]
            }
            
            if let firstBank = banks.first {
                selectedBankId = firstBank.id
            }
            
            isLoading = false
        }
        
        // 添加離線模式變更的通知觀察者
        NotificationCenter.default.addObserver(
            forName: Notification.Name("OfflineModeChanged"),
            object: nil,
            queue: .main
        ) { notification in
            guard let isOffline = notification.userInfo?["isOffline"] as? Bool else { return }
            
            self.isOnlineMode = !isOffline && self.networkMonitor.isConnected
            self.showOfflineIndicator = isOffline
            
            // 根據離線模式變更來處理數據
            if !isOffline && self.networkMonitor.isConnected {
                // 如果退出離線模式且有網絡，嘗試同步數據
                Task {
                    await self.loadDataFromAPI()
                }
            }
        }
        // 添加同步服務器數據的通知觀察者
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SyncWithServer"),
            object: nil,
            queue: .main
        ) { _ in
            // 嘗試同步數據
            Task {
                await self.loadDataFromAPI()
            }
        }
    }
    private func synchronizeDataWithServer() async {
        await loadDataFromAPI()
    }
    
    private func setupAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .black
        tabBarAppearance.shadowColor = nil
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = .black
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .black
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.shadowColor = nil
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
    
    // 登出處理
    private func handleLogout() {
        // 設置登入狀態為 false
        isLoggedIn = false
        print("使用者已登出")
    }
    // 重置所有數據
    private func resetAllData() {
        // 清空所有數據狀態
        stocks = []
        watchlist = []
        banks = []
        searchText = ""
        
        // 創建一個新的預設銀行
        let defaultBank = Bank(name: "預設銀行")
        banks = [defaultBank]
        selectedBankId = defaultBank.id
        
        // 儲存清空後的狀態
        saveData()
        
        // 確保重置所有 UserDefaults 的值，包括「我的規劃」相關的數據
        // 這裡不需要逐一列出所有 key，因為使用者會自己重新建立規劃
        if Bundle.main.bundleIdentifier != nil {
            let defaults = UserDefaults.standard
            let keys = defaults.dictionaryRepresentation().keys
            
            // 保留特定的設定
            let keysToKeep = ["isLoggedIn", "userId", "loginMethod", "dividendNotification", "priceNotification", "offlineMode"]
            
            for key in keys {
                // 判斷是否需要保留該設定
                if !keysToKeep.contains(key) {
                    defaults.removeObject(forKey: key)
                }
            }
        }
        
        print("所有數據已重置")
    }
    
    // 從 API 載入資料
    private func loadDataFromAPI() async {
        // 檢查網絡連接狀態
        if !networkMonitor.isConnected || offlineMode {
            // 從本地緩存加載資料
            loadLocalData()
            
            // 如果是手動設置的離線模式，顯示提示
            if offlineMode {
                showOfflineIndicator = true
            }
            return
        }
        
        // 嘗試從API獲取數據
        let baseURL = "https://postgres-1-148949302162.asia-east1.run.app"
        
        // 使用 async/await 形式進行連接檢查
        let isServerConnected = await withCheckedContinuation { continuation in
            networkMonitor.checkServerConnection(urlString: baseURL) { isConnected, _ in
                continuation.resume(returning: isConnected)
            }
        }
        
        if !isServerConnected {
            // 如果無法連接後端，使用本地數據
            loadLocalData()
            // 顯示離線指示器
            showOfflineIndicator = true
            return
        }
        
        // 暫時先加載本地數據
        loadLocalData()
        
        // 更新股票實時數據
        await updateStocksWithLiveData()
    }
    
    // 更新股票實時數據
    private func updateStocksWithLiveData() async {
        // 獲取所有不重複的股票代碼
        let uniqueSymbols = Array(Set(stocks.map { $0.symbol }))
        
        for symbol in uniqueSymbols {
            do {
                // 獲取股票信息
                let stockInfo = try await StockAPIService.shared.getStockInfo(symbol: symbol)
                
                // 更新相關股票的當前價格和股息信息
                await MainActor.run {
                    // 使用 enumerated 獲取索引，以便可以直接修改 stocks 數組
                    for i in 0..<stocks.count where stocks[i].symbol == symbol {
                        stocks[i].dividendPerShare = stockInfo.dividendPerShare
                        // 其他可能的更新...
                    }
                }
            } catch {
                // 檢查是否為網絡連接問題或離線模式
                if let apiError = error as? APIError,
                   apiError.code == 0 || !NetworkMonitor().isConnected {
                    print("網絡連接問題，暫停更新實時數據")
                    break // 停止嘗試更新
                } else {
                    print("更新實時數據失敗，股票: \(symbol), 錯誤: \(error.localizedDescription)")
                    continue // 對於特定股票的錯誤，跳過該股票繼續下一個
                }
            }
        }
    }
    
    // 從本地載入資料
    private func loadLocalData() {
        // 從 UserDefaults 加載資料
        if let stocksData = UserDefaults.standard.data(forKey: "stocks"),
           let decodedStocks = try? JSONDecoder().decode([Stock].self, from: stocksData) {
            stocks = decodedStocks
        }
        
        if let watchlistData = UserDefaults.standard.data(forKey: "watchlist"),
           let decodedWatchlist = try? JSONDecoder().decode([WatchStock].self, from: watchlistData) {
            watchlist = decodedWatchlist
        }
        
        if let banksData = UserDefaults.standard.data(forKey: "banks"),
           let decodedBanks = try? JSONDecoder().decode([Bank].self, from: banksData) {
            banks = decodedBanks
        } else if banks.isEmpty {
            // 如果沒有銀行資料，創建一個預設銀行
            let defaultBank = Bank(name: "預設銀行")
            banks = [defaultBank]
            selectedBankId = defaultBank.id
        }
    }
    
    // 儲存資料
    private func saveData() {
        // 儲存到 UserDefaults
        if let encodedStocks = try? JSONEncoder().encode(stocks) {
            UserDefaults.standard.set(encodedStocks, forKey: "stocks")
        }
        
        if let encodedWatchlist = try? JSONEncoder().encode(watchlist) {
            UserDefaults.standard.set(encodedWatchlist, forKey: "watchlist")
        }
        
        if let encodedBanks = try? JSONEncoder().encode(banks) {
            UserDefaults.standard.set(encodedBanks, forKey: "banks")
        }
    }
}

