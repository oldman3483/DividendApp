//
//  CustomDateRangeView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/3/9.
//
import SwiftUI

struct CustomDateRangeView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isVisible: Bool
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    @State private var selectedQuickRange: QuickDateRange = .custom
    @State private var showDatePicker = false
    @State private var isSelectingStartDate = true
    
    // 預設日期範圍選項
    enum QuickDateRange: String, CaseIterable, Identifiable {
        case week = "一週"
        case month = "一個月"
        case quarter = "一季"
        case halfYear = "半年"
        case custom = "自訂"
        
        var id: String { self.rawValue }
    }
    
    init(startDate: Binding<Date>, endDate: Binding<Date>, isVisible: Binding<Bool>, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self._startDate = startDate
        self._endDate = endDate
        self._isVisible = isVisible
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        
        // 初始化臨時日期
        self._tempStartDate = State(initialValue: startDate.wrappedValue)
        self._tempEndDate = State(initialValue: endDate.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                // 快速選擇按鈕 - 更明顯的風格
                quickRangeSelector
                    .padding(.top, 5)
                
                // 日期範圍摘要 - 顯示當前選擇
                dateRangeSummary
                
                // 簡化的日期選擇視圖
                simplifiedDateSelectionView
                
                // 顯示日期間隔
                intervalDisplay
                    .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("選擇日期範圍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("確定") {
                        // 確保開始日期不晚於結束日期
                        if tempStartDate > tempEndDate {
                            tempStartDate = tempEndDate
                        }
                        startDate = tempStartDate
                        endDate = tempEndDate
                        onConfirm()
                    }
                    .disabled(tempEndDate < tempStartDate)
                }
            }
            .background(Color.black)
        }
    }
    
    // 快速範圍選擇器
    private var quickRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(QuickDateRange.allCases) { range in
                    Button(action: {
                        selectQuickRange(range)
                    }) {
                        Text(range.rawValue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedQuickRange == range ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedQuickRange == range ? .white : .gray)
                            .cornerRadius(15)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 10)
        }
        .background(Color(white: 0.15))
        .cornerRadius(10)
    }
    
    // 日期範圍摘要
    private var dateRangeSummary: some View {
        HStack(spacing: 0) {
            // 開始日期按鈕
            Button(action: {
                isSelectingStartDate = true
                showDatePicker = true
            }) {
                VStack(alignment: .center, spacing: 4) {
                    Text("開始日期")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(formatDate(tempStartDate))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.2))
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity)
            
            // 中間箭頭
            Image(systemName: "arrow.right")
                .foregroundColor(.gray)
                .padding(.horizontal, 5)
            
            // 結束日期按鈕
            Button(action: {
                isSelectingStartDate = false
                showDatePicker = true
            }) {
                VStack(alignment: .center, spacing: 4) {
                    Text("結束日期")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(formatDate(tempEndDate))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.2))
                    .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
    }
    
    // 簡化的日期選擇視圖
    private var simplifiedDateSelectionView: some View {
        VStack {
            if showDatePicker {
                Text(isSelectingStartDate ? "選擇開始日期" : "選擇結束日期")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.bottom, 5)
                
                if isSelectingStartDate {
                    DatePicker("", selection: $tempStartDate, in: ...tempEndDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                        .background(Color(white: 0.15))
                        .cornerRadius(10)
                        .frame(height: 300)
                        .onChange(of: tempStartDate) { _, newValue in
                            // 確保開始日期不晚於結束日期
                            if newValue > tempEndDate {
                                tempEndDate = newValue
                            }
                        }
                } else {
                    DatePicker("", selection: $tempEndDate, in: tempStartDate...Date(), displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                        .background(Color(white: 0.15))
                        .cornerRadius(10)
                        .frame(height: 300)
                }
                
                Button(action: {
                    showDatePicker = false
                }) {
                    Text("完成選擇")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            } else {
                // 日期範圍視覺化
                HStack(spacing: 15) {
                    VStack(alignment: .center) {
                        Text(String(Calendar.current.component(.day, from: tempStartDate)))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Text("\(monthName(tempStartDate)) \(String(Calendar.current.component(.year, from: tempStartDate)))")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color(white: 0.15))
                    .cornerRadius(10)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .center) {
                        Text(String(Calendar.current.component(.day, from: tempEndDate)))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Text("\(monthName(tempEndDate)) \(String(Calendar.current.component(.year, from: tempEndDate)))")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 120, height: 120)
                    .background(Color(white: 0.15))
                    .cornerRadius(10)
                }
                .padding(.vertical, 20)
                
                Button(action: {
                    showDatePicker = true
                    isSelectingStartDate = true
                }) {
                    Text("選擇具體日期")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    // 間隔顯示
    private var intervalDisplay: some View {
        let days = Calendar.current.dateComponents([.day], from: tempStartDate, to: tempEndDate).day ?? 0
        
        return VStack(alignment: .center, spacing: 5) {
            Text("選擇範圍: \(days) 天")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text("\(formatDate(tempStartDate)) 至 \(formatDate(tempEndDate))")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cardBackground()
        
    }
    
    // 選擇快速時間範圍
    private func selectQuickRange(_ range: QuickDateRange) {
        selectedQuickRange = range
        let calendar = Calendar.current
        let today = Date()
        
        switch range {
        case .week:
            tempEndDate = today
            tempStartDate = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        case .month:
            tempEndDate = today
            tempStartDate = calendar.date(byAdding: .month, value: -1, to: today) ?? today
        case .quarter:
            tempEndDate = today
            tempStartDate = calendar.date(byAdding: .month, value: -3, to: today) ?? today
        case .halfYear:
            tempEndDate = today
            tempStartDate = calendar.date(byAdding: .month, value: -6, to: today) ?? today
        case .custom:
            // 保持當前選擇的日期
            break
        }
        
        // 關閉日期選擇器
        showDatePicker = false
    }
}

// MARK: - 日期範圍徽章視圖
struct CustomDateRangeBadgeView: View {
    let startDate: Date
    let endDate: Date
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("自訂時間範圍")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
                
                HStack(spacing: 10) {
                    Text(formatDate(startDate))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(5)
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                    
                    Text(formatDate(endDate))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(5)
                    
                    Spacer()
                    
                    let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
                    Text("\(days) 天")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(10)
            .cardBackground()
            
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// MARK: - 預覽用擴展
struct CustomDateRangeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 預覽日期範圍選擇器
            CustomDateRangeView(
                startDate: .constant(Date().addingTimeInterval(-86400 * 30)),
                endDate: .constant(Date()),
                isVisible: .constant(true),
                onConfirm: {},
                onCancel: {}
            )
            .preferredColorScheme(.dark)
            
            // 預覽徽章視圖
            CustomDateRangeBadgeView(
                startDate: Date().addingTimeInterval(-86400 * 30),
                endDate: Date(),
                onTap: {}
            )
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.black)
        }
    }
}
