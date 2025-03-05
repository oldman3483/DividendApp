//
//  ContentView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
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
    
    let stockService = LocalStockService() // 保留本地服務用於模擬價格變動
    
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
            do {
                isLoading = true
                
                // 測試資料庫連接
                let isConnected = try await PostgresService.shared.testConnection()
                if !isConnected {
                    errorMessage = "無法連接到資料庫，請檢查網絡連接"
                    showingErrorAlert = true
                    isLoading = false
                    return
                }
                
                // 從資料庫獲取資料
                await loadDataFromDatabase()
                
                // 在獲取完成後更新 UI
                if let firstBank = banks.first {
                    selectedBankId = firstBank.id
                }
                
                isLoading = false
            } catch {
                // 如果無法連接到資料庫，嘗試從本地加載
                print("資料庫連接錯誤: \(error.localizedDescription)")
                errorMessage = "資料庫連接失敗: \(error.localizedDescription)\n正在嘗試加載本地資料..."
                showingErrorAlert = true
                
                // 從本地緩存加載資料
                loadLocalData()
                
                if let firstBank = banks.first {
                    selectedBankId = firstBank.id
                }
                
                isLoading = false
            }
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
    
    // 從資料庫載入資料
    private func loadDataFromDatabase() async {
        do {
            // 從資料庫加載銀行列表
            let fetchedBanks = try await PostgresService.shared.fetchBanks()
            
            // 從資料庫加載股票列表
            let fetchedStocks = try await PostgresService.shared.fetchStocks()
            
            // 從資料庫加載觀察清單
            let fetchedWatchlist = try await PostgresService.shared.fetchWatchlist()
            
            // 使用 MainActor 更新 UI
            await MainActor.run {
                self.banks = fetchedBanks
                self.stocks = fetchedStocks
                self.watchlist = fetchedWatchlist
            }
        } catch {
            await MainActor.run {
                errorMessage = "資料庫載入失敗: \(error.localizedDescription)"
                showingErrorAlert = true
                print("資料庫載入錯誤: \(error)")
                
                // 加載失敗時，載入本地資料
                loadLocalData()
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
        
        // 同步到資料庫（如果需要）
        Task {
            do {
                // 實際項目中，您可能想要執行批次更新，或只更新已變更的資料
                for bank in banks {
                    try await PostgresService.shared.updateBank(bank)
                }
                
                for stock in stocks {
                    try await PostgresService.shared.updateStock(stock)
                }
                
                // 更新觀察清單可能需要更複雜的邏輯，這裡只是示例
                // 實際中可能需要比較舊值和新值，執行增刪改操作
            } catch {
                print("資料庫同步失敗: \(error.localizedDescription)")
                // 在主線程顯示錯誤（如果需要）
                await MainActor.run {
                    errorMessage = "資料庫同步失敗，但已儲存到本地: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
}
        
    
