//
//  ContentView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.
//

import SwiftUI

struct ContentView: View {
    @State private var stocks: [Stock] = []
    @State private var searchText: String = ""
    @State private var isEditing = false
    let stockService = StockService()
    
    var body: some View {
        ZStack(alignment: .top) {
            SearchBarView(searchText:  $searchText, stocks: $stocks)
                .zIndex(1)
            TabView {
                // 第一頁：投資組合
                NavigationStack {
                    List {
                        ForEach(stocks) { stock in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(stock.symbol)
                                        .font(.headline)
                                    Text(stock.name)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("持股：\(stock.shares)")
                                    Text("股利：\(String(format: "%.2f", stock.dividendPerShare))")
                                    Text("年化：\(String(format: "%.0f", stock.calculateAnnualDividend()))")
                                }
                                .font(.subheadline)
                            }
                        }
                        .onDelete { offsets in
                            stocks.remove(atOffsets: offsets)
                        }
                        .onMove { from, to in
                            stocks.move(fromOffsets: from, toOffset: to)
                        } // 新增移動功能
                    }
                    .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
                    // 控制編輯模式
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("投資組合")
                                .font(.system(size: 40, weight: .bold))
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                isEditing.toggle()
                            }) {
                                Text(isEditing ? "完成" : "編輯")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(.top, 65) // 為搜尋框留出空間
                .tabItem {
                    Label("投資組合", systemImage: "chart.pie.fill")
                }
                // 第二頁觀察清單
                NavigationStack {
                    List {
                        
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("觀察清單")
                                .font(.system(size: 40, weight: .bold))
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                isEditing.toggle()
                            })  {
                                Text(isEditing ? "完成" : "編輯")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(.top, 65)
                .tabItem {
                    Label("觀察清單", systemImage: "star.fill")
                }
                //第三頁投資總覽
                NavigationStack {
                    List {
                        
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("投資總覽")
                                .font(.system(size: 40, weight: .bold))
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                isEditing.toggle()
                            })  {
                                Text(isEditing ? "完成" : "編輯")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(.top, 65)
                .tabItem {
                    Label("投資總覽", systemImage: "chart.bar.fill")
                }
            }
        }
    }
}
    
    
    
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

