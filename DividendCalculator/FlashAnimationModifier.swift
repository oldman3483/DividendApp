//
//  FlashAnimationModifier.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/9.
//

import SwiftUI

struct FlashAnimation: ViewModifier {
    let isPositive: Bool
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .background(
                isAnimating ? (isPositive ? Color.green : Color.red).opacity(0.2) : Color.clear
            )
            .onChange(of: isAnimating) { oldValue, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isAnimating = false
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isAnimating)
    }
    
    func flash() {
        isAnimating = true
    }
}

extension View {
    func flashAnimation(isPositive: Bool = true) -> some View {
        modifier(FlashAnimation(isPositive: isPositive))
    }
}
