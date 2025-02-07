//
//  LoginView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/6.
//


import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.ignoresSafeArea()
            
            // 背景圖案
            Circle()
                .fill(Color.blue.opacity(0.3))
                .blur(radius: 30)
                .offset(x: -50, y: -100)
            
            Circle()
                .fill(Color.purple.opacity(0.2))
                .blur(radius: 30)
                .offset(x: 100, y: 150)
            
            GeometryReader { geometry in
                ScrollView {
                    // 主要內容
                    VStack(spacing: 25) {
                        // 標題區域
                        VStack(spacing: 10) {
                            Text("股息計算器")
                                .navigationTitleStyle()
                                .padding(.top, 60)
                            
                            Text("追蹤您的投資組合")
                                .subtextStyle()
                        }
                        .padding(.bottom, 40)
                        
                        // 登入表單
                        VStack(spacing: 20) {
                            // 電子郵件輸入框
                            GlassTextField(
                                icon: "envelope.fill",
                                placeholder: "電子郵件",
                                text: $email
                            )
                            
                            // 密碼輸入框
                            GlassTextField(
                                icon: "lock.fill",
                                placeholder: "密碼",
                                text: $password,
                                isSecure: true
                            )
                        }
                        
                        // 登入按鈕
                        Button(action: handleLogin) {
                            Text("登入")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue.opacity(0.3))
                                .background(.ultraThinMaterial)
                                .cornerRadius(25)
                        }
                        .padding(.top, 20)
                        
                        // 分隔線
                        HStack {
                            Rectangle()
                                .fill(.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("或")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            Rectangle()
                                .fill(.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical)
                        
                        // 社群登入按鈕
                        HStack(spacing: 20) {
                            GlassSocialButton(icon: "apple.logo", text: "Apple")
                            GlassSocialButton(icon: "g.circle.fill", text: "Google")
                        }
                        
                        Spacer()
                        
                        // 註冊提示
                        HStack(spacing: 4) {
                            Text("新用戶?")
                                .foregroundColor(.gray)
                            Button("建立帳號") {
                                // TODO: 實作註冊功能
                            }
                            .foregroundColor(.white)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 30)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .dismissKeyboardOnTap()
        .alert("登入訊息", isPresented: $isShowingAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleLogin() {
        // TODO: 實作實際的登入邏輯
        guard !email.isEmpty && !password.isEmpty else {
            alertMessage = "請輸入電子郵件和密碼"
            isShowingAlert = true
            return
        }
        
        // 模擬登入成功
        isLoggedIn = true
    }
}

// 玻璃效果輸入框
struct GlassTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

// 社群登入按鈕
struct GlassSocialButton: View {
    let icon: String
    let text: String
    
    var body: some View {
        Button(action: {
            // TODO: 實作社群登入
        }) {
            HStack {
                Image(systemName: icon)
                Text(text)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(Color.white.opacity(0.1))
            .background(.ultraThinMaterial)
            .cornerRadius(22.5)
        }
    }
}



#Preview {
    LoginView()
}
