//
//  BankListContent.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/4.
//

import SwiftUI

struct BankListContent: View {
    @Binding var banks: [Bank]
    @Binding var stocks: [Stock]
    let isEditing: Bool
    let onRename: (Bank) -> Void
    let onDelete: (IndexSet) -> Void
    let onMove: (IndexSet, Int) -> Void
    
    var body: some View {
        List {
            ForEach(banks) { bank in
                ZStack {
                    BankCardView(
                        bank: bank,
                        isEditing: isEditing,
                        onRename: onRename
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
            .onDelete(perform: onDelete)
            .onMove(perform: onMove)
        }
        .listStyle(PlainListStyle())
        .listRowSpacing(10)
        .background(Color.white)
    }
}
