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
    @Binding var stocks: [Stock]
    @Binding var banks: [Bank]
    
    @State private var showAmountInReport: Bool = true
    @State private var showingUpdateAlert = false
    
    @State private var showingConvertToPlanSheet = false
    @State private var selectedBankId: UUID? = nil
    @State private var startDate = Date()
    
    
    private let stockService = LocalStockService()
    @State private var stockName: String = ""
    
    init(plan: InvestmentPlan, onUpdate: @escaping (InvestmentPlan) -> Void, stocks: Binding<[Stock]>, banks: Binding<[Bank]>) {
        self.plan = plan
        self.onUpdate = onUpdate
        self._stocks = stocks
        self._banks = banks
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
                
                // 添加轉換為定期定額計畫的按鈕
                Button(action: {
                    showingConvertToPlanSheet = true
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("轉換為定期定額計畫")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 10)
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
        .sheet(isPresented: $showingConvertToPlanSheet) {
            ConvertToPlanView(
                plan: plan,
                stocks: $stocks,
                banks: $banks,
                onConvert: { bankId, startDate in
                    convertToRegularPlan(bankId: bankId, startDate: startDate)
                }
            )
        }
    }
    
    private func fetchStockName() async {
        let name = await stockService.getTaiwanStockInfo(symbol: plan.symbol)
        
        await MainActor.run {
            stockName = name ?? ""
        }
    }
    
    private func convertToRegularPlan(bankId: UUID, startDate: Date) {
        // 創建新的定期定額投資設定
        let regularInvestment = RegularInvestment(
            title: plan.title,
            amount: plan.requiredAmount,
            frequency: getFrequencyFromPlan(),
            startDate: startDate,
            endDate: getEndDateFromPlan(),
            isActive: true,
            note: "從「\(plan.title)」規劃轉換而來"
        )
        
        let newStock = Stock(
            symbol: plan.symbol,
            name: stockName,
            shares: 0, // 定期定額初始股數為0
            dividendPerShare: 0, // 先設為0，後續會自動獲取
            dividendYear: Calendar.current.component(.year, from: Date()),
            frequency: 1, // 先設為1，後續會自動獲取
            bankId: bankId,
            regularInvestment: regularInvestment
        )
        stocks.append(newStock)
        
        Task {
            var updatedStock = newStock
            await updatedStock.updateRegularInvestmentTransactions(stockService: stockService)
            
            await MainActor.run {
                if let index = stocks.firstIndex(where: { $0.id == newStock.id }) {
                    stocks[index] = updatedStock
                }
            }
        }
        
        Task {
            await updateStockDividendInfo(stock: newStock)
        }
        
        showingConvertToPlanSheet = false
    }
    
    private func getFrequencyFromPlan() -> RegularInvestment.Frequency {
        switch plan.investmentFrequency {
        case 12:
            return .monthly
        case 4:
            return .quarterly
        case 1:
            return .monthly // 一年一次太久，轉為每月
        default:
            return .monthly
        }
    }
    
    private func getEndDateFromPlan() -> Date? {
        let calendar = Calendar.current
        return calendar.date(byAdding: .year, value: plan.investmentYears, to: Date())
    }
    
    private func updateStockDividendInfo(stock: Stock) async {
            var updatedStock = stock
            
            // 獲取股息資訊
            do {
                let dividendResponse = try await APIService.shared.getDividendData(symbol: plan.symbol)
                
                // 使用 SQLDataProcessor 處理資料
                let frequency = SQLDataProcessor.shared.calculateDividendFrequency(from: dividendResponse.data)
                let dividendPerShare = SQLDataProcessor.shared.calculateDividendPerShare(from: dividendResponse.data)
                
                await MainActor.run {
                    if let index = stocks.firstIndex(where: { $0.id == stock.id }) {
                        updatedStock.dividendPerShare = dividendPerShare
                        updatedStock.frequency = frequency
                        stocks[index] = updatedStock
                    }
                }
            } catch {
                print("從 API 獲取股息資料失敗: \(error.localizedDescription)")
                
                // 如果API獲取失敗，使用本地服務
                if let dividend = await stockService.getTaiwanStockDividend(symbol: plan.symbol) {
                    updatedStock.dividendPerShare = dividend
                }
                if let freq = await stockService.getTaiwanStockFrequency(symbol: plan.symbol) {
                    updatedStock.frequency = freq
                }
                
                await MainActor.run {
                    if let index = stocks.firstIndex(where: { $0.id == stock.id }) {
                        stocks[index] = updatedStock
                    }
                }
            }
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
    

struct ConvertToPlanView: View {
    @Environment(\.dismiss) private var dismiss
    let plan: InvestmentPlan
    @Binding var stocks: [Stock]
    @Binding var banks: [Bank]
    let onConvert: (UUID, Date) -> Void
    
    @State private var selectedBankId: UUID?
    @State private var startDate = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 添加銀行列表
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("轉換設定")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("將「\(plan.title)」轉換為定期定額計畫")
                            .font(.headline)
                            .lineLimit(2)
                        
                        Text("每\(getFrequencyText())投入金額: $\(Int(plan.requiredAmount).formattedWithComma)")
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("選擇銀行")) {
                    if banks.isEmpty {
                        Text("請先新增銀行")
                            .foregroundColor(.red)
                    } else {
                        Picker("選擇銀行", selection: $selectedBankId) {
                            ForEach(banks) { bank in
                                Text(bank.name).tag(bank.id as UUID?)
                            }
                        }
                    }
                }
                
                Section(header: Text("開始日期")) {
                    DatePicker("開始執行日期", selection: $startDate, displayedComponents: .date)
                }
                
                Section {
                    Button(action: {
                        if let bankId = selectedBankId {
                            onConvert(bankId, startDate)
                            dismiss()
                        } else {
                            showError = true
                            errorMessage = "請選擇銀行"
                        }
                    }) {
                        Text("確認轉換")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(selectedBankId != nil ? Color.blue : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(selectedBankId == nil)
                }
            }
            .background(Color.black)
            .scrollContentBackground(.hidden)
            .navigationTitle("轉換為定期定額")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("錯誤", isPresented: $showError) {
                Button("確定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // 如果只有一個銀行，則默認選中
                if banks.count == 1 {
                    selectedBankId = banks.first?.id
                }
            }
        }
    }
    
    // 獲取頻率文字
    private func getFrequencyText() -> String {
        switch plan.investmentFrequency {
        case 1: return "年"
        case 4: return "季"
        case 12: return "月"
        default: return "期"
        }
    }
}
