//
//   BankListView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/31.
//

import SwiftUI

// MARK: - 銀行卡片視圖
struct BankCardView: View {
    let bank: Bank
    let isEditing: Bool
    let onRename: () -> Void

    
    var body: some View {
        HStack {
            Text(bank.name)
                .heading3Style()
                .padding(.vertical, 10)
                .padding(.horizontal, isEditing ? 8 : 16)
                .foregroundColor(.black)
            Spacer()
            
            if isEditing {
                Button(action: onRename) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.white)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 3,
            x: 0,
            y: 2
        )
    }
}

// MARK: - 新增按鈕視圖
struct AddBankButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                        .shadow(radius: 3)
                }
                .padding(.trailing, 30)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - 主視圖
struct BankListView: View {
    @Binding var banks: [Bank]
    @Binding var stocks: [Stock]
    @State private var showingAddBank = false
    @State private var isEditing = false
    @State private var showingRenameAlert = false
    @State private var selectedBank: Bank?
    @State private var newBankName = ""
    @State private var errorMessage: String = ""
    @State private var showingErrorAlert = false
    @State private var selectedBankForNavigation: Bank?


    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(banks) { bank in
                        ZStack{
                            BankCardView(
                                bank: bank,
                                isEditing: isEditing,
                                onRename: {
                                    selectedBank = bank
                                    newBankName = bank.name
                                    showingRenameAlert = true
                                }
                            )
                            if !isEditing {
                                NavigationLink(
                                    destination: StockPortfolioView(
                                        stocks: $stocks,
                                        isEditing: .constant(false),
                                        bankId: bank.id,
                                        bankName: bank.name
                                    )
                                ) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                        }
                        .listRowBackground(Color.white)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                        .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deleteBank)
                    .onMove(perform: moveBanks)
                }
                .listStyle(PlainListStyle())
                .listRowSpacing(10)
                .background(Color.white)
                
                AddBankButton(action: { showingAddBank = true })
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("我的銀行")
                        .navigationTitleStyle()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !banks.isEmpty {
                        Button(isEditing ? "完成" : "編輯") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                    }
                }
            }
            .padding(.top, 25)
        }
        .sheet(isPresented: $showingAddBank) {
            AddBankView(banks: $banks)
        }
        .alert("重新命名銀行", isPresented: $showingRenameAlert) {
            TextField("銀行名稱", text: $newBankName)
                .autocorrectionDisabled(true)
            Button("取消", role: .cancel) {
                newBankName = ""
            }
            Button("確定") {
                renameSelectedBank()
            }
        } message: {
            Text("請輸入新的銀行名稱")
        }
                                        
        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
        .alert("錯誤", isPresented: $showingErrorAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func deleteBank(at offsets: IndexSet) {
        let banksToDelete = offsets.map { banks[$0] }
        stocks.removeAll { stock in
            banksToDelete.contains { $0.id == stock.bankId }
        }
        banks.remove(atOffsets: offsets)
    }
    
    private func moveBanks(from source: IndexSet, to destination: Int) {
        banks.move(fromOffsets: source, toOffset: destination)
    }
    


    private func renameSelectedBank() {
        
        let trimmedName = newBankName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "銀行名稱不能為空"
            showingErrorAlert = true
            return
        }
                
        if let selectedBank = selectedBank,
           let bankIndex = banks.firstIndex(where: { $0.id == selectedBank.id }) {
            // 檢查新名稱是否已存在於其他銀行
            if banks.contains(where: { $0.name == trimmedName && $0.id != selectedBank.id }) {
                errorMessage = "已存在相同名稱的銀行"
                showingErrorAlert = true
                return
            }
            
            var updatedBank = banks[bankIndex]
            updatedBank.name = trimmedName
            banks[bankIndex] = updatedBank
            newBankName = ""
        }
    }
}

#Preview {
    ContentView()
}
