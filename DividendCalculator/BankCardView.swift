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
                .foregroundColor(.white)
            Spacer()
            
            if isEditing {
                Button(action: { onRename(bank) }) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 7)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: Color.white.opacity(0.1),
            radius: 3,
            x: 0,
            y: 2
        )
    }
}
