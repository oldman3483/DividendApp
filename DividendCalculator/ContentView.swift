//
//  ContentView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//  Updated on 2025/3/6 with API integration
//

import SwiftUI

struct ContentView: View {
    // MARK: - 狀態變數
    @AppStorage("isLoggedIn") private var isLoggedIn = false
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
    
    // API 相關狀態
    @State private var isOnlineMode = true // 是否使用在線數據模式
    
    @AppStorage("userId") private var userId = ""
    @AppStorage("loginMethod") private var loginMethod = ""
    
    let stockService = LocalStockService() // 保留本地服務用於模擬價格變動
    let repository = StockRepository.shared // 添加 repository 用於 API 數據
    
    // MARK: - 視圖
    var body: some View {
        if !isLoggedIn {
            LoginView()
        } else {
            mainContent
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
        .onChange(of: stocks) { oldValue, newValue in saveData() }
        .onChange(of: watchlist) { oldValue, newValue in saveData() }
        .onChange(of: banks) { oldValue, newValue in
            if let firstBank = newValue.first {
                selectedBankId = firstBank.id
            }
            saveData()
        }
    }
    
    // MARK: - 方法
    private func setupInitialState() {
        setupAppearance()
        
        // 使用 Task 來進行非同步加載
        Task {
            isLoading = true
            
            if isOnlineMode {
                // 嘗試從 API 加載數據
                await loadDataFromAPI()
            } else {
                // 從本地緩存加載資料
                loadLocalData()
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
        
        // 可以選擇是否清除資料
        // 如果想要保留資料以便使用者再次登入時仍然可以看到他們的資料，則不需要清除
        // 如果出於安全考慮需要清除資料，則取消下面的註解
        
        // stocks = []
        // watchlist = []
        // banks = []
        // searchText = ""
        
        // 將登出訊息顯示在主控台（可選）
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
        
        print("所有數據已重置")
    }
    // 從 API 載入資料
    private func loadDataFromAPI() async {
        // 在實際情況中，你需要實現以下 API 端點：
        // 1. 獲取用戶的銀行列表
        // 2. 獲取用戶的股票列表
        // 3. 獲取用戶的觀察清單
        
        // 由於目前沒有這些 API 端點，我們先載入本地資料
        loadLocalData()
        
        // 然後，我們可以嘗試更新股票的實時數據
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
                print("更新實時數據失敗，股票: \(symbol), 錯誤: \(error.localizedDescription)")
                // 出錯時繼續下一個股票，不中斷整個流程
                continue
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

#Preview {
    ContentView()
}
