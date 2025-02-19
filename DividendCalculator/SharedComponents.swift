//
//  SharedComponents.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/19.
//

import SwiftUI

// MARK: - 詳細資訊列
struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = .white
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - 交易記錄列
struct TransactionRow: View {
    let transaction: RegularInvestmentTransaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDate(transaction.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                Text(transaction.isExecuted ? "已執行" : "待執行")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(transaction.isExecuted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
            
            HStack(spacing: 20) {
                DetailColumn(title: "投資金額", value: String(format: "$ %.0f", transaction.amount))
                DetailColumn(title: "股價", value: String(format: "$ %.2f", transaction.price))
                DetailColumn(title: "股數", value: "\(transaction.shares)")
            }
        }
    }
}

// MARK: - 詳細資訊欄位
struct DetailColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - 透明 GroupBox 樣式
struct TransparentGroupBox: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.content
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(10)
    }
}

// MARK: - 輔助方法
func formatDate(_ date: Date?) -> String {
    guard let date = date else { return "N/A" }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.string(from: date)
}
