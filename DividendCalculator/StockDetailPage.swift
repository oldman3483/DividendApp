//
//  StockDetailPage.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/12.
//

import SwiftUI
import Charts

struct StockDetailPage: View {
    let symbol: String
    let name: String
    @State private var selectedTab = "行情"
    @State private var selectedTimeRange = "當日"
    @State private var stockPrice: Double = 0.0
    @State private var priceChange: Double = 0.0
    @State private var percentageChange: Double = 0.0
    @State private var volume: Int = 0
    @State private var isLoading = true
    
    private let tabs = ["行情", "K線", "評析", "新聞", "籌碼", "基本", "財務"]
    private let timeRanges = ["當日", "五日", "近月", "三月", "六月", "一年", "五年"]
    private let stockService = LocalStockService()
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // 標題區域
                    headerSection
                    
                    // 價格資訊區域
                    priceSection
                    
                    // 分頁選擇器
                    tabSection
                    
                    // 時間區間選擇器
                    timeRangeSection
                    
                    // K線圖
                    chartSection
                }
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
        }
        .task {
            await loadStockData()
        }
    }
    
    // MARK: - UI Components
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(symbol)
                    .font(.title)
                    .bold()
                Text(name)
                    .font(.title2)
                    .foregroundColor(.gray)
                Spacer()
            }
            
//            HStack {
//                Text("加權指數")
//                    .foregroundColor(.gray)
//                Text("23297.52")
//                    .foregroundColor(.red)
//                Text("▼")
//                    .foregroundColor(.red)
//                Text("-86.53")
//                    .foregroundColor(.red)
//                Spacer()
//            }
            .font(.subheadline)
        }
        .padding()
    }
    
    private var priceSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(String(format: "%.2f", stockPrice))")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(priceChange >= 0 ? .red : .green)
                
                HStack(spacing: 4) {
                    Text("\(priceChange >= 0 ? "+" : "")\(String(format: "%.2f", priceChange))")
                    Text("(\(String(format: "%.2f", percentageChange))%)")
                }
                .font(.title3)
                .foregroundColor(priceChange >= 0 ? .red : .green)
                
                Spacer()
            }
            
            HStack {
                GridRow("最高", value: "1115.00", color: .red)
                GridRow("最低", value: "1100.00", color: .green)
                GridRow("總量", value: "\(volume)", color: .white)
            }
        }
        .padding(.horizontal)
    }
    
    private var tabSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack {
                            Text(tab)
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                            Rectangle()
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color.black)
    }
    
    private var timeRangeSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(timeRanges, id: \.self) { range in
                    Button(action: { selectedTimeRange = range }) {
                        Text(range)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTimeRange == range ? Color.orange : Color.clear)
                            .cornerRadius(15)
                            .foregroundColor(selectedTimeRange == range ? .white : .gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var chartSection: some View {
        VStack {
            Chart {
                LineMark(
                    x: .value("Time", Date()),
                    y: .value("Price", stockPrice)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 300)
            .padding()
        }
    }
    
    // MARK: - Helper Views
    private struct GridRow: View {
        let title: String
        let value: String
        let color: Color
        
        init(_ title: String, value: String, color: Color) {
            self.title = title
            self.value = value
            self.color = color
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.body)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Data Loading
    private func loadStockData() async {
        if let currentPrice = await stockService.getStockPrice(symbol: symbol, date: Date()) {
            let calendar = Calendar.current
            if let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: Date()),
               let yesterdayPrice = await stockService.getStockPrice(symbol: symbol, date: yesterdayDate) {
                
                await MainActor.run {
                    stockPrice = currentPrice
                    priceChange = currentPrice - yesterdayPrice
                    percentageChange = (priceChange / yesterdayPrice) * 100
                    volume = Int.random(in: 10000...50000)
                    isLoading = false
                }
            }
        }
    }
}
