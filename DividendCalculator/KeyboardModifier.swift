//
//  KeyboardModifier.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/6.
//

import SwiftUI
import UIKit

struct DismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        endEditing()
                    }
            )
    }
    
    private func endEditing() {
        // 取得當前的 windows scene
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        
        // 結束編輯狀態
        window?.endEditing(true)
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardModifier())
    }
}
