//
//  WatchlistComponents.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/11.
//

import SwiftUI

// MARK: - 觀察清單頂部選單
struct WatchlistHeader: View {
    let listNames: [String]
    let selectedList: Int
    @Binding var showingAddList: Bool
    let onSelect: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(Array(listNames.enumerated()), id: \.element) { index, name in
                    Button(action: {
                        onSelect(index)
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
        .background(Color.clear)
    }
}

// MARK: - 新增清單表單
struct AddWatchlistForm: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newListName: String
    let onAdd: () -> Void
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 20) {
                        Form {
                            Section {
                                TextField("清單名稱", text: $newListName)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .foregroundColor(.white)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationTitle("新增觀察清單")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                    newListName = ""
                },
                trailing: Button("新增") {
                    onAdd()
                }
                .disabled(newListName.isEmpty)
            )
        }
        .dismissKeyboardOnTap()
    }
}

// MARK: - 觀察清單內容
struct WatchlistContent: View {
    let stocks: [WatchStock]
    let isEditing: Bool
    
    var body: some View {
        List {
            if stocks.isEmpty {
                Text("尚無觀察股票")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(stocks) { stock in
                    WatchStockCard(stock: stock)
                        .listRowInsets(EdgeInsets(top: 6, leading: isEditing ? 0 : 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .onDelete (perform: isEditing ? { _ in } : nil)
                .onMove(perform: isEditing ? { _, _ in } : nil)
            }
        }
        
        .listStyle(PlainListStyle())
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    }
}

