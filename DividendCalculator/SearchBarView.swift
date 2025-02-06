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
    let bankId: UUID?

    @State private var showingSearchResult = false
    
    // 加入預覽用的初始化器
    init(searchText: Binding<String>, stocks: Binding<[Stock]>,watchlist: Binding<[WatchStock]>, bankId: UUID) {
        self._searchText = searchText
        self._stocks = stocks
        self._watchlist  = watchlist
        self.bankId = bankId
    }
    
    
    
    var body: some View {
        HStack {
            TextField("搜尋股票", text: $searchText)
                .textFieldStyle(CustomTextFieldStyle()) // 移除任何可能限制輸入的修飾符
                .foregroundColor(.white)  // 文字顏色改為白色
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
                searchText: searchText,
                bankId: bankId ?? UUID()
            )
        }
    }
}
                   
// 自定義 TextField 樣式
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 8)
            .padding(.horizontal, 18)
            .background(Color.black.opacity(0.3))  // 與銀行卡片相同的背景色
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

#Preview {
    ContentView()
}
