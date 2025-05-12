//
//  PlanningDetailView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/5/8.
//

import SwiftUI
import Charts

struct PlanningDetailView: View {
    let plan: InvestmentPlan
    let onUpdate: (InvestmentPlan) -> Void
    
    @State private var currentAmount: String
    @State private var showAmountInReport: Bool = true
    @State private var showingUpdateAlert = false
    
    init(plan: InvestmentPlan, onUpdate: @escaping (InvestmentPlan) -> Void) {
        self.plan = plan
        self.onUpdate = onUpdate
        self._currentAmount = State(initialValue: String(format: "%.0f", plan.currentAmount))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 標題和目標摘要
                GroupBox {
                    VStack(alignment: .leading, spacing: 15) {
                        // 股票基本信息
                        HStack {
                            Text(plan.symbol)
                                .font(.headline)
                            Text(getStockName(plan.symbol))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(plan.targetYear)年目標")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.bottom, 5)
                        
                        // 進度條
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 20)
                                    .cornerRadius(10)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * CGFloat(plan.completionPercentage / 100), height: 20)
                                    .cornerRadius(10)
                                
                                Text("\(Int(plan.completionPercentage))%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                        .frame(height: 20)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("目前已投入")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("$\(Int(plan.currentAmount).formattedWithComma)")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 5) {
                                Text("目標金額")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("$\(Int(plan.targetAmount).formattedWithComma)")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        
                        Button(action: {
                            showingUpdateAlert = true
                        }) {
                            Text("更新投資進度")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 投資計劃詳情
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("投資計劃詳情")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        DetailRow(
                            title: "每\(plan.getFrequencyText())投入金額",
                            value: "$\(Int(plan.requiredAmount).formattedWithComma)",
                            valueColor: .blue
                        )
                        
                        DetailRow(
                            title: "投資頻率",
                            value: plan.getFrequencyText()
                        )
                        
                        DetailRow(
                            title: "投資年限",
                            value: "\(plan.investmentYears) 年"
                        )
                        
                        DetailRow(
                            title: "總投入金額",
                            value: "$\(Int(plan.requiredAmount * Double(plan.investmentFrequency * plan.investmentYears)).formattedWithComma)"
                        )
                        
                        DetailRow(
                            title: "預期報酬",
                            value: "$\(Int(plan.targetAmount - plan.requiredAmount * Double(plan.investmentFrequency * plan.investmentYears)).formattedWithComma)",
                            valueColor: .green
                        )
                    }
                    .padding()
                }
                .groupBoxStyle(TransparentGroupBox())
                
                
                // 預期階段性成就
                GroupBox {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("預期階段性成就")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        // 時間點預測
                        HStack(spacing: 12) {
                            forecastCard(
                                year: 1,
                                title: "1年後",
                                plan: plan
                            )
                            
                            forecastCard(
                                year: plan.investmentYears / 2,
                                title: "\(plan.investmentYears / 2)年後",
                                plan: plan
                            )
                            
                            forecastCard(
                                year: plan.investmentYears,
                                title: "\(plan.investmentYears)年後",
                                plan: plan,
                                isTarget: true
                            )
                        }
                    }
                    .padding()
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 注意事項
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("注意事項")
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Text("• 此計算基於歷史平均報酬率，實際投資報酬可能有所不同")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("• 計算假設報酬率平均分布，未考慮市場波動")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("• 投資涉及風險，過去的表現不代表未來的結果")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding()
                }
                .groupBoxStyle(TransparentGroupBox())
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("更新投資進度", isPresented: $showingUpdateAlert) {
            TextField("已投入金額", text: $currentAmount)
                .keyboardType(.numberPad)
            Button("取消", role: .cancel) { }
            Button("更新") {
                updateCurrentAmount()
            }
        } message: {
            Text("請輸入目前已投入的總金額")
        }
    }
    
    // 預測卡片
    private func forecastCard(year: Int, title: String, plan: InvestmentPlan, isTarget: Bool = false) -> some View {
        let (amount, percentage) = calculateForecastValue(year: year, plan: plan)
        
        return VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text("$\(Int(amount).formattedWithComma)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isTarget ? .green : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            Text(String(format: "+%.1f%%", percentage))
                .font(.system(size: 14))
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isTarget ? Color.green.opacity(0.2) : Color(white: 0.2))
        .cornerRadius(10)
    }
    
    // 計算特定年份的預測值
    private func calculateForecastValue(year: Int, plan: InvestmentPlan) -> (amount: Double, percentage: Double) {
        if let projectionData = plan.projectionData,
           let point = projectionData.first(where: { Int($0.year) == year }) {
            let principal = point.principal
            let profit = point.amount - principal
            let percentage = principal > 0 ? (profit / principal) * 100 : 0
            return (point.amount, percentage)
        }
        
        // 如果沒有找到對應的數據點，進行簡單計算
        let annualRate = 0.09 // 假設年化報酬率為9%
        let periodicAmount = plan.requiredAmount
        
        // 總投資金額
        let totalInvestment = periodicAmount * Double(plan.investmentFrequency * year)
        
        // 計算未來值
        var futureValue = 0.0
        for _ in 1...(plan.investmentFrequency * year) {
            futureValue = futureValue * (1 + annualRate / Double(plan.investmentFrequency))
            futureValue += periodicAmount
        }
        
        // 計算報酬百分比
        let profit = futureValue - totalInvestment
        let percentage = totalInvestment > 0 ? (profit / totalInvestment) * 100 : 0
        
        return (futureValue, percentage)
    }
    
    // 更新當前投資金額
    private func updateCurrentAmount() {
        if let amount = Double(currentAmount), amount >= 0 {
            var updatedPlan = plan
            updatedPlan.currentAmount = amount
            onUpdate(updatedPlan)
        }
    }
    
    // 獲取股票名稱
    private func getStockName(_ symbol: String) -> String {
        // 這裡應該根據 symbol 獲取股票名稱，可以使用本地服務
        // 簡單起見，這裡先返回空字符串
        return ""
    }
}
