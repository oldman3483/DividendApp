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
    @Binding var stocks: [Stock]
    @Binding var banks: [Bank]
    @State private var isEditing = false
    @State private var showingAddList = false
    @State private var newListName = ""
    @State private var showingEditList = false
    @State private var showingDeleteAlert = false
    @State private var listNames: [String] = UserDefaults.standard.stringArray(forKey: "watchlistNames") ?? ["自選清單1"]
    
    // MARK: - Computed Properties
    private var currentListStocks: [WatchStock] {
        guard selectedList < listNames.count else { return [] }
        return watchlist.filter { $0.listName == listNames[selectedList] }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 清單選擇器
            WatchlistHeader(
                listNames: listNames,
                selectedList: selectedList,
                showingAddList: $showingAddList,
                onSelect: { selectedList = $0 }
            )
            
            // 股票列表
            List {
                if currentListStocks.isEmpty {
                    Text("尚無觀察股票")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(currentListStocks) { stock in
                        WatchStockCard(
                            stock: stock,
                            stocks: $stocks,
                            watchlist: $watchlist,
                            banks: $banks
                        )
                            .listRowInsets(EdgeInsets(
                                top: 6,
                                leading: isEditing ? 0 : 16,
                                bottom: 6,
                                trailing: 16
                            ))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete (perform: isEditing ? deleteStocks : nil)
                    .onMove { from, to in
                        moveStocks(from: from, to: to)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("觀察清單")
                    .navigationTitleStyle()
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    // 編輯按鈕
                    if !currentListStocks.isEmpty {
                        Button(isEditing ? "完成" : "編輯") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                    }
                    
                    // 清單管理選單
                    if !isEditing {
                        Menu {
                            Button("重新命名", action: {
                                newListName = listNames[selectedList]
                                showingEditList = true
                            })
                            Button("刪除清單", role: .destructive, action: {
                                showingDeleteAlert = true
                            })
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.white)
                        }
                        .disabled(listNames.count <= 1)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddList) {
            AddWatchlistForm(
                newListName: $newListName,
                onAdd: addNewList
            )
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
    
    // MARK: - 方法
    private func addNewList() {
        guard !newListName.isEmpty else { return }
        
        listNames.append(newListName)
        UserDefaults.standard.set(listNames, forKey: "watchlistNames")
        selectedList = listNames.count - 1
        
        showingAddList = false
        newListName = ""
    }
    
    private func renameCurrentList() {
        guard !newListName.isEmpty else { return }
        
        // 重命名前先找出舊名稱
        let oldListName = listNames[selectedList]
        
        // 更新清單名稱
        listNames[selectedList] = newListName
        UserDefaults.standard.set(listNames, forKey: "watchlistNames")
        
        // 更新這個清單的所有股票的 listName
        watchlist = watchlist.map { stock in
            if stock.listName == oldListName {
                return WatchStock(
                    id: stock.id,
                    symbol: stock.symbol,
                    name: stock.name,
                    addedDate: stock.addedDate,
                    listName: newListName
                )
            }
            return stock
        }
        
        newListName = ""
    }
    
    private func deleteCurrentList() {
        guard listNames.count > 1 else { return }
        
        // 刪除當前清單的股票
        watchlist.removeAll { $0.listName == listNames[selectedList] }
        
        // 移除清單
        listNames.remove(at: selectedList)
        UserDefaults.standard.set(listNames, forKey: "watchlistNames")
        
        // 調整選中的清單
        selectedList = max(0, min(selectedList, listNames.count - 1))
    }
    
    private func deleteStocks(at indexSet: IndexSet) {
        let stocksToDelete = indexSet.map { currentListStocks[$0] }
        watchlist.removeAll { stock in
            stocksToDelete.contains { $0.id == stock.id }
        }
    }
    
    private func moveStocks(from source: IndexSet, to destination: Int) {
        var currentStocks = currentListStocks
        currentStocks.move(fromOffsets: source, toOffset: destination)
        
        // 更新 watchlist 中對應的股票順序
        let updatedStockIds = currentStocks.map { $0.id }
        watchlist = watchlist.sorted { stock1, stock2 in
            if stock1.listName == listNames[selectedList] && stock2.listName == listNames[selectedList] {
                guard let index1 = updatedStockIds.firstIndex(of: stock1.id),
                      let index2 = updatedStockIds.firstIndex(of: stock2.id) else {
                    return false
                }
                return index1 < index2
            }
            return true
        }
    }
}
