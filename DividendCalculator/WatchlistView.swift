//
//  WatchlistView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import SwiftUI

struct WatchlistView: View {
    @State private var watchlist: [WatchStock] = []
    let stockService: StockServiceProtocol
    
    struct WatchStock: Identifiable {
        let id = UUID()
        let symbol: String
        let name: String
        let addedDate: Date
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(watchlist) { stock in
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
            .navigationTitle("觀察清單")
            .toolbar {
                Button(action: {
                    // 之後加入新增觀察股票的功能
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private func removeFromWatchlist(at offsets: IndexSet) {
        watchlist.remove(atOffsets: offsets)
    }
}
