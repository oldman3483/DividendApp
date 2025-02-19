//
//  AddBankView.swift
//  DividendCalculator
//


import SwiftUI

struct AddBankView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var banks: [Bank]
    
    @State var bankName: String = ""
    @State var errorMessage: String = ""
    
    var filteredSuggestions: [String] {
        if bankName.isEmpty {
            return TaiwanBanks.suggestions
        }
        return TaiwanBanks.suggestions.filter {
            $0.lowercased().contains(bankName.lowercased())
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 銀行名稱輸入區
                    VStack(alignment: .leading, spacing: 8) {
                        Text("銀行名稱")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        TextField("輸入銀行名稱或從下方選擇", text: $bankName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled(true)
                    }
                    .padding(.horizontal)
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                            .padding(.horizontal)
                    }
                    
                    // 建議銀行列表
                    VStack(alignment: .leading, spacing: 12) {
                        Text("銀行清單")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 12
                        ) {
                            ForEach(filteredSuggestions, id: \.self) { suggestion in
                                Button(action: {
                                    bankName = suggestion
                                }) {
                                    Text(suggestion)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(bankName == suggestion ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.black)
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
    
    func addBank() {
        // 使用新的驗證系統
        let validationResult = FormValidator.validateBankName(bankName, existingBanks: banks)
        
        switch validationResult {
        case .success:
            let newBank = Bank(name: bankName)
            banks.append(newBank)
            dismiss()
        case .failure(let message):
            errorMessage = message
        }
    }
}
