//
//  BankListItemView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/2.
//


import SwiftUI

struct BankListItemView: View {
    let bank: Bank
    let isEditing: Bool
    let onRename: () -> Void
    @Binding var stocks: [Stock]
    @State private var portfolioEditing = false

    
    var body: some View {
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
                        isEditing: $portfolioEditing,
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
}
