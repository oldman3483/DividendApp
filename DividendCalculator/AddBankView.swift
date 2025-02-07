//
//  BankListView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/1/31.
//

//
//  AddBankView.swift
//  DividendCalculator
//

import SwiftUI

struct AddBankView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var banks: [Bank]
    
    @State private var bankName: String = ""
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    Form {
                        Section(header: Text("銀行資訊")
                            .font(.system(size: 14))) { // 調整區段標題字體大小
                                TextField("銀行名稱", text: $bankName)
                                    .autocorrectionDisabled(true)
                                    .font(.system(size: 18))  // 調整輸入框字體大小
                                
                            }
                        
                        if !errorMessage.isEmpty {
                            Section {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))  // 調整錯誤訊息字體大小
                            }
                        }
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationTitle("新增銀行")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新增") {
                        addBank()
                    }
                    .disabled(bankName.isEmpty)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
    
    private func addBank() {
        let trimmedName = bankName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "請輸入銀行名稱"
            return
        }
        
        // 檢查是否已存在相同名稱的銀行
        guard !banks.contains(where: { $0.name == trimmedName }) else {
            errorMessage = "已存在相同名稱的銀行"
            return
        }
        
        // 新增銀行
        let newBank = Bank(name: trimmedName)
        banks.append(newBank)
        dismiss()
    }
}

#Preview {
    ContentView()
}
