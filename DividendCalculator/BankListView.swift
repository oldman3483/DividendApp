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
    @State private var bankToRename: Bank?
    @State private var newBankName = ""
    @State private var errorMessage: String = ""
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(banks) { bank in
                        ZStack {
                            BankCardView(
                                bank: bank,
                                isEditing: isEditing,
                                onRename: { bank in
                                    bankToRename = bank
                                    newBankName = bank.name
                                    showingRenameAlert = true
                                }
                            )
                            if !isEditing {
                                NavigationLink(
                                    destination: StockPortfolioView(
                                        stocks: $stocks,
                                        bankId: bank.id,
                                        bankName: bank.name
                                    )
                                ) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                        }
                        .listRowBackground(Color.black)
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                        .listRowSeparator(.hidden)
                    }
                    .onDelete(perform: deleteBank)
                    .onMove(perform: moveBanks)
                }
                .listStyle(PlainListStyle())
                .listRowSpacing(10)
                .background(Color.black)
                
                if banks.isEmpty {
                    VStack {
                        Text("尚未新增任何銀行")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
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
                        .foregroundColor(.white)
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
                resetRenameState()
            }
            Button("確定") {
                renameSelectedBank()
            }
        } message: {
            Text("請輸入新的銀行名稱")
        }
        .alert("錯誤", isPresented: $showingErrorAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
    }
    
    // MARK: - 私有方法
    
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
        
        if let bank = bankToRename,
           let bankIndex = banks.firstIndex(where: { $0.id == bank.id }) {
            if banks.contains(where: { $0.name == trimmedName && $0.id != bank.id }) {
                errorMessage = "已存在相同名稱的銀行"
                showingErrorAlert = true
                return
            }
            
            let updatedBank = Bank(
                id: banks[bankIndex].id,
                name: trimmedName,
                createdDate: banks[bankIndex].createdDate
            )
            
            banks[bankIndex] = updatedBank
            resetRenameState()
        }
    }
    
    private func resetRenameState() {
        bankToRename = nil
        newBankName = ""
        showingRenameAlert = false
    }
}

#Preview {
    ContentView()
}
