//
//  BankCardView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/4.
//

import SwiftUI

struct BankCardView: View {
    let bank: Bank
    let isEditing: Bool
    let onRename: (Bank) -> Void
    
    var body: some View {
        HStack {
            Text(bank.name)
                .heading3Style()
                .padding(.vertical, 10)
                .padding(.horizontal, isEditing ? 8 : 16)
                .foregroundColor(.black)
            Spacer()
            
            if isEditing {
                Button(action: { onRename(bank) }) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.white)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 3,
            x: 0,
            y: 2
        )
    }
}

#Preview {
    // 創建一個示例銀行用於預覽
    let sampleBank = Bank(name: "測試銀行")
    
    return VStack(spacing: 20) {
        // 非編輯模式的預覽
        BankCardView(
            bank: sampleBank,
            isEditing: false,
            onRename: { _ in }
        )
        
        // 編輯模式的預覽
        BankCardView(
            bank: sampleBank,
            isEditing: true,
            onRename: { _ in }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
