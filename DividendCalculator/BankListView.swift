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

    // 莫蘭迪色系

    private let cardBackground = Color(red: 0.93, green: 0.91, blue: 0.89)
    private let cardBorder = Color(red: 0.85, green: 0.82, blue: 0.80)

        
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
                            Text(bank.name)
                                .heading3Style()
                                .padding(.vertical, 10)
                                .padding(.horizontal, isEditing ? 8 : 16)
                                .foregroundColor(.black)
                            Spacer()
                            
                        }
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(cardBorder, lineWidth: 0)
                        )
                        .shadow(
                            color: Color.black.opacity(0.1),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                    }
                    .listRowBackground(Color.white)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .listRowSeparator(.hidden)  // 新增這行來隱藏分隔線
                }
                .onDelete(perform: deleteBank)
                .onMove(perform: moveBanks)

            }
            .listStyle(PlainListStyle())  // 使用純列表樣式
            .listRowSpacing(10)// 增加列表项之间的间距
            .background(Color.white)
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
        .sheet(isPresented: $showingAddBank) {
            AddBankView(banks: $banks)
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
