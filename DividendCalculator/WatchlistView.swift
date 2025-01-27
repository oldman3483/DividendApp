//
//  WatchlistView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//
import SwiftUI

struct WatchlistView: View {
    @State private var selectedList: Int = 1 // 目前選擇的清單編號
    @Binding var watchlist: [WatchStock]  // 修改這裡，使用 Binding
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack {
            // 自選清單切換按鈕
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(1...5, id: \.self) { index in
                        Button(action: {
                            selectedList = index
                        }) {
                            Text("自選清單\(index)")
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .background(selectedList == index ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedList == index ? .white : .black)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding()
            }
            
            List {
                Section {
                    ForEach(watchlist.filter { $0.listIndex == selectedList }) { stock in
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(stock.symbol)
                                        .font(.headline)
                                    Text(stock.name)
                                        .foregroundColor(.gray)
                                }
                                Text("加入時間：\(stock.addedDate.formatted(.dateTime.month().day()))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: removeFromWatchlist)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("觀察清單")
                    .font(.system(size: 40, weight: .bold))
            }
        }
    }
    
    func removeFromWatchlist(at offsets: IndexSet) {
        // 先獲取當前清單的股票
        let currentListStocks = watchlist.filter { $0.listIndex == selectedList }
        // 找出要刪除的股票的索引
        let toRemove = offsets.map { currentListStocks[$0] }
        // 從 watchlist 中移除這些股票
        watchlist.removeAll { stock in
            toRemove.contains { $0.id == stock.id }
        }
    }
}
