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
}
