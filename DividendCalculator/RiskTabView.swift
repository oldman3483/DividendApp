import SwiftUI
import Charts

struct RiskTabView: View {
    @Binding var metrics: InvestmentMetrics
    @Binding var isLoading: Bool
    @Binding var selectedTimeRange: String
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(spacing: 20) {
                    riskSummarySection
                    concentrationAnalysisSection
                    riskVsReturnSection
                    riskOptimizationAdviceSection
                    riskLevelSection
                }
                .padding(.horizontal)
            }
        }
        .onChange(of: selectedTimeRange) { _, newPeriod in
            updateRiskMetricsForPeriod(newPeriod)
        }
    }
    
    // MARK: - 風險指標摘要
    private var riskSummarySection: some View {
        GroupBox {
            VStack(spacing: 15) {
                Text("風險指標摘要")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                riskComponentRow(
                    title: "投資組合波動性",
                    value: metrics.riskMetrics.portfolioVolatility,
                    detail: "波動程度",
                    color: getRiskColor("投資組合波動性", metrics.riskMetrics.portfolioVolatility)
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                riskComponentRow(
                    title: "Beta值",
                    value: metrics.riskMetrics.betaValue,
                    detail: "市場敏感度",
                    color: getRiskColor("Beta值", metrics.riskMetrics.betaValue)
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                riskComponentRow(
                    title: "最大回撤",
                    value: metrics.riskMetrics.maxDrawdown,
                    detail: "最大損失",
                    color: getRiskColor("最大回撤", metrics.riskMetrics.maxDrawdown)
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                riskComponentRow(
                    title: "夏普比率",
                    value: metrics.performanceMetrics.sharpeRatio,
                    detail: "風險調整收益",
                    color: getRiskColor("夏普比率", metrics.performanceMetrics.sharpeRatio)
                )
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // MARK: - 集中度分析
    private var concentrationAnalysisSection: some View {
        GroupBox {
            VStack(spacing: 15) {
                Text("集中度分析")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                riskComponentRow(
                    title: "行業集中度",
                    value: metrics.riskMetrics.sectorConcentration,
                    detail: getConcentrationRating(metrics.riskMetrics.sectorConcentration),
                    color: getRiskColor("行業集中度", metrics.riskMetrics.sectorConcentration)
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                riskComponentRow(
                    title: "前五大持股比重",
                    value: metrics.riskMetrics.topHoldingsWeight,
                    detail: getTopHoldingsRating(metrics.riskMetrics.topHoldingsWeight),
                    color: getRiskColor("前五大持股比重", metrics.riskMetrics.topHoldingsWeight)
                )
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                riskComponentRow(
                    title: "地域分散度",
                    value: calculateGeographicDiversification(),
                    detail: getGeographicDiversityRating(calculateGeographicDiversification()),
                    color: getRiskColor("地域分散度", calculateGeographicDiversification())
                )
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // MARK: - 風險vs報酬圖表
    private var riskVsReturnSection: some View {
        GroupBox {
            VStack(spacing: 15) {
                Text("波動vs報酬分析")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                riskReturnChart
                    .frame(height: 250)
                
                riskReturnLegend
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // MARK: - 風險優化建議
    private var riskOptimizationAdviceSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 15) {
                Text("風險優化建議")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("根據您的風險分析，以下是優化建議：")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    if metrics.riskMetrics.sectorConcentration > 40 {
                        riskAdviceRow(icon: "exclamationmark.triangle", text: "產業集中度較高，建議增加其他產業的投資以分散風險")
                    }
                    
                    if metrics.riskMetrics.portfolioVolatility > 20 {
                        riskAdviceRow(icon: "chart.line.uptrend.xyaxis", text: "投資組合波動性較高，可考慮增加低波動性股票")
                    }
                    
                    if metrics.riskMetrics.topHoldingsWeight > 50 {
                        riskAdviceRow(icon: "chart.pie", text: "前五大持股佔比過高，建議增加投資組合多樣性")
                    }
                    
                    if metrics.performanceMetrics.sharpeRatio < 0.8 {
                        riskAdviceRow(icon: "chart.bar", text: "夏普比率偏低，可考慮調整投資組合以提高風險調整後報酬")
                    }
                    
                    if calculateGeographicDiversification() < 30 {
                        riskAdviceRow(icon: "globe", text: "地域分散度不足，可考慮增加不同地區的投資標的")
                    }
                    
                    riskAdviceRow(icon: "timer", text: "定期評估投資組合風險指標，確保風險保持在可接受範圍內")
                }
            }
            .padding()
        }
        .groupBoxStyle(TransparentGroupBox())
    }
    
    // MARK: - 風險等級評估
    private var riskLevelSection: some View {
        GroupBox {
            VStack(spacing: 15) {
                Text("投資組合風險等級")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                riskLevelVisualization
                    .frame(height: 100)
                
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
    
    // MARK: - 內部方法
    
    // 通用列表行
    private func riskComponentRow(title: String, value: Double, detail: String, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(formatRiskValue(title, value))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 6)
    }
    
    // 格式化風險值
    private func formatRiskValue(_ title: String, _ value: Double) -> String {
        switch title {
        case "投資組合波動性":
            return String(format: "%.2f%%", value)
        case "Beta值":
            return String(format: "%.2f", value)
        case "最大回撤":
            return String(format: "%.2f%%", value)
        case "夏普比率":
            return String(format: "%.2f", value)
        case "行業集中度":
            return String(format: "%.1f%%", value)
        case "前五大持股比重":
            return String(format: "%.1f%%", value)
        case "地域分散度":
            return String(format: "%.1f%%", value)
        default:
            return String(format: "%.2f", value)
        }
    }
    
    // 風險顏色
    private func getRiskColor(_ title: String, _ value: Double) -> Color {
        switch title {
        case "投資組合波動性":
            return value > 15 ? .red : (value > 10 ? .orange : .green)
        case "Beta值":
            return value > 1.2 ? .red : (value < 0.8 ? .green : .orange)
        case "最大回撤":
            return value > 15 ? .red : (value > 10 ? .orange : .green)
        case "夏普比率":
            return value >= 1 ? .green : (value >= 0 ? .orange : .red)
        case "行業集中度":
            return value > 50 ? .red : (value > 30 ? .orange : .green)
        case "前五大持股比重":
            return value > 60 ? .red : (value > 40 ? .orange : .green)
        case "地域分散度":
            return value < 30 ? .red : (value < 60 ? .orange : .green)
        default:
            return .gray
        }
    }
    
    // 風險等級指示器
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
    
    // 風險建議列
    private func riskAdviceRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // 圖例
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
    
    // MARK: - 其他輔助方法
    
    // 更新風險指標（模擬）
        private func updateRiskMetricsForPeriod(_ period: String) {
            Task {
                isLoading = true
                
                await MainActor.run {
                    switch period {
                    case "1年":
                        metrics.riskMetrics.portfolioVolatility = Double.random(in: 10...15)
                        metrics.riskMetrics.betaValue = Double.random(in: 0.9...1.1)
                        metrics.riskMetrics.maxDrawdown = Double.random(in: 5...10)
                    case "3年":
                        metrics.riskMetrics.portfolioVolatility = Double.random(in: 12...18)
                        metrics.riskMetrics.betaValue = Double.random(in: 0.8...1.2)
                        metrics.riskMetrics.maxDrawdown = Double.random(in: 8...15)
                    case "5年":
                        metrics.riskMetrics.portfolioVolatility = Double.random(in: 15...22)
                        metrics.riskMetrics.betaValue = Double.random(in: 0.7...1.3)
                        metrics.riskMetrics.maxDrawdown = Double.random(in: 10...20)
                    default:
                        break
                    }
                    
                    isLoading = false
                }
            }
        }
        
        // 風險vs報酬數據結構
        private struct RiskReturnDataPoint: Identifiable {
            let id = UUID()
            let name: String
            let risk: Double
            let returnRate: Double
            let size: CGFloat
            let color: Color
            let isHighlighted: Bool
        }
        
        // 生成風險vs報酬模擬數據
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
            
            // 添加背景股票
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
                risk: metrics.riskMetrics.portfolioVolatility / 2,
                returnRate: metrics.performanceMetrics.totalReturnPercentage / 2,
                size: 150,
                color: .purple,
                isHighlighted: true
            ))
            
            return dataPoints
        }
        
        // 計算投資組合風險等級
        private func calculatePortfolioRiskLevel() -> Int {
            let volatilityScore = Int(metrics.riskMetrics.portfolioVolatility / 6)
            let betaScore = metrics.riskMetrics.betaValue < 0.8 ? 0 :
                            metrics.riskMetrics.betaValue < 1.0 ? 1 :
                            metrics.riskMetrics.betaValue < 1.2 ? 2 :
                            metrics.riskMetrics.betaValue < 1.4 ? 3 : 4
            
            let concentrationScore = Int(metrics.riskMetrics.sectorConcentration / 20)
            
            let combinedScore = (volatilityScore + betaScore + concentrationScore) / 3
            return min(4, max(0, combinedScore))
        }
        
        // 風險等級顏色
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
        
        // 風險等級名稱
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
        
        // 風險等級描述
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
        
        // 計算地域分散度
        private func calculateGeographicDiversification() -> Double {
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
