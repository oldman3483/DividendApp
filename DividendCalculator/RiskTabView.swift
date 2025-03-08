//
//  RiskTabView.swift
//  DividendCalculator
//
//  Created on 2025/3/9.
//

import SwiftUI
import Charts

struct RiskTabView: View {
    @Binding var metrics: InvestmentMetrics
    @Binding var isLoading: Bool
    @State private var selectedRiskPeriod: String = "1年"
    
    private let riskPeriods = ["1年", "3年", "5年"]
    
    var body: some View {
        VStack(spacing: 20) {
            // 風險時間段選擇器
            Picker("風險分析期間", selection: $selectedRiskPeriod) {
                ForEach(riskPeriods, id: \.self) { period in
                    Text(period).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 風險指標摘要
                    GroupBox {
                        VStack(spacing: 15) {
                            Text("風險指標摘要")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // 投資組合波動性
                            HStack {
                                Text("投資組合波動性")
                                    .foregroundColor(.gray)
                                Spacer()
                                volatilityIndicator(value: metrics.riskMetrics.portfolioVolatility)
                            }
                            
                            // Beta值
                            HStack {
                                Text("Beta值")
                                    .foregroundColor(.gray)
                                Spacer()
                                betaIndicator(value: metrics.riskMetrics.betaValue)
                            }
                            
                            // 最大回撤
                            HStack {
                                Text("最大回撤")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(String(format: "%.2f%%", metrics.riskMetrics.maxDrawdown))
                                    .foregroundColor(.red)
                            }
                            
                            // 夏普比率
                            HStack {
                                Text("夏普比率")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(String(format: "%.2f", metrics.performanceMetrics.sharpeRatio))
                                    .foregroundColor(metrics.performanceMetrics.sharpeRatio >= 1 ? .green : .orange)
                            }
                        }
                        .padding()
                    }
                    .groupBoxStyle(TransparentGroupBox())
                    
                    // 集中度分析
                    GroupBox {
                        VStack(spacing: 15) {
                            Text("集中度分析")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // 行業集中度
                            riskComponentRow(
                                title: "行業集中度",
                                value: metrics.riskMetrics.sectorConcentration,
                                indicator: { concentrationIndicator(value: $0) },
                                detail: getConcentrationRating(metrics.riskMetrics.sectorConcentration)
                            )
                            
                            // 前五大持股比重
                            riskComponentRow(
                                title: "前五大持股比重",
                                value: metrics.riskMetrics.topHoldingsWeight,
                                indicator: { Text(String(format: "%.1f%%", $0)) },
                                detail: getTopHoldingsRating(metrics.riskMetrics.topHoldingsWeight)
                            )
                            
                            // 地域分散度 (假設新增)
                            riskComponentRow(
                                title: "地域分散度",
                                value: calculateGeographicDiversification(),
                                indicator: { geographicDiversityIndicator(value: $0) },
                                detail: getGeographicDiversityRating(calculateGeographicDiversification())
                            )
                        }
                        .padding()
                    }
                    .groupBoxStyle(TransparentGroupBox())
                    
                    // 風險vs報酬圖表
                    GroupBox {
                        VStack(spacing: 15) {
                            Text("波動vs報酬分析")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // 簡單的散點圖，展示頂級股票的風險vs報酬
                            riskReturnChart
                                .frame(height: 250)
                            
                            // 圖例說明
                            riskReturnLegend
                        }
                        .padding()
                    }
                    .groupBoxStyle(TransparentGroupBox())
                    
                    // 風險多樣化建議
                    GroupBox {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("風險優化建議")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("基於您的風險分析，以下建議可能有助於優化您的投資組合：")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                // 根據不同的風險指標提供建議
                                if metrics.riskMetrics.sectorConcentration > 40 {
                                    riskAdviceRow(icon: "exclamationmark.triangle", text: "產業集中度過高，考慮增加其它產業的股票以分散風險")
                                }
                                
                                if metrics.riskMetrics.portfolioVolatility > 20 {
                                    riskAdviceRow(icon: "chart.line.uptrend.xyaxis", text: "投資組合波動性較高，可考慮增加低波動性股票")
                                }
                                
                                if metrics.riskMetrics.topHoldingsWeight > 50 {
                                    riskAdviceRow(icon: "arrow.up.right", text: "前五大持股佔比過高，建議增加持股多樣性")
                                }
                                
                                if metrics.performanceMetrics.sharpeRatio < 0.8 {
                                    riskAdviceRow(icon: "chart.bar", text: "夏普比率偏低，可考慮調整投資組合以提高風險調整後報酬")
                                }
                                
                                if calculateGeographicDiversification() < 30 {
                                    riskAdviceRow(icon: "globe", text: "地域分散度不足，可考慮增加不同地區的投資標的")
                                }
                                
                                // 默認建議
                                riskAdviceRow(icon: "timer", text: "定期評估投資組合風險指標，確保風險保持在可接受範圍內")
                            }
                        }
                        .padding()
                    }
                    .groupBoxStyle(TransparentGroupBox())
                    
                    // 風險等級評估
                    GroupBox {
                        VStack(spacing: 15) {
                            Text("投資組合風險等級")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // 風險評級視覺化
                            riskLevelVisualization
                                .frame(height: 100)
                            
                            // 風險描述
                            Text(getRiskLevelDescription())
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                        .padding()
                    }
                    .groupBoxStyle(TransparentGroupBox())
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - 子視圖
    
    // 風險vs報酬圖表
    private var riskReturnChart: some View {
        let sampleData = generateRiskReturnData()
        
        return Chart(sampleData) { item in
            PointMark(
                x: .value("Risk", item.risk),
                y: .value("ReturnRate", item.returnRate)
            )
            .symbolSize(item.size)
            .foregroundStyle(item.color)
            .annotation(position: .top) {
                if item.isHighlighted {
                    Text(item.name)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
            }
        }
        .chartXScale(domain: [0, 25])
        .chartYScale(domain: [0, 20])
        .chartXAxis {
            AxisMarks { value in
                if let number = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(number))%")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                if let number = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(number))%")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // 風險報酬圖例
    private var riskReturnLegend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("圖例說明：")
                .font(.system(size: 14, weight: .medium))
            
            HStack(spacing: 20) {
                legendItem(color: .green, text: "高報酬低風險")
                legendItem(color: .blue, text: "中等風險報酬")
                legendItem(color: .orange, text: "高風險高報酬")
                legendItem(color: .red, text: "市場")
                legendItem(color: .purple, text: "投資組合")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // 風險等級視覺化
    private var riskLevelVisualization: some View {
        let riskLevel = calculatePortfolioRiskLevel()
        
        return HStack(spacing: 0) {
            ForEach(0..<5) { level in
                Rectangle()
                    .fill(getRiskLevelColor(level))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        if level == riskLevel {
                            VStack {
                                Image(systemName: "arrowtriangle.down.fill")
                                    .foregroundColor(.white)
                                    .offset(y: -20)
                                
                                Text(getRiskLevelName(level))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text(getRiskLevelName(level))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
            }
        }
        .cornerRadius(10)
    }
    
    // MARK: - 輔助視圖元件
    
    private func volatilityIndicator(value: Double) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Image(systemName: "circle.fill")
                    .foregroundColor(index < Int(value / 5) ? .red : .gray)
                    .font(.system(size: 12))
            }
            
            Text(String(format: "%.2f%%", value))
                .foregroundColor(value > 15 ? .red : (value > 10 ? .orange : .green))
        }
    }
    
    private func betaIndicator(value: Double) -> some View {
        HStack {
            Text(String(format: "%.2f", value))
                .foregroundColor(value > 1.2 ? .red : (value < 0.8 ? .green : .orange))
            
            Image(systemName: value > 1.2 ? "arrow.up.forward" : (value < 0.8 ? "arrow.down.forward" : "arrow.forward"))
                .foregroundColor(value > 1.2 ? .red : (value < 0.8 ? .green : .orange))
                .font(.system(size: 12))
        }
    }
    
    private func concentrationIndicator(value: Double) -> some View {
        HStack(spacing: 4) {
            ProgressView(value: value, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: value > 50 ? .red : (value > 30 ? .orange : .green)))
                .frame(width: 100)
            
            Text(String(format: "%.1f%%", value))
                .foregroundColor(value > 50 ? .red : (value > 30 ? .orange : .green))
        }
    }
    
    private func geographicDiversityIndicator(value: Double) -> some View {
        HStack(spacing: 4) {
            ProgressView(value: value, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: value < 30 ? .red : (value < 60 ? .orange : .green)))
                .frame(width: 100)
            
            Text(String(format: "%.1f%%", value))
                .foregroundColor(value < 30 ? .red : (value < 60 ? .orange : .green))
        }
    }
    
    private func riskComponentRow(title: String, value: Double, indicator: (Double) -> some View, detail: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .foregroundColor(.gray)
                Spacer()
                indicator(value)
            }
            
            HStack {
                Spacer()
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func riskAdviceRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - 輔助計算方法
    
    // 生成風險vs報酬數據（模擬數據）
    private struct RiskReturnDataPoint: Identifiable {
        let id = UUID()
        let name: String
        let risk: Double
        let returnRate: Double
        let size: CGFloat
        let color: Color
        let isHighlighted: Bool
    }
    
    private func generateRiskReturnData() -> [RiskReturnDataPoint] {
        // 獲取前5支股票作為重點顯示
        let topStocks = metrics.topPerformingStocks.prefix(5)
        
        var dataPoints: [RiskReturnDataPoint] = []
        
        // 為頂級股票創建數據點
        for (_, stock) in topStocks.enumerated() {
            // 模擬風險和報酬數據
            let risk = Double.random(in: 5...20)
            let returnValue = Double.random(in: 5...15)
            
            // 根據股利率給定顏色
            let color: Color
            if let yield = stock.calculateDividendYield() {
                if yield > 6 {
                    color = .green
                } else if yield > 3 {
                    color = .blue
                } else {
                    color = .orange
                }
            } else {
                color = .gray
            }
            
            dataPoints.append(RiskReturnDataPoint(
                name: stock.symbol,
                risk: risk,
                returnRate: returnValue,
                size: 120,
                color: color,
                isHighlighted: true
            ))
        }
        
        // 添加一些背景股票作為參考
        for _ in 0..<10 {
            let risk = Double.random(in: 3...23)
            let returnValue = Double.random(in: 2...18)
            
            dataPoints.append(RiskReturnDataPoint(
                name: "",
                risk: risk,
                returnRate: returnValue,
                size: 60,
                color: .gray.opacity(0.5),
                isHighlighted: false
            ))
        }
        
        // 添加市場平均點
        dataPoints.append(RiskReturnDataPoint(
            name: "市場",
            risk: 12,
            returnRate: 9,
            size: 100,
            color: .red,
            isHighlighted: true
        ))
        
        // 添加投資組合點
        dataPoints.append(RiskReturnDataPoint(
            name: "投資組合",
            risk: metrics.riskMetrics.portfolioVolatility / 2, // 縮放以適應圖表
            returnRate: metrics.performanceMetrics.totalReturnPercentage / 2, // 縮放以適應圖表
            size: 150,
            color: .purple,
            isHighlighted: true
        ))
        
        return dataPoints
    }
    
    // 計算投資組合風險等級 (0-4)
    private func calculatePortfolioRiskLevel() -> Int {
        // 考慮多個風險因素
        let volatilityScore = Int(metrics.riskMetrics.portfolioVolatility / 6)
        let betaScore = metrics.riskMetrics.betaValue < 0.8 ? 0 :
                        metrics.riskMetrics.betaValue < 1.0 ? 1 :
                        metrics.riskMetrics.betaValue < 1.2 ? 2 :
                        metrics.riskMetrics.betaValue < 1.4 ? 3 : 4
        
        let concentrationScore = Int(metrics.riskMetrics.sectorConcentration / 20)
        
        // 綜合評分
        let combinedScore = (volatilityScore + betaScore + concentrationScore) / 3
        return min(4, max(0, combinedScore))
    }
    
    // 獲取風險等級顏色
    private func getRiskLevelColor(_ level: Int) -> Color {
        switch level {
        case 0:
            return .green
        case 1:
            return .blue
        case 2:
            return .yellow
        case 3:
            return .orange
        case 4:
            return .red
        default:
            return .gray
        }
    }
    
    // 獲取風險等級名稱
    private func getRiskLevelName(_ level: Int) -> String {
        switch level {
        case 0:
            return "低風險"
        case 1:
            return "中低風險"
        case 2:
            return "中等風險"
        case 3:
            return "中高風險"
        case 4:
            return "高風險"
        default:
            return ""
        }
    }
    
    // 獲取風險等級描述
    private func getRiskLevelDescription() -> String {
        let level = calculatePortfolioRiskLevel()
        switch level {
        case 0:
            return "您的投資組合波動性低，適合保守型投資者。主要適合追求穩定收入和資本保值的投資者。"
        case 1:
            return "您的投資組合風險適中偏低，兼顧穩定性和適度成長。適合穩健型投資者，願意承擔少量風險以換取較高報酬。"
        case 2:
            return "您的投資組合風險處於中等水平，平衡了風險和報酬。適合平衡型投資者，能接受市場波動以追求長期成長。"
        case 3:
            return "您的投資組合風險較高，具有較大的波動性。適合積極型投資者，願意承擔更多風險以追求更高報酬。"
        case 4:
            return "您的投資組合風險水平高，可能會有較大幅度的波動。適合進取型投資者，能夠承受市場顯著波動以換取潛在高報酬。"
        default:
            return ""
        }
    }
    
    // 計算地域分散度（模擬數據）
    private func calculateGeographicDiversification() -> Double {
        // 實際應用中應該基於真實的地理分散數據計算
        // 這裡使用一個與集中度相關的模擬值
        return max(20.0, 100.0 - metrics.riskMetrics.sectorConcentration * 0.8)
    }
    
    // 獲取集中度評級
    private func getConcentrationRating(_ value: Double) -> String {
        if value > 60 {
            return "高度集中"
        } else if value > 40 {
            return "中度集中"
        } else if value > 20 {
            return "適度分散"
        } else {
            return "高度分散"
        }
    }
    
    // 獲取前五大持股比重評級
    private func getTopHoldingsRating(_ value: Double) -> String {
        if value > 70 {
            return "過度集中"
        } else if value > 50 {
            return "較為集中"
        } else if value > 30 {
            return "適度均衡"
        } else {
            return "高度均衡"
        }
    }
    
    // 獲取地域分散度評級
    private func getGeographicDiversityRating(_ value: Double) -> String {
        if value < 30 {
            return "區域高度集中"
        } else if value < 60 {
            return "區域適度分散"
        } else {
            return "國際化良好"
        }
    }
}
