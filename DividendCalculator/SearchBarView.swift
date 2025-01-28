//
//  SearchBarView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/22.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]

    @State private var showingSearchResult = false
    
    // 加入預覽用的初始化器
    init(searchText: Binding<String>, stocks: Binding<[Stock]>,watchlist: Binding<[WatchStock]>) {
        self._searchText = searchText
        self._stocks = stocks
        self._watchlist  = watchlist
    }
    
    
    
    var body: some View {
        HStack {
            TextField("搜尋股票", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle()) // 移除任何可能限制輸入的修飾符
                .autocorrectionDisabled(false)  // 允許自動更正
                .textInputAutocapitalization(.never)  // 不自動大寫
                .keyboardType(.default)  // 使用預設鍵盤
                .onSubmit {
                    if !searchText.isEmpty {
                        showingSearchResult = true
                    }
                }
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .onTapGesture {
                    if !searchText.isEmpty {
                        showingSearchResult = true
                    }
                }
            
        }
        .padding()
        .sheet(isPresented: $showingSearchResult) {
            SearchResultView(
                stocks: $stocks,
                watchlist: $watchlist,
                searchText: searchText
            )
        }
    }
}
                   
