//
//  ReportGeneratorView.swift
//  DividendCalculator
//
//  Created on 2025/4/10.
//

import SwiftUI
import Charts

struct ReportGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stocks: [Stock]
    
    // 報表類型和時間區間選擇
    @State private var selectedReportType = ReportType.investmentReturn
    @State private var selectedTimeRange = "1年"
    @State private var isCustomRangeActive = false
    @State private var startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showCustomDatePicker = false
    
    // 報表數據
    @State private var reportData: [ReportDataPoint] = []
    @State private var isLoading = false
    
    // 控制顯示金額的狀態
    @State private var showAmountInReport: Bool = true
    @State private var showAmountAlert: Bool = false
    
    // 服務依賴
    private let stockService = LocalStockService()
    private let reportService = ReportService()
    
    // 報表類型枚舉
    enum ReportType: String, CaseIterable, Identifiable {
        case investmentReturn = "投資報酬率"
        case dividendYield = "股利報酬率"
        
        var id: String { self.rawValue }
    }
    
    // 時間區間選項
    private let timeRanges = ["3個月", "6個月", "1年", "3年", "5年", "自訂"]
    
    // 獲取當前報表數據的摘要
    private var dataSummary: (currentPercentage: Double, averagePercentage: Double, currentAmount: Double, averageAmount: Double) {
        guard !reportData.isEmpty else {
            return (0, 0, 0, 0)
        }
        
        let currentPercentage = reportData.last?.percentage ?? 0
        let currentAmount = reportData.last?.amount ?? 0
        
        let totalPercentage = reportData.reduce(0) { $0 + $1.percentage }
        let totalAmount = reportData.reduce(0) { $0 + $1.amount }
        
        let averagePercentage = totalPercentage / Double(reportData.count)
        let averageAmount = totalAmount / Double(reportData.count)
        
        return (currentPercentage, averagePercentage, currentAmount, averageAmount)
    }
    
    var body: some View {
        ZStack {
            // 主視圖
            VStack(spacing: 15) {
                // 報表類型選擇器
                Picker("報表類型", selection: $selectedReportType) {
                    ForEach(ReportType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // 時間區間選擇器
                VStack(alignment: .leading, spacing: 5) {
                    Text("時間區間")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    HStack {
                        ForEach(timeRanges, id: \.self) { range in
                            Button(action: {
                                withAnimation {
                                    selectedTimeRange = range
                                    if range == "自訂" {
                                        showCustomDatePicker = true
                                    } else {
                                        isCustomRangeActive = false
                                        updateDateRangeForSelection(range)
                                        Task {
                                            await generateReportData()
                                        }
                                    }
                                }
                            }) {
                                Text(range)
                                    .font(.system(size: 12))
                                    .foregroundColor(selectedTimeRange == range ? .white : .gray)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 5)
                                    .background(selectedTimeRange == range ? Color.blue : Color.gray.opacity(0.2))
                                    .cornerRadius(5)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 顯示自定義日期範圍
                if isCustomRangeActive {
                    CustomDateRangeBadgeView(
                        startDate: startDate,
                        endDate: endDate,
                        onTap: {
                            showCustomDatePicker = true
                        }
                    )
                    .padding(.top, -5)
                }
                // 投資報表標題區域
                VStack(spacing: 15) {
                    Text(selectedReportType.rawValue + "報表")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Text("期間: " + (isCustomRangeActive ?
                                   "\(formatDate(startDate)) - \(formatDate(endDate))" :
                                    selectedTimeRange))
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // 摘要卡片
                    HStack(spacing: 10) {
                        // 百分比
                        VStack(alignment: .leading, spacing: 5) {
                            Text(selectedReportType == .investmentReturn ? "目前投資報酬率" : "目前股利報酬率")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Text(String(format: "%.1f%%", dataSummary.currentPercentage))
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(dataSummary.currentPercentage >= 0 ? .blue : .red)
                            
                            Text("平均值: \(String(format: "%.1f%%", dataSummary.averagePercentage))")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(white: 0.15))
                        .cornerRadius(10)
                        
                        // 實際金額
                        VStack(alignment: .leading, spacing: 5) {
                            Text(selectedReportType == .investmentReturn ? "實際投資報酬金額" : "實際股利收入金額")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            if showAmountInReport {
                                Text("$\(Int(dataSummary.currentAmount).formattedWithComma)")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.blue)
                            } else {
                                Text("*****")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("平均值: " + (showAmountInReport ?
                                            "$\(Int(dataSummary.averageAmount).formattedWithComma)" : "*****"))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(white: 0.15))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                // 圖表區域
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(selectedReportType.rawValue)趨勢")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if reportData.isEmpty {
                        Text("無資料可顯示")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 50)
                            .foregroundColor(.gray)
                    } else {
                        chartView
                            .frame(height: 250)
                            .padding(.horizontal, 5)
                    }
                    
                    // 圖例
                    HStack {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(selectedReportType == .investmentReturn ? Color.blue : Color.green)
                                .frame(width: 8, height: 8)
                            Text(selectedReportType.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 16, height: 1)
                            Text("平均值")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // 分享按鈕
                Button(action: {
                    shareReport()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享報表")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .background(Color.black)
            .navigationTitle("投資報表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            
            // 加載狀態
            if isLoading {
                ProgressView("計算中...")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
        .onAppear {
            Task {
                await generateReportData()
            }
        }
        .onChange(of: selectedReportType) { _, _ in
            Task {
                await generateReportData()
            }
        }
        .sheet(isPresented: $showCustomDatePicker) {
            CustomDateRangeView(
                startDate: $startDate,
                endDate: $endDate,
                isVisible: $showCustomDatePicker,
                onConfirm: {
                    isCustomRangeActive = true
                    showCustomDatePicker = false
                    // 重新計算指標
                    Task {
                        await generateReportData()
                    }
                },
                onCancel: {
                    if !isCustomRangeActive {
                        selectedTimeRange = "1年" // 如果之前沒有啟用自定義，則回到預設值
                    }
                    showCustomDatePicker = false
                }
            )
        }
        .alert("金額顯示選項", isPresented: $showAmountAlert) {
                Button("顯示金額") {
                    showAmountInReport = true
                    executeShareReport()
                }
                Button("隱藏金額") {
                    showAmountInReport = false
                    executeShareReport()
                }
                Button("取消", role: .cancel) { }
        } message: {
            Text("您希望在報表中顯示具體金額嗎？")
        }
    }
    
    // MARK: - 子視圖
    
    // 圖表視圖
    private var chartView: some View {
        Chart {
            ForEach(reportData) { dataPoint in
                LineMark(
                    x: .value("日期", dataPoint.date),
                    y: .value("百分比", dataPoint.percentage)
                )
                .foregroundStyle(selectedReportType == .investmentReturn ? Color.blue : Color.green)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .symbol {
                    Circle()
                        .fill(selectedReportType == .investmentReturn ? Color.blue : Color.green)
                        .frame(width: 8, height: 8)
                }
                .annotation(position: .top, alignment: .center) {
                    annotationContent(for: dataPoint)
                }
            }
            
            // 平均線
            RuleMark(
                y: .value("平均", dataSummary.averagePercentage)
            )
            .foregroundStyle(Color.gray.opacity(0.5))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatAxisDate(date))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let number = value.as(Double.self) {
                    AxisValueLabel {
                        Text(String(format: "%.1f%%", number))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        // 關鍵：設置Y軸範圍，使圖表能正確顯示數據變化
        .chartYScale(domain: getYAxisDomain())
        .frame(height: 250)
        .padding(.horizontal, 5)
    }

    // 輔助方法：生成標註內容
    private func annotationContent(for dataPoint: ReportDataPoint) -> some View {
        let shouldShowAnnotation =
            dataPoint == reportData.last ||
            dataPoint == reportData.first ||
            abs(dataPoint.percentage - dataSummary.averagePercentage) > 5
        
        if shouldShowAnnotation {
            return AnyView(
                Text("\(String(format: "%.1f%%", dataPoint.percentage))")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dataPoint.percentage >= 0 ? Color.blue.opacity(0.7) : Color.red.opacity(0.7))
                    )
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    // 輔助方法：動態計算Y軸範圍
    private func getYAxisDomain() -> ClosedRange<Double> {
        guard !reportData.isEmpty else { return -5...5 }
        
        let values = reportData.map { $0.percentage }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        
        // 確保有足夠的空間顯示數據變化
        let padding = max(5.0, (maxValue - minValue) * 0.2)
        return (minValue - padding)...(maxValue + padding)
    }

    
    
    // MARK: - 數據處理方法
    
    // 生成報表數據
    private func generateReportData() async {
        isLoading = true
        defer { isLoading = false }
        
        // 使用報表服務生成數據
        if selectedReportType == .investmentReturn {
            reportData = await reportService.generateInvestmentReturnData(
                stocks: stocks,
                startDate: startDate,
                endDate: endDate,
                stockService: stockService
            )
        } else {
            reportData = await reportService.generateDividendYieldData(
                stocks: stocks,
                startDate: startDate,
                endDate: endDate,
                stockService: stockService
            )
        }
    }
    
    // 更新日期範圍
    private func updateDateRangeForSelection(_ selection: String) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selection {
        case "3個月":
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            endDate = now
        case "6個月":
            startDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
            endDate = now
        case "1年":
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            endDate = now
        case "3年":
            startDate = calendar.date(byAdding: .year, value: -3, to: now) ?? now
            endDate = now
        case "5年":
            startDate = calendar.date(byAdding: .year, value: -5, to: now) ?? now
            endDate = now
        default:
            break
        }
    }
    
    // 格式化圖表X軸日期顯示
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        // 根據日期範圍長短調整顯示格式
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        let daysBetween = components.day ?? 0
        
        if daysBetween <= 90 {
            formatter.dateFormat = "MM/dd"
        } else if daysBetween <= 365 {
            formatter.dateFormat = "MM月"
        } else {
            formatter.dateFormat = "yyyy/MM"
        }
        
        return formatter.string(from: date)
    }
    
    // 格式化一般日期顯示
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
    
    // MARK: - 分享功能
    
    // 分享報表
    private func shareReport() {
        // 先詢問是否顯示金額
        showAmountAlert = true
    }
    
    // 實際執行分享的方法
    private func executeShareReport() {

        // 使用更安全的方式來展示分享表單
        DispatchQueue.main.async {
            // 使用 UIWindowScene.windows 獲取窗口
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                print("Cannot find root view controller")
                return
            }
            
            // 生成一個更精美的報表圖像
            let screenshot = createReportImage()
            
//            // 報表生成完成後顯示插頁式廣告
//            AdMobManager.shared.reportGenerationCompleted()
//            
            // 準備分享項目
            let reportTitle = "\(selectedReportType.rawValue)報表"
            _ = isCustomRangeActive ?
            "\(formatDate(startDate)) - \(formatDate(endDate))" :
            selectedTimeRange
            
            let shareItems: [Any] = [
                reportTitle,
                screenshot
            ]
            
            // 遞迴尋找最上層的視圖控制器
            func topViewController(base: UIViewController? = nil) -> UIViewController? {
                let base = base ?? rootViewController
                
                if let nav = base as? UINavigationController {
                    return topViewController(base: nav.visibleViewController)
                }
                if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
                    return topViewController(base: selected)
                }
                if let presented = base.presentedViewController {
                    return topViewController(base: presented)
                }
                return base
            }
            
            // 確保在主線程中執行UI操作
            if let topVC = topViewController() {
                let activityVC = UIActivityViewController(
                    activityItems: shareItems,
                    applicationActivities: nil
                )
                
                // 設置平板上彈出的錨點
                if let popoverController = activityVC.popoverPresentationController {
                    popoverController.sourceView = topVC.view
                    popoverController.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                
                // 讓最上層的controller呈現分享視圖
                topVC.present(activityVC, animated: true)
            } else {
                print("無法找到最上層的視圖控制器")
            }
        }
    }
    
    // 繪製圓角矩形的輔助函數
    private func fillRoundedRect(context: CGContext, rect: CGRect, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        context.addPath(path.cgPath)
        context.fillPath()
    }

    
    // 創建精美的報表圖像
    private func createReportImage() -> UIImage {
        // 設置報表圖像尺寸 - 使用適合分享的比例
        let imageWidth: CGFloat = 1200
        let imageHeight: CGFloat = 1800
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: imageWidth, height: imageHeight))
        
        return renderer.image { context in
            // 1. 設置深色背景
            UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0).setFill()
                    context.fill(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
            
            // 2. 繪製標題區域
            let titleY: CGFloat = 100
            let titleFont = UIFont.systemFont(ofSize: 60, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white
            ]
                    
            let titleString = selectedReportType.rawValue + "報表"
            let titleRect = CGRect(x: 50, y: titleY, width: imageWidth - 100, height: 70)
            titleString.draw(in: titleRect, withAttributes: titleAttributes)
            
            // 3. 繪製摘要卡片
            drawSummaryCards(context: context.cgContext, width: imageWidth)
            
            // 4. 繪製趨勢圖表
            drawTrendChart(context: context.cgContext, width: imageWidth, height: imageHeight)

            // 5. 繪製底部水印
            drawWatermark(context: context.cgContext, width: imageWidth, height: imageHeight)
        }
    }
    
    // 繪製標題區域
    private func drawTitleSection(context: CGContext, width: CGFloat) {
        // 標題部分
        let titleY: CGFloat = 100
        let titleFont = UIFont.systemFont(ofSize: 48, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        
        let titleString = selectedReportType.rawValue + "報表"
        let titleRect = CGRect(x: 50, y: titleY, width: width - 100, height: 70)
        titleString.draw(in: titleRect, withAttributes: titleAttributes)
        
        // 期間標籤
        let periodY = titleY + 100
        let periodFont = UIFont.systemFont(ofSize: 32)
        let periodAttributes: [NSAttributedString.Key: Any] = [
            .font: periodFont,
            .foregroundColor: UIColor.lightGray
        ]
        
        let periodString = "期間: " + (isCustomRangeActive ?
                                     "\(formatDate(startDate)) - \(formatDate(endDate))" :
                                        selectedTimeRange)
        let periodRect = CGRect(x: 50, y: periodY, width: width - 100, height: 40)
        periodString.draw(in: periodRect, withAttributes: periodAttributes)
    }
    
    
    // 繪製摘要卡片
    private func drawSummaryCards(context: CGContext, width: CGFloat) {
        let cardY: CGFloat = 280
        let cardHeight: CGFloat = 200
        let cardWidth = width - 100
        
        // 畫卡片背景
        context.setFillColor(UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0).cgColor)
        let cardRect = CGRect(x: 50, y: cardY, width: cardWidth, height: cardHeight)
        fillRoundedRect(context: context, rect: cardRect, radius: 20)
        
        // 左側數據 - 目前值
        let currentValueY = cardY + 40
        let valueFont = UIFont.systemFont(ofSize: 48, weight: .bold) // 增加字體大小
        let labelFont = UIFont.systemFont(ofSize: 30) // 增加字體大小
        
        // 繪製標籤
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor.lightGray
        ]
        
        let currentLabel = "目前\(selectedReportType == .investmentReturn ? "投資" : "股利")報酬率"
        let currentLabelRect = CGRect(x: 80, y: currentValueY, width: cardWidth/2 - 60, height: 40)
        currentLabel.draw(in: currentLabelRect, withAttributes: labelAttributes)
        
        // 繪製值
        let valueColor = dataSummary.currentPercentage >= 0 ?
                        UIColor(red: 0.0, green: 0.8, blue: 0.5, alpha: 1.0) :
                        UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: valueColor
        ]
        
        let currentValueString = String(format: "%.1f%%", dataSummary.currentPercentage)
        let currentValueRect = CGRect(x: 80, y: currentValueY + 50, width: cardWidth/2 - 60, height: 60)
        currentValueString.draw(in: currentValueRect, withAttributes: valueAttributes)
        
        // 平均值標籤
        let averageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24), // 增加字體大小
            .foregroundColor: UIColor.lightGray
        ]
        
        let averageString = "平均值: \(String(format: "%.1f%%", dataSummary.averagePercentage))"
        let averageRect = CGRect(x: 80, y: currentValueY + 120, width: cardWidth/2 - 60, height: 30)
        averageString.draw(in: averageRect, withAttributes: averageAttributes)
        
        // 右側數據 - 金額
        let amountLabel = "實際\(selectedReportType == .investmentReturn ? "投資" : "股利")金額"
        let amountLabelRect = CGRect(x: width/2 + 30, y: currentValueY, width: cardWidth/2 - 60, height: 40)
        amountLabel.draw(in: amountLabelRect, withAttributes: labelAttributes)
        
        // 金額值
        let amountValueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: UIColor.white
        ]
        
        // 根據用戶選擇決定是否顯示具體金額
        let amountString = showAmountInReport ?
                           "$\(Int(dataSummary.currentAmount).formattedWithComma)" :
                           "*****"
        let amountValueRect = CGRect(x: width/2 + 30, y: currentValueY + 50, width: cardWidth/2 - 60, height: 60)
        amountString.draw(in: amountValueRect, withAttributes: amountValueAttributes)
        
        // 平均金額
        let avgAmountString = showAmountInReport ?
                              "平均值: $\(Int(dataSummary.averageAmount).formattedWithComma)" :
                              "平均值: *****"
        let avgAmountRect = CGRect(x: width/2 + 30, y: currentValueY + 120, width: cardWidth/2 - 60, height: 30)
        avgAmountString.draw(in: avgAmountRect, withAttributes: averageAttributes)
    }
    
    
    // 繪製趨勢圖表 - 修改以確保連線並增加尺寸
    private func drawTrendChart(context: CGContext, width: CGFloat, height: CGFloat) {
        // 圖表標題
        let chartTitleY: CGFloat = 520
        let titleFont = UIFont.systemFont(ofSize: 36, weight: .bold) // 增加字體大小
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        
        let titleString = "\(selectedReportType.rawValue)趨勢"
        let titleRect = CGRect(x: 50, y: chartTitleY, width: width - 100, height: 50)
        titleString.draw(in: titleRect, withAttributes: titleAttributes)
        
        // 圖表容器 - 增加圖表高度
        let chartY = chartTitleY + 80
        let chartHeight: CGFloat = 700
        let chartWidth = width - 100
        
        // 繪製圖表背景
        context.setFillColor(UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0).cgColor)
        let chartRect = CGRect(x: 50, y: chartY, width: chartWidth, height: chartHeight)
        fillRoundedRect(context: context, rect: chartRect, radius: 10)
        
        // 繪製網格線
        context.setStrokeColor(UIColor(white: 0.3, alpha: 0.5).cgColor)
        context.setLineWidth(1)
        
        // 水平網格線
        let gridCount = 4
        for i in 0...gridCount {
            let y = chartY + (CGFloat(i) / CGFloat(gridCount)) * chartHeight
            context.move(to: CGPoint(x: 50, y: y))
            context.addLine(to: CGPoint(x: width - 50, y: y))
        }
        
        // 垂直網格線
        if reportData.count > 1 {
            for i in 0...reportData.count-1 {
                let x = 50 + (CGFloat(i) / CGFloat(reportData.count-1)) * chartWidth
                context.move(to: CGPoint(x: x, y: chartY))
                context.addLine(to: CGPoint(x: x, y: chartY + chartHeight))
            }
        }
        context.strokePath()
        
        // 繪製平均線
        context.setStrokeColor(UIColor.gray.cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [5, 5])
        
        let avgY = chartY + chartHeight - (chartHeight * CGFloat(dataSummary.averagePercentage) / 20.0)
        context.move(to: CGPoint(x: 50, y: avgY))
        context.addLine(to: CGPoint(x: width - 50, y: avgY))
        context.strokePath()
        
        // 重置虛線設置
        context.setLineDash(phase: 0, lengths: [])
        
        // 繪製數據線 - 確保連接所有點
        if reportData.count > 1 {
            // 先畫線
            context.beginPath()
            context.setStrokeColor(UIColor.blue.cgColor)
            context.setLineWidth(4) // 增加線的寬度
            
            var isFirstPoint = true
            
            for (index, dataPoint) in reportData.enumerated() {
                let x = 50 + (CGFloat(index) / CGFloat(reportData.count-1)) * chartWidth
                let normalizedValue = min(max(dataPoint.percentage, 0), 20) // 限制在0-20%範圍內
                let y = chartY + chartHeight - (chartHeight * CGFloat(normalizedValue) / 20.0)
                
                if isFirstPoint {
                    context.move(to: CGPoint(x: x, y: y))
                    isFirstPoint = false
                } else {
                    context.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            // 繪製線段
            context.strokePath()
            
            // 再畫點和標籤
            for (index, dataPoint) in reportData.enumerated() {
                let x = 50 + (CGFloat(index) / CGFloat(reportData.count-1)) * chartWidth
                let normalizedValue = min(max(dataPoint.percentage, 0), 20)
                let y = chartY + chartHeight - (chartHeight * CGFloat(normalizedValue) / 20.0)
                
                // 繪製數據點
                context.setFillColor(UIColor.white.cgColor)
                context.fillEllipse(in: CGRect(x: x-8, y: y-8, width: 16, height: 16)) // 增加點的大小
                
                // 繪製數據點標籤
                let labelFont = UIFont.systemFont(ofSize: 20) // 增加字體大小
                let labelAttributes: [NSAttributedString.Key: Any] = [
                    .font: labelFont,
                    .foregroundColor: UIColor.white
                ]
                
                let labelString = String(format: "%.1f%%", dataPoint.percentage)
                let labelSize = labelString.size(withAttributes: labelAttributes)
                let labelRect = CGRect(x: x - labelSize.width/2, y: y - 35, width: labelSize.width, height: labelSize.height)
                labelString.draw(in: labelRect, withAttributes: labelAttributes)
                
                // 添加月份標籤在底部
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/yy"
                let monthString = dateFormatter.string(from: dataPoint.date)
                
                let monthFont = UIFont.systemFont(ofSize: 16)
                let monthAttributes: [NSAttributedString.Key: Any] = [
                    .font: monthFont,
                    .foregroundColor: UIColor.lightGray
                ]
                
                let monthRect = CGRect(x: x - 30, y: chartY + chartHeight + 10, width: 60, height: 20)
                monthString.draw(in: monthRect, withAttributes: monthAttributes)
            }
        }
        
        // 添加Y軸標籤
        let yAxisFont = UIFont.systemFont(ofSize: 16)
        let yAxisAttributes: [NSAttributedString.Key: Any] = [
            .font: yAxisFont,
            .foregroundColor: UIColor.lightGray
        ]
        
        let maxPercentage = 20.0 // Y軸最大值
        for i in 0...gridCount {
            let percentage = CGFloat(maxPercentage) * (CGFloat(gridCount) - CGFloat(i)) / CGFloat(gridCount)
            let labelString = String(format: "%.0f%%", percentage)
            let y = chartY + (CGFloat(i) / CGFloat(gridCount)) * chartHeight
            let labelRect = CGRect(x: 10, y: y - 10, width: 40, height: 20)
            labelString.draw(in: labelRect, withAttributes: yAxisAttributes)
        }
    }

    
   
    // 繪製底部水印
    private func drawWatermark(context: CGContext, width: CGFloat, height: CGFloat) {
        let watermarkFont = UIFont.systemFont(ofSize: 20) // 增加字體大小
        let watermarkAttributes: [NSAttributedString.Key: Any] = [
            .font: watermarkFont,
            .foregroundColor: UIColor.lightGray.withAlphaComponent(0.5)
        ]
        
        let watermarkString = "由股息計算器App產生"
        let watermarkSize = watermarkString.size(withAttributes: watermarkAttributes)
        let watermarkX = (width - watermarkSize.width) / 2
        let watermarkRect = CGRect(x: watermarkX, y: height - 50, width: watermarkSize.width, height: 30)
        watermarkString.draw(in: watermarkRect, withAttributes: watermarkAttributes)
    }
}
