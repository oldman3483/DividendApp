//
//   BankListView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/31.
//


import SwiftUI

struct BankListView: View {
    @Binding var banks: [Bank]
    @Binding var stocks: [Stock]
    @State private var showingAddBank = false
    @State private var isEditing = false
    @State private var showingRenameAlert = false
    @State private var selectedBank: Bank?
    @State private var newBankName = ""
    @State private var errorMessage = ""
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if banks.isEmpty {
                    emptyStateView
                } else {
                    bankListContent
                }
                
                if !isEditing {
                    AddBankButton(action: { showingAddBank = true })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .padding(.top, 0)
        }
        .sheet(isPresented: $showingAddBank) {
            AddBankView(banks: $banks)
        }
        .alert("重新命名銀行", isPresented: $showingRenameAlert) {
            renameAlertContent
        }
        .alert("錯誤", isPresented: $showingErrorAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
    }
    
    private var emptyStateView: some View {
        VStack {
            Text("尚無銀行")
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    private var bankListContent: some View {
        List {
            ForEach(banks) { bank in
                BankListItemView(
                    bank: bank,
                    isEditing: isEditing,
                    onRename: {
                        selectedBank = bank
                        newBankName = bank.name
                        showingRenameAlert = true
                    },
                    stocks: $stocks
                )
            }
            .onDelete(perform: deleteBank)
            .onMove(perform: moveBanks)
        }
        .listStyle(PlainListStyle())
        .listRowSpacing(10)
        .background(Color.white)
    }
    
    private var toolbarContent: some ToolbarContent {
        Group {
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
    }
    
    private var renameAlertContent: some View {
        Group {
            TextField("銀行名稱", text: $newBankName)
                .autocorrectionDisabled(true)
            Button("取消", role: .cancel) {
                newBankName = ""
            }
            Button("確定") {
                renameSelectedBank()
            }
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
