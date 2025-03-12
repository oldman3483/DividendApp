//
//  WatchStockCard.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/11.
//

import SwiftUI
import Charts

struct WatchStockCard: View {
    let stock: WatchStock
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]
    @Binding var banks: [Bank]
    let stockService = LocalStockService()
    
    @State private var closingPrice: Double = 0.0
    @State private var previousClosingPrice: Double = 0.0
    @State private var isLoading = true
    @Environment(\.editMode) private var editMode
    
    private var priceChange: Double {
        closingPrice - previousClosingPrice
    }
    
    private var changePercentage: Double {
        guard previousClosingPrice != 0 else { return 0 }
        return (priceChange / previousClosingPrice) * 100
    }
    
    private var isEditing: Bool {
        editMode?.wrappedValue.isEditing ?? false
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if isEditing {
                Color.clear
                    .frame(width: 8)
            }
            
            // 左側：股票名稱和代號
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white)
                
                Text(stock.symbol)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .frame(width: 70, alignment: .leading)
            
            Spacer()
            
            // 右側：價格區域
            if !isLoading {
                HStack(alignment: .center, spacing: 8) {
                    Text(String(format: "%.2f", closingPrice))
                        .heading3Style()
                        .frame(width: 70, alignment: .trailing)
                        .foregroundStyle(priceChange >= 0 ? Color.red : Color.green)
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text(String(format: "%+.2f", priceChange))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(priceChange >= 0 ? Color.red : Color.green)
                            )
                            .frame(minWidth: 70)
                        
                        Text(String(format: "%+.2f%%", changePercentage))
                            .font(.system(size: 12))
                            .foregroundStyle(priceChange >= 0 ? Color.red : Color.green)
                    }
                }
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .frame(height: 40)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .task {
            await loadClosingPrices()
        }
    }
    
    private func loadClosingPrices() async {
        isLoading = true
        
        let calendar = Calendar.current
        
        // 獲取前一天日期
        guard let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        // 獲取前兩天日期
        guard let twoDaysAgoDate = calendar.date(byAdding: .day, value: -2, to: Date()) else {
            await MainActor.run {
                isLoading = false
            }
            return
        }
        
        // 獲取前一日收盤價
        if let yesterdayPrice = await stockService.getStockPrice(symbol: stock.symbol, date: yesterdayDate) {
            await MainActor.run {
                closingPrice = yesterdayPrice
            }
        }
        
        // 獲取前兩日收盤價
        if let twoDaysAgoPrice = await stockService.getStockPrice(symbol: stock.symbol, date: twoDaysAgoDate) {
            await MainActor.run {
                previousClosingPrice = twoDaysAgoPrice
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}
