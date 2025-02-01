//
//  WatchlistView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/20.



import SwiftUI

struct WatchlistView: View {
    @State private var selectedList: Int = 0
    @Binding var watchlist: [WatchStock]
    @Binding var isEditing: Bool
    @State private var showingAddList = false
    @State private var newListName = ""
    @State private var showingEditList = false
    @State private var showingDeleteAlert = false
    @State private var listNames: [String] = UserDefaults.standard.stringArray(forKey: "watchlistNames") ?? ["自選清單1"]
    
    
    var body: some View {
        VStack(spacing: 0) {
           
            // 自選清單切換按鈕
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
                                .foregroundColor(selectedList == index ? .white : .black)
                                .cornerRadius(20)
                        }
                    }
                    
                    // 新增清單按鈕
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
            .background(Color.white)
            
            // 股票列表
            List {
                if watchlist.filter({ $0.listNames == selectedList }).isEmpty {
                    Text("尚無觀察股票")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(watchlist.filter { $0.listNames == selectedList }) { stock in
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(stock.symbol)
                                        .font(.headline)
                                    Text(stock.name)
                                        .foregroundColor(.gray)
                                }
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
                    .navigationTitleStyle()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
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
                }
                .disabled(listNames.count <= 1)
            }
        }
        .sheet(isPresented: $showingAddList) {
            NavigationStack {
                Form {
                    TextField("清單名稱", text: $newListName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
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
    
    // 從觀察清單中移除股票
    private func removeFromWatchlist(at offsets: IndexSet) {
        let currentListStocks = watchlist.filter { $0.listNames == selectedList }
        let toRemove = offsets.map { currentListStocks[$0] }
        watchlist.removeAll { stock in
            toRemove.contains { $0.id == stock.id }
        }
    }
    
    // 新增觀察清單
    private func addNewList() {
        var names = listNames
        names.append(newListName)
        self.listNames = names
        UserDefaults.standard.set(listNames, forKey: "watchlistNames")
        selectedList = names.count - 1
        showingAddList = false
        newListName = ""
    }
    
    // 重新命名當前清單
    private func renameCurrentList() {
        if !newListName.isEmpty {
            var names = listNames
            names[selectedList] = newListName
            self.listNames = names
            UserDefaults.standard.set(listNames, forKey: "watchlistNames")
            newListName = ""
        }
    }
    
    // 刪除當前清單
    private func deleteCurrentList() {
        guard listNames.count > 1 else { return }
        
        // 刪除該清單中的所有股票
        watchlist.removeAll { $0.listNames == selectedList }
        
        // 刪除清單名稱
        var updatedNames = listNames
        updatedNames.remove(at: selectedList)
        self.listNames = updatedNames
        
        // 儲存更新後的清單名稱到 UserDefaults

        UserDefaults.standard.set(listNames, forKey: "watchlistNames")
        UserDefaults.standard.synchronize()
        
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
        
        // 如果刪除的是最後一個清單，選擇前一個清單
        if selectedList >= listNames.count {
            selectedList = max(0, listNames.count - 1)
        }
    }
}

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WatchlistView(
                watchlist: .constant([]),
                isEditing: .constant(false)
            )
        }
    }
}

#Preview {
    NavigationStack {
        WatchlistView(
            watchlist: .constant([
                WatchStock(
                    symbol: "2330",
                    name: "台積電",
                    listIndex: 0
                ),
                WatchStock(
                    symbol: "2317",
                    name: "鴻海",
                    listIndex: 0
                )
            ]),
            isEditing: .constant(false)
        )
    }
}
