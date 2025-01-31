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


    
    var body: some View {
        NavigationStack {
            List {
                ForEach(banks) { bank in
                    NavigationLink(destination: StockPortfolioView(
                        stocks: $stocks,
                        isEditing: .constant(false),
                        bankId: bank.id,
                        bankName: bank.name
                    )) {
                        HStack{
                            if isEditing {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                                .frame(width: 15)
                            Text(bank.name)
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.vertical, 8)
                        }
                    }
                }
                .onDelete(perform: deleteBank)
                .onMove(perform: moveBanks)
                
            }
            .listRowSpacing(10)  // 增加列表项之间的间距
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("我的銀行")
                        .font(.system(size: 30, weight: .bold))
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
            .sheet(isPresented: $showingAddBank) {
                AddBankView(banks: $banks)
            }
            
            // 浮動的新增按鈕
            VStack {
                Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        showingAddBank = true
                        
                    }) {
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
        
        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
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

}

#Preview {
    ContentView()
}
