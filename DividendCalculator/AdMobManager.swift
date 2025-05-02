////
////  AdMobManager.swift
////  DividendCalculator
////
////  Created on 2025/5/2.
////
//
//import SwiftUI
//import GoogleMobileAds
//
//class AdMobManager: NSObject, ObservableObject {
//    static let shared = AdMobManager()
//    
//    // 廣告狀態
//    @Published var bannerAdLoaded = false
//    @Published var interstitialAdLoaded = false
//    
//    // 插頁式廣告計數器和時間控制
//    private var stockDetailViewCount = 0
//    private var lastInterstitialTime: Date?
//    private let minimumInterstitialInterval: TimeInterval = 300 // 5分鐘
//    private let stockDetailThreshold = 4 // 查看4個股票後顯示廣告
//    
//    // 廣告ID (請替換為您的實際ID)
//    private let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716" // 測試ID
//    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // 測試ID
//    
//    // 廣告物件
//    var bannerView: GADBannerView?
//    private var interstitialAd: GADInterstitialAd?
//    
//    override init() {
//        super.init()
//        initializeMobileAds()
//    }
//    
//    // 初始化 AdMob
//    private func initializeMobileAds() {
//        GADMobileAds.sharedInstance().start { status in
//            print("AdMob SDK 初始化完成")
//            // 預載入插頁式廣告
//            self.loadInterstitialAd()
//        }
//    }
//    
//    // MARK: - Banner 廣告方法
//    
//    func createBannerView(rootViewController: UIViewController) -> GADBannerView {
//        let banner = GADBannerView(adSize: GADAdSizeBanner)
//        banner.adUnitID = bannerAdUnitID
//        banner.rootViewController = rootViewController
//        banner.delegate = self
//        banner.load(GADRequest())
//        
//        // 深色主題樣式
//        banner.backgroundColor = UIColor(white: 0.1, alpha: 0.95)
//        banner.layer.cornerRadius = 8
//        banner.layer.borderWidth = 1
//        banner.layer.borderColor = UIColor(white: 1, alpha: 0.1).cgColor
//        
//        self.bannerView = banner
//        return banner
//    }
//    
//    // MARK: - Interstitial 廣告方法
//    
//    func loadInterstitialAd() {
//        GADInterstitialAd.load(withAdUnitID: interstitialAdUnitID,
//                               request: GADRequest()) { [weak self] ad, error in
//            if let error = error {
//                print("插頁式廣告載入失敗: \(error.localizedDescription)")
//                return
//            }
//            
//            self?.interstitialAd = ad
//            self?.interstitialAd?.fullScreenContentDelegate = self
//            self?.interstitialAdLoaded = true
//            print("插頁式廣告載入成功")
//        }
//    }
//    
//    // 顯示插頁式廣告
//    func showInterstitialAd(from viewController: UIViewController) {
//        guard let interstitialAd = interstitialAd,
//              canShowInterstitialAd() else {
//            return
//        }
//        
//        interstitialAd.present(fromRootViewController: viewController)
//        lastInterstitialTime = Date()
//        
//        // 重新載入下一個插頁式廣告
//        loadInterstitialAd()
//    }
//    
//    // 檢查是否可以顯示插頁式廣告
//    private func canShowInterstitialAd() -> Bool {
//        // 檢查時間間隔
//        if let lastTime = lastInterstitialTime {
//            let timeSinceLastAd = Date().timeIntervalSince(lastTime)
//            if timeSinceLastAd < minimumInterstitialInterval {
//                return false
//            }
//        }
//        
//        return interstitialAdLoaded
//    }
//    
//    // 追蹤股票詳情頁查看次數
//    func trackStockDetailView() {
//        stockDetailViewCount += 1
//        
//        if stockDetailViewCount >= stockDetailThreshold {
//            // 重置計數器
//            stockDetailViewCount = 0
//            
//            // 嘗試顯示插頁式廣告
//            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//               let rootViewController = windowScene.windows.first?.rootViewController {
//                showInterstitialAd(from: rootViewController)
//            }
//        }
//    }
//    
//    // 報表生成完成時調用
//    func reportGenerationCompleted() {
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let rootViewController = windowScene.windows.first?.rootViewController {
//            showInterstitialAd(from: rootViewController)
//        }
//    }
//}
//
//// MARK: - GADBannerViewDelegate
//extension AdMobManager: GADBannerViewDelegate {
//    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
//        print("Banner 廣告載入成功")
//        bannerAdLoaded = true
//    }
//    
//    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
//        print("Banner 廣告載入失敗: \(error.localizedDescription)")
//        bannerAdLoaded = false
//    }
//}
//
//// MARK: - GADFullScreenContentDelegate
//extension AdMobManager: GADFullScreenContentDelegate {
//    func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
//        print("插頁式廣告已顯示")
//    }
//    
//    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
//        print("插頁式廣告顯示失敗: \(error.localizedDescription)")
//        interstitialAdLoaded = false
//    }
//    
//    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
//        print("插頁式廣告已關閉")
//        interstitialAdLoaded = false
//    }
//}
