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

// MARK: - 浮動按鈕基礎元件
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .shadow(radius: 3)
                }
                .padding(.trailing, 30)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - 空狀態視圖
struct EmptyStateView: View {
    var icon: String
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 100)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - 卡片背景修飾器
struct CardBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(white: 0.15))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

extension View {
    func cardBackground() -> some View {
        self.modifier(CardBackgroundModifier())
    }
}

// MARK: - 輔助方法
func formatDate(_ date: Date?) -> String {
    guard let date = date else { return "N/A" }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.string(from: date)
}

func monthName(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM月"
    return formatter.string(from: date)
}

func getFrequencyText(_ frequency: Int) -> String {
    switch frequency {
    case 1: return "年配"
    case 2: return "半年配"
    case 4: return "季配"
    case 12: return "月配"
    default: return "未知"
    }
}
