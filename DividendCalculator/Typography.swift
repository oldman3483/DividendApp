//
//  Typography.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/1.
//


import SwiftUI

// MARK: - 字型大小定義
struct FontSize {
    // 標題
    static let navigationTitle: CGFloat = 28
    
    // 主要內容
    static let heading1: CGFloat = 24
    static let heading2: CGFloat = 20
    static let heading3: CGFloat = 18
    
    // 一般文字
    static let body: CGFloat = 16
    static let subtext: CGFloat = 14
    static let caption: CGFloat = 12
}

// MARK: - 自定義字型修飾符
extension View {
    func navigationTitleStyle() -> some View {
        self.font(.system(size: FontSize.navigationTitle, weight: .bold))
    }
    
    func heading1Style() -> some View {
        self.font(.system(size: FontSize.heading1, weight: .semibold))

    }
    
    func heading2Style() -> some View {
        self.font(.system(size: FontSize.heading2, weight: .semibold))

    }
    
    func heading3Style() -> some View {
        self.font(.system(size: FontSize.heading3, weight: .medium))

    }
    
    func bodyStyle() -> some View {
        self.font(.system(size: FontSize.body))

    }
    
    func subtextStyle() -> some View {
        self.font(.system(size: FontSize.subtext))

    }
    
    func captionStyle() -> some View {
        self.font(.system(size: FontSize.caption))

    }
}
