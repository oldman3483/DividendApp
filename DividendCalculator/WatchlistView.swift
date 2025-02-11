//
//  WatchlistView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.

import SwiftUI

struct WatchlistView: View {
    // MARK: - Properties
    @State private var selectedList: Int = 0
    @Binding var watchlist: [WatchStock]
    @State private var isEditing = false
    @State private var showingAddList = false
    @State private var newListName = ""
    @State private var showingEditList = false
    @State private var showingDeleteAlert = false
    @State private var listNames: [String] = UserDefaults.standard.stringArray(forKey: "watchlistNames") ?? ["自選清單1"]
    
    // MARK: - Computed Properties
    private var currentListStocks: [WatchStock] {
        watchlist.filter { $0.listNames == selectedList }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 清單選擇器
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(Array(listNames.enumerated()), id: \.element) { index, name in
                                Button(action: {
                                    selectedList = index
                                }) {
                                    Text(name)
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 8)
                                        .background(selectedList == index ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                }
                            }
                            
                            Button(action: {
                                showingAddList = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                        }
                        .padding()
                    }
                    
                    // 股票列表
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if currentListStocks.isEmpty {
                                VStack {
                                    Spacer()
                                    Text("尚無觀察股票")
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 200)
                                    Spacer()
                                }
                            } else {
                                ForEach(currentListStocks) { stock in
                                    WatchStockCard(stock: stock)
                                        .padding(.horizontal)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                deleteStock(stock)
                                            } label: {
                                                Label("刪除", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("觀察清單")
                        .navigationTitleStyle()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // 清單管理選單
                        Menu {
                            Button("重新命名清單") {
                                newListName = listNames[selectedList]
                                showingEditList = true
                            }
                            
                            if listNames.count > 1 {
                                Button("刪除清單", role: .destructive) {
                                    showingDeleteAlert = true
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddList) {
                NavigationStack {
                    Form {
                        Section {
                            TextField("清單名稱", text: $newListName)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .navigationTitle("新增觀察清單")
                    .navigationBarItems(
                        leading: Button("取消") {
                            showingAddList = false
                            newListName = ""
                        },
                        trailing: Button("新增") {
                            addNewList()
                        }
                        .disabled(newListName.isEmpty)
                    )
                }
            }
            .alert("重新命名清單", isPresented: $showingEditList) {
                TextField("新名稱", text: $newListName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                Button("取消", role: .cancel) {
                    newListName = ""
                }
                Button("確定") {
                    renameCurrentList()
                }
            }
            .alert("刪除清單", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("刪除", role: .destructive) {
                    deleteCurrentList()
                }
            } message: {
                Text("確定要刪除「\(listNames[selectedList])」嗎？此操作無法復原。")
            }
        }
    }
    
    // MARK: - Methods
    private func deleteStock(_ stock: WatchStock) {
        watchlist.removeAll { $0.id == stock.id }
    }
    
    private func addNewList() {
        guard !newListName.isEmpty else { return }
        
        var names = listNames
        names.append(newListName)
        listNames = names
        UserDefaults.standard.set(names, forKey: "watchlistNames")
        
        selectedList = names.count - 1
        showingAddList = false
        newListName = ""
    }
    
    private func renameCurrentList() {
        guard !newListName.isEmpty else { return }
        
        var names = listNames
        names[selectedList] = newListName
        listNames = names
        UserDefaults.standard.set(names, forKey: "watchlistNames")
        newListName = ""
    }
    
    private func deleteCurrentList() {
        guard listNames.count > 1 else { return }
        
        // 刪除該清單中的所有股票
        watchlist.removeAll { $0.listNames == selectedList }
        
        // 更新清單名稱
        var names = listNames
        names.remove(at: selectedList)
        listNames = names
        UserDefaults.standard.set(names, forKey: "watchlistNames")
        
        // 更新其他股票的清單索引
        for i in 0..<watchlist.count {
            if watchlist[i].listNames > selectedList {
                let updatedStock = WatchStock(
                    id: watchlist[i].id,
                    symbol: watchlist[i].symbol,
                    name: watchlist[i].name,
                    addedDate: watchlist[i].addedDate,
                    listIndex: watchlist[i].listNames - 1
                )
                watchlist[i] = updatedStock
            }
        }
        
        // 更新選中的清單
        selectedList = max(0, names.count - 1)
    }
}

#Preview {
    NavigationStack {
        WatchlistView(watchlist: .constant([]))
    }
}
