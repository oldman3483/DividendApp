//
//  AddStockSheetView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/28.
//

import SwiftUI

struct AddStockSheetView: View {
    @Binding var stocks: [Stock]
    @Binding var watchlist: [WatchStock]
    let symbol: String
    let name: String
    
    var body: some View {
        AddStockView(
            stocks: $stocks,
            watchlist: $watchlist,
            initialSymbol: symbol,
            initialName: name
        )
    }
}
