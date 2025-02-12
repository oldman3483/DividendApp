//
//  StockTabBar.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/12.
//

import SwiftUI

struct StockTabBar: View {
    @Binding var selectedTab: StockDetailTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(StockDetailTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 6) {
                            Text(tab.rawValue)
                                .font(.system(size: 15, weight: selectedTab == tab ? .medium : .regular))
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                            
                            Rectangle()
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }
}
