////
////  BannerAdView.swift
////  DividendCalculator
////
////  Created on 2025/5/2.
////
//
//import SwiftUI
//import GoogleMobileAds
//
//struct BannerAdView: UIViewRepresentable {
//    @ObservedObject private var adManager = AdMobManager.shared
//    
//    func makeUIView(context: Context) -> UIView {
//        let containerView = UIView()
//        containerView.backgroundColor = .clear
//        
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let rootViewController = windowScene.windows.first?.rootViewController {
//            
//            let bannerView = adManager.createBannerView(rootViewController: rootViewController)
//            containerView.addSubview(bannerView)
//            
//            // 設置約束
//            bannerView.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//                bannerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
//                bannerView.widthAnchor.constraint(equalToConstant: 320),
//                bannerView.heightAnchor.constraint(equalToConstant: 50)
//            ])
//        }
//        
//        return containerView
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {}
//}
//
//// 方便的 View Modifier
//struct AdBannerModifier: ViewModifier {
//    @ObservedObject private var adManager = AdMobManager.shared
//    
//    func body(content: Content) -> some View {
//        VStack(spacing: 0) {
//            content
//            
//            if adManager.bannerAdLoaded {
//                BannerAdView()
//                    .frame(height: 50)
//                    .background(Color.black.opacity(0.95))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 8)
//                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
//                    )
//                    .padding(.horizontal, 16)
//                    .padding(.bottom, 8)
//                    .transition(.move(edge: .bottom).combined(with: .opacity))
//            }
//        }
//    }
//}
//
//extension View {
//    func withBannerAd() -> some View {
//        modifier(AdBannerModifier())
//    }
//}
