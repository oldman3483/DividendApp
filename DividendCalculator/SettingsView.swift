//
//  SettingsView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/7.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userId") private var userId = ""
    @AppStorage("loginMethod") private var loginMethod = ""
    @AppStorage("dividendNotification") private var dividendNotification = true
    @AppStorage("priceNotification") private var priceNotification = true
    @AppStorage("offlineMode") private var offlineMode = false
    @State private var showingLogoutAlert = false
    @State private var showingClearDataAlert = false
    @State private var showTestResult = false
    @State private var testResultMessage = ""
    @State private var isTestingDb = false
    
    // 環境變數來獲取網絡監視器狀態
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    
    var body: some View {
        NavigationStack {
            List {
                // 帳戶設定
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        Text("使用者帳號")
                        Spacer()
                        Text(loginMethod == "apple" ? "Apple ID 登入" :
                             loginMethod == "guest" ? "訪客登入" : "未登入")
                            .foregroundColor(.gray)
                    }
                } header: {
                    Text("帳戶資訊")
                }
                
                // 應用程式設定
                Section {
                    Toggle(isOn: $dividendNotification) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                            Text("接收股利通知")
                        }
                    }
                    
                    Toggle(isOn: $priceNotification) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.blue)
                            Text("股價變動提醒")
                        }
                    }
                    // 離線模式設置
                    Toggle(isOn: $offlineMode) {
                        HStack {
                            Image(systemName: offlineMode ? "wifi.slash" : "wifi")
                                .foregroundColor(.blue)
                            Text("離線模式")
                        }
                    }
                    .onChange(of: offlineMode) { oldValue, newValue in
                        // 當用戶手動切換離線模式時，通知應用的其他部分
                        NotificationCenter.default.post(name: Notification.Name("OfflineModeChanged"), object: nil, userInfo: ["isOffline": newValue])
                        
                        if newValue {
                            // 進入離線模式時的處理邏輯
                            // 例如：可以顯示提示，保存當前數據狀態等
                        } else if networkMonitor.isConnected {
                            // 退出離線模式且有網絡連接時，嘗試同步數據
                            Task {
                                await synchronizeDataWithServer()
                            }
                        }
                    }
                    // 在離線模式啟用時顯示額外的信息
                    if offlineMode {
                        HStack {
                            Text("離線模式下，部分功能可能不可用")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 30)
                            Spacer()
                        }
                    }
                    // 資料庫連接測試按鈕 (僅在非離線模式下顯示)
                    if !offlineMode {
                        Button(action: {
                            testDatabaseConnection()
                        }) {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundColor(.blue)
                                Text("測試資料庫連接")
                            }
                        }
                    }
                    Button(action: {
                        checkBackendStatus()
                    }) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.blue)
                            Text("檢查後端服務狀態")
                        }
                    }
                    
                } header: {
                    Text("通知與連線設定")
                }
                
                // 資料管理
                Section {
                    Button(action: { showingClearDataAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("清除所有資料")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("登出")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("資料管理")
                }
                
                // 關於
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                } header: {
                    Text("關於")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("更多設定")
                        .navigationTitleStyle()
                }
            }
        }
        .padding(.top, 30)
        .alert("登出確認", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("登出", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("確定要登出嗎？")
        }
        .alert("清除資料確認", isPresented: $showingClearDataAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("確定要清除所有資料嗎？此操作無法復原。")
        }
        .alert("資料庫連接測試結果", isPresented: $showTestResult) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(testResultMessage)
        }
        .overlay {
            if isTestingDb {
                ProgressView("測試中...")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
    }
    
    private func checkBackendStatus() {
        isTestingDb = true
        testResultMessage = "正在檢查後端服務狀態..."
        showTestResult = true
        
        let baseURL = "https://postgres-1-148949302162.asia-east1.run.app"
        
        let networkMonitor = NetworkMonitor()
        networkMonitor.checkServerConnection(urlString: baseURL) { isConnected, message in
            DispatchQueue.main.async {
                if isConnected {
                    testResultMessage = "後端服務正常響應，您可以嘗試連接資料庫"
                } else {
                    testResultMessage = "無法連接到後端服務: \(message ?? "未知錯誤")\n\n請確認服務器地址正確且服務正在運行"
                }
                isTestingDb = false
            }
        }
    }
    
    // 添加與服務器同步數據的方法
    private func synchronizeDataWithServer() async {
        // 在這裡實現與服務器同步數據的邏輯
        // 可以觸發 ContentView 中的數據更新方法
        // 例如通過 NotificationCenter 發送通知
        NotificationCenter.default.post(name: Notification.Name("SyncWithServer"), object: nil)
    }
    
    private func handleLogout() {
        // 清除用戶狀態
        userId = ""
        loginMethod = ""
        isLoggedIn = false
        
        print("使用者已登出")
    }
    
    private func clearAllData() {
        if let bundleID = Bundle.main.bundleIdentifier {
            // 清除 UserDefaults 數據
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            
            // 重置通知設定
            dividendNotification = true
            priceNotification = true
            
            // 登出用戶
            isLoggedIn = false
            userId = ""
            loginMethod = ""
            
            // 特別確保清除我的規劃相關的所有數據
            UserDefaults.standard.removeObject(forKey: "targetAmount")
            UserDefaults.standard.removeObject(forKey: "currentAmount")
            UserDefaults.standard.removeObject(forKey: "targetYear")
            UserDefaults.standard.removeObject(forKey: "selectedSymbol")
            UserDefaults.standard.removeObject(forKey: "goalAmount")
            UserDefaults.standard.removeObject(forKey: "investmentYears")
            UserDefaults.standard.removeObject(forKey: "investmentFrequency")
            UserDefaults.standard.removeObject(forKey: "planningData")
            
            // 發送通知以通知其他視圖重置所有數據
            NotificationCenter.default.post(name: Notification.Name("ClearAllData"), object: nil)
        }
    }
    
    // 資料庫連接測試方法
    private func testDatabaseConnection() {
        isTestingDb = true
        
        Task {
                do {
                    print("開始測試資料庫連接...")
                    
                    // 先檢查網絡連接
                    if !NetworkMonitor().isConnected {
                        throw APIError(code: 1, message: "網絡未連接，請檢查您的網絡設置並確保離線模式已關閉")
                    }
                    
                    // 打印目標URL - 修改這裡
                    let baseURL = "https://dividend-app-148949302162.asia-east1.run.app"
                    let path = "get_t_0050_data"
                    print("目標URL: \(baseURL)/\(path)")
                    
                    let dividendResponse = try await APIService.shared.getDividendData(symbol: "0050")
                
                var resultMessage = ""
                
                // 檢查資料是否成功獲取
                    if dividendResponse.success {
                        resultMessage = "連接成功！共獲取 \(dividendResponse.data.count) 筆0050的股利記錄"
                        print(resultMessage)
                        
                        // 打印第一筆資料作為示例
                        if let firstRecord = dividendResponse.data.first {
                            let details = """
                            第一筆資料:
                            日期: \(firstRecord.date)
                            股利年度: \(firstRecord.dividendYear)
                            股利期間: \(firstRecord.dividendPeriod)
                            現金股利: \(firstRecord.totalCashDividend)
                            除息日: \(firstRecord.exDividendDate)
                            """
                            print(details)
                            resultMessage += "\n\n共獲取 \(dividendResponse.data.count) 條記錄"
                        }
                    } else {
                        resultMessage = "資料獲取失敗: \(dividendResponse.message ?? "未知錯誤")"
                        print(resultMessage)
                    }
                
                // 更新UI顯示測試結果
                await MainActor.run {
                    testResultMessage = resultMessage
                    showTestResult = true
                    isTestingDb = false
                }
            } catch {
                var errorMessage = "測試失敗: \(error.localizedDescription)"
                
                // 處理不同類型的錯誤
                if let apiError = error as? APIError {
                    errorMessage = "API錯誤: 代碼 \(apiError.code), 訊息: \(apiError.message)"
                    
                    // 提供故障排除建議
                    switch apiError.code {
                    case 1:
                        errorMessage += "\n\n請檢查您的網絡連接並確保離線模式已關閉"
                    case 3:
                        errorMessage += "\n\n請求超時，服務器可能無法回應，請稍後再試"
                    case 4:
                        errorMessage += "\n\n無法連接到服務器，請確認服務器地址正確且服務器正在運行"
                    case 400...499:
                        errorMessage += "\n\n請求錯誤，請檢查API參數設置"
                    case 500...599:
                        errorMessage += "\n\n服務器內部錯誤，請聯繫後端開發人員"
                    default:
                        errorMessage += "\n\n請嘗試重新啟動應用程序或檢查API配置"
                    }
                } else if let urlError = error as? URLError {
                    errorMessage = "連接錯誤: \(urlError.localizedDescription)"
                    
                    switch urlError.code {
                    case .timedOut:
                        errorMessage += "\n\n連接超時，請檢查網絡狀態或服務器回應時間"
                    case .notConnectedToInternet:
                        errorMessage += "\n\n網絡未連接，請檢查網絡設置"
                    case .cannotFindHost, .cannotConnectToHost:
                        errorMessage += "\n\n無法連接到服務器，請檢查服務器地址是否正確"
                    default:
                        errorMessage += "\n\n請檢查您的網絡連接"
                    }
                }
                
                print(errorMessage)
                
                // 更新UI顯示錯誤信息
                await MainActor.run {
                    testResultMessage = errorMessage
                    showTestResult = true
                    isTestingDb = false
                }
            }
        }
    }
}
