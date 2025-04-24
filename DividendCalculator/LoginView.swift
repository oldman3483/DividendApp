//
//  LoginView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/6.
//


import SwiftUI
import AuthenticationServices // 新增 Apple Sign In
import Firebase

struct LoginView: View {
    @State private var isShowingAlert = false
    @State private var errorMessage = ""
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userId") private var userId = ""
    @AppStorage("loginMethod") private var loginMethod = ""
    
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
                        
                        // 使用 Apple ID 登入按鈕
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: configureAppleSignIn,
                            onCompletion: handleAppleSignInResult
                        )
                        .frame(height: 50)
                        .cornerRadius(8)
                        .padding(.horizontal, 30)
                        
                        // 訪客登入按鈕
                        Button(action: signInAsGuest) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                Text("以訪客身份登入")
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.5))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("登入錯誤"),
                message: Text(errorMessage),
                dismissButton: .default(Text("確定"))
            )
        }
    }
    
    // Apple 登入設置
    private func configureAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        request.nonce = randomNonceString() // 添加 nonce 增加安全性
    }
    
    // 處理 Apple 登入結果
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // 更安全的用戶識別方式
                guard let identityToken = appleIDCredential.identityToken,
                      let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                    errorMessage = "無法獲取身份驗證令牌"
                    isShowingAlert = true
                    return
                }
                
                // 使用更穩定的方式獲取用戶 ID
                let userId = appleIDCredential.user
                
                // 保存用戶資訊
                self.userId = userId
                self.loginMethod = "apple"
                self.isLoggedIn = true
                
                print("成功使用 Apple ID 登入，用戶 ID：\(userId)")
            }
        case .failure(let error):
            handleSignInError(error)
        }
    }
    private func handleSignInError(_ error: Error) {
        let nsError = error as NSError
        
        switch nsError.code {
        case ASAuthorizationError.canceled.rawValue:
            errorMessage = "登入已取消"
        case ASAuthorizationError.failed.rawValue:
            errorMessage = "登入失敗，請檢查網絡連接"
        case ASAuthorizationError.invalidResponse.rawValue:
            errorMessage = "登入返回無效的回應"
        case ASAuthorizationError.notHandled.rawValue:
            errorMessage = "登入未成功處理"
        default:
            errorMessage = "未知的登入錯誤：\(error.localizedDescription)"
        }
        
        print("Apple 登入錯誤：\(errorMessage)")
        isShowingAlert = true
        isLoggedIn = false
    }
    
    // 訪客登入
    private func signInAsGuest() {
        // 為訪客生成隨機 ID
        let guestId = "guest_\(UUID().uuidString)"
        
        // 保存用戶 ID 和登入方法
        self.userId = guestId
        self.loginMethod = "guest"
        self.isLoggedIn = true
        
        print("已以訪客身份登入，訪客 ID：\(guestId)")
    }
    // 生成 nonce 的輔助方法
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}

// Apple 登入按鈕
struct SignInWithAppleButton: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let onRequest: ((ASAuthorizationAppleIDRequest) -> Void)
    let onCompletion: ((Result<ASAuthorization, Error>) -> Void)
    
    init(_ type: ASAuthorizationAppleIDButton.ButtonType, onRequest: @escaping ((ASAuthorizationAppleIDRequest) -> Void), onCompletion: @escaping ((Result<ASAuthorization, Error>) -> Void)) {
        self.type = type
        self.onRequest = onRequest
        self.onCompletion = onCompletion
    }
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: .white)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let parent: SignInWithAppleButton
        
        init(_ parent: SignInWithAppleButton) {
            self.parent = parent
        }
        
        @objc func buttonTapped() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            parent.onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            
            // 重要：在主線程中執行
            DispatchQueue.main.async {
                controller.performRequests()
            }
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            // 使用 UIWindowScene 獲取當前的 window
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("Invalid window")
            }
            return window
        }
    }
}
