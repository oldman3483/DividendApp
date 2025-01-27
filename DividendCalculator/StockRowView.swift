//
//  StockRowView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/22.
//

import SwiftUI

struct StockRowView: View {
    let stock: SearchStock
    let addAction: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.symbol).font(.headline)
                Text(stock.name).foregroundColor(.gray)
            }
            Spacer()
            Button(action: addAction) {
                Image(systemName: "plus.circle").foregroundColor(.blue)
            }
        }
    }
}
