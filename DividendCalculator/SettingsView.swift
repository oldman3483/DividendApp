//
//  SettingsView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/7.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var showingLogoutAlert = false
    @State private var showingClearDataAlert = false
    
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
                        Text("user@example.com")
                            .foregroundColor(.gray)
                    }
                } header: {
                    Text("帳戶資訊")
                }
                
                // 應用程式設定
                Section {
                    Toggle(isOn: .constant(true)) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                            Text("接收股利通知")
                        }
                    }
                    
                    Toggle(isOn: .constant(true)) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.blue)
                            Text("股價變動提醒")
                        }
                    }
                } header: {
                    Text("通知設定")
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
        .padding(.top, 65)
        .alert("登出確認", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("登出", role: .destructive) {
                isLoggedIn = false
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
    
    private func clearAllData() {
        // 清除 UserDefaults 中的所有資料
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
}

#Preview {
    SettingsView()
}
