//
//  AddingButton.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/2/4.
//

import SwiftUI

struct AddingButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
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
}
