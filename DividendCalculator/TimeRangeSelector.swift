//
//  TimeRangeSelector.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/12.
//

import SwiftUI

struct TimeRangeSelector: View {
    let timeRanges: [String]
    @Binding var selectedRange: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(timeRanges, id: \.self) { range in
                    Button(action: {
                        withAnimation {
                            selectedRange = range
                        }
                    }) {
                        Text(range)
                            .font(.system(size: 13))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedRange == range ? Color.blue : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(selectedRange == range ? .white : .gray)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }
}
