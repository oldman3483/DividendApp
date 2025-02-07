//
//  SearchStockView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/7.
//


import SwiftUI

struct SearchStockView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    let bankId: UUID
    @State private var searchText = ""
    @State private var showingSearchResult = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜尋欄
                SearchBarView(
                    searchText: $searchText,
                    stocks: $stocks,
                    watchlist: .constant([]),
                    banks: .constant([]),
                    bankId: bankId
                )
                .padding(.top)
                
                Spacer()
                
                // 提示文字
                if searchText.isEmpty {
                    Text("輸入股票代號或名稱進行搜尋")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }
            }
            .navigationTitle("新增股票")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingSearchResult) {
            SearchResultView(
                stocks: $stocks,
                watchlist: .constant([]),
                banks: .constant([]),
                searchText: searchText,
                bankId: bankId
            )
        }
    }
}

#Preview {
    ContentView()
}
