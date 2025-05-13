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
    
    @State private var showAmountInReport: Bool = true
    @State private var showingUpdateAlert = false
    
    private let stockService = LocalStockService()
    @State private var stockName: String = ""
    
    init(plan: InvestmentPlan, onUpdate: @escaping (InvestmentPlan) -> Void) {
        self.plan = plan
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 股票資訊和目標卡片
                GroupBox {
                    VStack(spacing: 20) {
                        // 股票基本信息
                        HStack(alignment: .center) {
                            // 左側：股票代號和名稱
                            HStack(spacing: 8) {
                                Text(plan.symbol)
                                    .font(.system(size: 22, weight: .bold))
                                Text(stockName)
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // 右側：目標年度
                            Text("\(plan.targetYear)年目標")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.vertical, 4)
                        
                        // 目標金額
                        HStack {
                            Text("目標金額")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("$\(Int(plan.targetAmount).formattedWithComma)")
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 投資計劃詳情
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("投資計劃詳情")
                            .font(.headline)
                            .padding(.bottom, 10)
                        
                        // 使用固定格式的行來確保對齊
                        detailRow(
                            title: "每\(plan.getFrequencyText())投入金額",
                            value: "$\(Int(plan.requiredAmount).formattedWithComma)",
                            valueColor: .blue
                        )
                        
                        detailRow(
                            title: "投資頻率",
                            value: plan.getFrequencyText()
                        )
                        
                        detailRow(
                            title: "投資年限",
                            value: "\(plan.investmentYears) 年"
                        )
                        
                        detailRow(
                            title: "總投入金額",
                            value: "$\(Int(plan.requiredAmount * Double(plan.investmentFrequency * plan.investmentYears)).formattedWithComma)"
                        )
                        
                        detailRow(
                            title: "預期報酬",
                            value: "$\(Int(plan.targetAmount - plan.requiredAmount * Double(plan.investmentFrequency * plan.investmentYears)).formattedWithComma)",
                            valueColor: .green
                        )
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 預期階段性成就
                GroupBox {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("預期階段性成就")
                            .font(.headline)
                            .padding(.bottom, 10)
                        
                        // 使用更美觀的卡片排列
                        HStack(spacing: 10) {
                            forecastCard(
                                year: 1,
                                title: "1年後",
                                plan: plan
                            )
                            
                            forecastCard(
                                year: 3,
                                title: "3年後",
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
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(TransparentGroupBox())
                
                // 注意事項
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("注意事項")
                            .font(.headline)
                            .padding(.bottom, 8)
                        
                        noticeRow(text: "此計算基於歷史平均報酬率，實際投資報酬可能有所不同")
                        noticeRow(text: "計算假設報酬率平均分布，未考慮市場波動")
                        noticeRow(text: "投資涉及風險，過去的表現不代表未來的結果")
                    }
                    .padding(.vertical, 4)
                }
                .groupBoxStyle(TransparentGroupBox())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.black)
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchStockName()
        }
    }
    
    // 一致的詳情行顯示格式
    private func detailRow(title: String, value: String, valueColor: Color = .white) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 8)
    }
    
    // 注意事項行格式
    private func noticeRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.gray)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    // 改進的預測卡片
    private func forecastCard(year: Int, title: String, plan: InvestmentPlan, isTarget: Bool = false) -> some View {
        let (amount, percentage) = calculateForecastValue(year: year, plan: plan)
        
        return VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text("$\(Int(amount).formattedWithComma)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isTarget ? .green : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(String(format: "+%.1f%%", percentage))
                .font(.system(size: 14))
                .foregroundColor(.blue)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
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
    
    // 獲取股票名稱
    private func fetchStockName() async {
        let name = await stockService.getTaiwanStockInfo(symbol: plan.symbol)
        
        await MainActor.run {
            stockName = name ?? ""
        }
    }
}
