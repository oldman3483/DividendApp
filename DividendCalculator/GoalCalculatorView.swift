//
//  GoalCalculatorView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/4/24.
//

import SwiftUI
import Charts

struct GoalCalculatorView: View {
    // 股票選擇
    @State private var selectedSymbol = "0050" // 默認0050
    @State private var clearDataObserver: NSObjectProtocol?

    
    private let availableSymbols = [
        ("0050", "元大台灣50ETF"),
        ("2330", "台積電")
    ]
    
    // 目標設置
    @State private var goalAmount: String = "1000000" // 默認100萬
    @State private var investmentYears: Int = 7      // 默認7年
    @State private var investmentFrequency: Int = 12 // 默認每月(12次/年)
    
    // 計算結果
    @State private var requiredAmount: Double = 0
    @State private var projectionData: [GrowthPoint] = []
    
    // 顯示狀態
    @State private var showResults = false
    @State private var isCalculating = false
    
    // 投資頻率選項
    private let frequencyOptions = [
        (1, "每年"),
        (4, "每季"),
        (12, "每月")
    ]
    
    // 服務
    private let calculatorService = GoalCalculatorService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 股票選擇區域
                    stockSelectionView
                    
                    // 目標設置區域
                    goalSettingView
                    
                    // 計算按鈕
                    calculateButton
                    
                    // 結果區域
                    if showResults {
                        // 投資結果卡片
                        investmentResultCards
                        
                        // 投資預測卡片
                        investmentForecastCards
                        
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("我的規劃")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // 添加清除數據的通知觀察者
            clearDataObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name("ClearAllData"),
                object: nil,
                queue: .main
            ) { _ in
                self.resetGoalData()
            }
        }
        .onDisappear {
            // 移除觀察者
            if let observer = clearDataObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    // MARK: - 子視圖
    
    // 投資結果卡片
    private var investmentResultCards: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                Text("計算結果")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .center, spacing: 10) {
                    Text("達成目標需要每\(getFrequencyText())投入")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("$\(Int(requiredAmount).formattedWithComma)")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.vertical, 10)
                
                // 總投入與預期報酬卡片
                HStack(spacing: 12) {
                    investmentMetricCard(
                        title: "總投入金額",
                        value: "$\(Int(requiredAmount * Double(investmentFrequency * investmentYears)).formattedWithComma)",
                        color: .white
                    )
                    
                    investmentMetricCard(
                        title: "預期報酬",
                        value: "$\(Int(Double(goalAmount) ?? 0 - requiredAmount * Double(investmentFrequency * investmentYears)).formattedWithComma)",
                        color: .green
                    )
                }
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    // 投資預測卡片
    private var investmentForecastCards: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                Text("投資增長預測")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 不同時間點的預測卡片
                VStack(spacing: 15) {
                    // 假設我們選擇顯示1年、3年和目標年份
                    HStack(spacing: 12) {
                        forecastCard(
                            year: 1,
                            title: "1年後",
                            amountFormat: "%.0f",
                            percentFormat: "+%.1f%%"
                        )
                        
                        forecastCard(
                            year: 3,
                            title: "3年後",
                            amountFormat: "%.0f",
                            percentFormat: "+%.1f%%"
                        )
                        
                        forecastCard(
                            year: investmentYears,
                            title: "\(investmentYears)年後(目標)",
                            amountFormat: "%.0f",
                            percentFormat: "+%.1f%%",
                            isTarget: true
                        )
                    }
                }
                
                // 預測說明
                HStack(spacing: 20) {
                    // 保留原有的預測說明...
                    VStack(alignment: .leading, spacing: 6) {
                        Text("保守預測")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        let conservativeRate = max(0, getHistoricalReturn() - 2)
                        Text(String(format: "+%.1f%%/年", conservativeRate))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("基準預測")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Text(String(format: "+%.1f%%/年", getHistoricalReturn()))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("樂觀預測")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        let optimisticRate = getHistoricalReturn() + 2
                        Text(String(format: "+%.1f%%/年", optimisticRate))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    // 投資指標卡片
    private func investmentMetricCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(white: 0.2))
        .cornerRadius(10)
    }
    // 預測卡片
    private func forecastCard(year: Int, title: String, amountFormat: String, percentFormat: String, isTarget: Bool = false) -> some View {
        let (amount, percentage) = calculateForecastValue(year: year)
        
        return VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text("$\(Int(amount).formattedWithComma)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isTarget ? .green : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Text(String(format: percentFormat, percentage))
                .font(.system(size: 14))
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isTarget ? Color.green.opacity(0.2) : Color(white: 0.2))
        .cornerRadius(10)
    }
    // 計算特定年份的預測值
        private func calculateForecastValue(year: Int) -> (amount: Double, percentage: Double) {
            let initialAmount = 0.0
            let annualRate = getHistoricalReturn() / 100
            let periodicAmount = requiredAmount
            
            // 總投資金額
            let totalInvestment = periodicAmount * Double(investmentFrequency * year)
            
            // 計算未來值
            var futureValue = initialAmount
            for i in 1...(investmentFrequency * year) {
                futureValue = futureValue * (1 + annualRate / Double(investmentFrequency))
                futureValue += periodicAmount
            }
            
            // 計算報酬百分比
            let profit = futureValue - totalInvestment
            let percentage = totalInvestment > 0 ? (profit / totalInvestment) * 100 : 0
            
            return (futureValue, percentage)
        }
        
        // 獲取歷史報酬率
    private func getHistoricalReturn() -> Double {
        return 9.0 // 假設默認報酬率為9%
    }
    
    
    // 添加重置目標資料的方法
    private func resetGoalData() {
        // 重置目標值為預設值
        selectedSymbol = "0050"
        goalAmount = "1000000"
        investmentYears = 7
        investmentFrequency = 12
        
        // 重置計算結果
        requiredAmount = 0
        projectionData = []
        showResults = false
    }
    
    // 股票選擇視圖
    private var stockSelectionView: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                Text("選擇投資標的")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Picker("投資標的", selection: $selectedSymbol) {
                    ForEach(availableSymbols, id: \.0) { symbol, name in
                        Text("\(symbol) \(name)").tag(symbol)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // 顯示歷史報酬率
                if let selectedStock = availableSymbols.first(where: { $0.0 == selectedSymbol }) {
                    HStack {
                        Text("\(selectedStock.1) 過去十年平均年化報酬率")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                        Text(String(format: "%.1f%%", calculatorService.getHistoricalReturn(for: selectedSymbol) * 100))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // 目標設置視圖
    private var goalSettingView: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                Text("目標設定")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 目標金額
                VStack(alignment: .leading, spacing: 8) {
                    Text("目標金額")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    TextField("目標金額", text: $goalAmount)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(white: 0.2))
                        .cornerRadius(8)
                        .keyboardType(.numberPad)
                        .foregroundColor(.white)
                }
                
                // 投資年限
                VStack(alignment: .leading, spacing: 8) {
                    Text("投資年限")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Stepper(value: $investmentYears, in: 1...30) {
                        Text("\(investmentYears) 年")
                            .foregroundColor(.white)
                    }
                }
                
                // 投資頻率
                VStack(alignment: .leading, spacing: 8) {
                    Text("投資頻率")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Picker("投資頻率", selection: $investmentFrequency) {
                        ForEach(frequencyOptions, id: \.0) { frequency, label in
                            Text(label).tag(frequency)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // 計算按鈕
    private var calculateButton: some View {
        Button(action: {
            calculateRequiredInvestment()
        }) {
            Text("計算所需投資金額")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(10)
        }
        .disabled(isCalculating)
        .overlay {
            if isCalculating {
                ProgressView()
                    .foregroundColor(.white)
            }
        }
    }
    
//    // 結果視圖
//    private var resultsView: some View {
//        VStack(spacing: 20) {
//            // 所需投資金額
//            GroupBox {
//                VStack(alignment: .leading, spacing: 15) {
//                    Text("計算結果")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    
//                    VStack(alignment: .center, spacing: 10) {
//                        Text("達成目標需要每\(getFrequencyText())投入")
//                            .font(.system(size: 16))
//                            .foregroundColor(.gray)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                        
//                        Text("$\(Int(requiredAmount).formattedWithComma)")
//                            .font(.system(size: 30, weight: .bold))
//                            .foregroundColor(.blue)
//                            .frame(maxWidth: .infinity, alignment: .center)
//                    }
//                    .padding(.vertical, 10)
//                    
//                    // 小結
//                    VStack(alignment: .leading, spacing: 5) {
//                        Text("總投入金額：$\(Int(requiredAmount * Double(investmentFrequency * investmentYears)).formattedWithComma)")
//                            .font(.system(size: 14))
//                            .foregroundColor(.gray)
//                        
//                        Text("預期報酬：$\(Int(Double(goalAmount) ?? 0 - requiredAmount * Double(investmentFrequency * investmentYears)).formattedWithComma)")
//                            .font(.system(size: 14))
//                            .foregroundColor(.green)
//                    }
//                    .padding(.top, 10)
//                }
//                .padding()
//            }
//            .groupBoxStyle(TransparentGroupBox())
//            
//            // 增長預測圖表
//            GroupBox {
//                VStack(alignment: .leading, spacing: 15) {
//                    Text("投資增長預測")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    
//                    // 圖表
//                    Chart {
//                        ForEach(projectionData) { point in
//                            LineMark(
//                                x: .value("年", point.year),
//                                y: .value("金額", point.amount)
//                            )
//                            .foregroundStyle(.blue)
//                        }
//                        
//                        ForEach(projectionData) { point in
//                            LineMark(
//                                x: .value("年", point.year),
//                                y: .value("本金", point.principal)
//                            )
//                            .foregroundStyle(.gray)
//                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
//                        }
//                        
//                        if let goalAmountValue = Double(goalAmount) {
//                            RuleMark(y: .value("目標", goalAmountValue))
//                                .foregroundStyle(.green)
//                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
//                                .annotation(position: .leading) {
//                                    Text("目標")
//                                        .font(.caption)
//                                        .foregroundColor(.green)
//                                }
//                        }
//                    }
//                    .frame(height: 250)
//                    .chartYAxis {
//                        AxisMarks(position: .leading) { value in
//                            if let amount = value.as(Double.self) {
//                                AxisValueLabel {
//                                    Text("$\(Int(amount).formattedWithComma)")
//                                        .font(.system(size: 10))
//                                        .foregroundColor(.gray)
//                                }
//                            }
//                        }
//                    }
//                    .chartXAxis {
//                        AxisMarks { value in
//                            if let year = value.as(Double.self), year.truncatingRemainder(dividingBy: 1) == 0 {
//                                AxisValueLabel {
//                                    Text("\(Int(year))年")
//                                        .font(.system(size: 10))
//                                        .foregroundColor(.gray)
//                                }
//                            }
//                        }
//                    }
//                    
//                    // 圖例
//                    HStack(spacing: 20) {
//                        HStack(spacing: 5) {
//                            Rectangle()
//                                .fill(.blue)
//                                .frame(width: 20, height: 2)
//                            Text("總資產")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                        
//                        HStack(spacing: 5) {
//                            Rectangle()
//                                .fill(.gray)
//                                .frame(width: 20, height: 2)
//                            Text("本金")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                        
//                        HStack(spacing: 5) {
//                            Rectangle()
//                                .fill(.green)
//                                .frame(width: 20, height: 2)
//                            Text("目標金額")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                    }
//                    .padding(.top, 10)
//                }
//                .padding()
//            }
//            .groupBoxStyle(TransparentGroupBox())
//            
//            // 注意事項
//            GroupBox {
//                VStack(alignment: .leading, spacing: 10) {
//                    Text("注意事項")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    
//                    Text("• 此計算基於歷史平均報酬率，實際投資報酬可能有所不同")
//                        .font(.system(size: 14))
//                        .foregroundColor(.gray)
//                    
//                    Text("• 計算假設報酬率平均分布，未考慮市場波動")
//                        .font(.system(size: 14))
//                        .foregroundColor(.gray)
//                    
//                    Text("• 投資涉及風險，過去的表現不代表未來的結果")
//                        .font(.system(size: 14))
//                        .foregroundColor(.gray)
//                }
//                .padding()
//            }
//            .groupBoxStyle(TransparentGroupBox())
//        }
//    }
    
    // MARK: - 業務邏輯
    
    // 計算所需投資金額
    private func calculateRequiredInvestment() {
        guard let goalAmountValue = Double(goalAmount), goalAmountValue > 0 else {
            return
        }
        
        isCalculating = true
        
        // 模擬異步計算
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 計算每期需要投入的金額
            let required = self.calculatorService.calculateRequiredInvestment(
                symbol: self.selectedSymbol,
                goalAmount: goalAmountValue,
                years: self.investmentYears,
                paymentsPerYear: self.investmentFrequency
            )
            
            // 生成增長預測
            let projection = self.calculatorService.generateGrowthProjection(
                symbol: self.selectedSymbol,
                periodicAmount: required,
                years: self.investmentYears,
                paymentsPerYear: self.investmentFrequency
            )
            
            // 更新UI
            self.requiredAmount = required
            self.projectionData = projection
            self.showResults = true
            self.isCalculating = false
            
            // 計算目標年份（當前年份 + 投資年限）
            let currentYear = Calendar.current.component(.year, from: Date())
            let targetYear = currentYear + self.investmentYears
            
            // 將規劃數據儲存到 AppStorage
            UserDefaults.standard.set(goalAmountValue, forKey: "targetAmount")
            UserDefaults.standard.set(0.0, forKey: "currentAmount") // 初始已投資設為 0
            UserDefaults.standard.set(targetYear, forKey: "targetYear")
        }
    }
    
    // 獲取頻率文字
    private func getFrequencyText() -> String {
        switch investmentFrequency {
        case 1: return "年"
        case 4: return "季"
        case 12: return "月"
        default: return "期"
        }
    }
}
