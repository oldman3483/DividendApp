//
//  PlanningListView.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/5/8.
//

import SwiftUI

struct PlanningListView: View {
    @State private var plans: [InvestmentPlan] = []
    @State private var isEditing = false
    @State private var showingAddPlan = false
    @State private var showingRenameAlert = false
    @State private var planToRename: InvestmentPlan?
    @State private var newPlanName = ""
    @State private var errorMessage: String = ""
    @State private var showingErrorAlert = false
    
    @Binding var stocks: [Stock]
    @Binding var banks: [Bank]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if plans.isEmpty {
                        // 空狀態
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        // 規劃卡片列表
                        planListContent
                    }
                }
                
                // 新增規劃按鈕
                FloatingActionButton(action: { showingAddPlan = true })
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("我的規劃")
                        .navigationTitleStyle()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !plans.isEmpty {
                        Button(isEditing ? "完成" : "編輯") {
                            withAnimation {
                                isEditing.toggle()
                            }
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPlan) {
            GoalCalculatorView(onSave: { newPlan in
                plans.append(newPlan)
                savePlans()
            })
        }
        .alert("重新命名", isPresented: $showingRenameAlert) {
            TextField("新名稱", text: $newPlanName)
                .autocorrectionDisabled(true)
            Button("取消", role: .cancel) { resetRenameState() }
            Button("確定") { renameSelectedPlan() }
        } message: {
            Text("請輸入新的名稱")
        }
        .alert("錯誤", isPresented: $showingErrorAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadPlans()
            
            // 預加載所有計劃中的股票名稱
            for plan in plans {
                fetchStockNameAsync(plan.symbol)
            }
        }
    }
    
    // MARK: - 子視圖
    
    // 空狀態視圖
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("尚未建立任何規劃")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("點擊右下角的按鈕開始新增規劃")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
        }
    }
    
    // 規劃列表
    private var planListContent: some View {
        List {
            ForEach(plans) { plan in
                planCardView(for: plan)
                    .listRowInsets(EdgeInsets(
                        top: 4,
                        leading: isEditing ? 0 : 16,
                        bottom: 4,
                        trailing: 16
                    ))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete(perform: isEditing ? deletePlan : nil)
            .onMove(perform: movePlans)
        }
        .listStyle(PlainListStyle())
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .padding(.horizontal, 0)
        .padding(.vertical, 8)
    }
    
    // 規劃卡片視圖
    private func planCardView(for plan: InvestmentPlan) -> some View {
        ZStack {
            // 卡片背景
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.15))
                .shadow(color: Color.white.opacity(0.05), radius: 4, x: 0, y: 2)
            
            if isEditing {
                // 編輯模式
                Button(action: {
                    planToRename = plan
                    newPlanName = plan.title
                    showingRenameAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                        
                        Text(plan.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            } else {
                // 一般模式 - 修改後的卡片
                VStack(alignment: .leading, spacing: 10) {
                    // 第一行：規劃標題
                    Text(plan.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    // 第二行：股票代號和名稱
                    HStack {
                        Text("\(plan.symbol) \(getStockName(plan.symbol))")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    // 第三行：目標金額、投資年限和頻率
                    HStack {
                        Text("目標: $\(Int(plan.targetAmount).formattedWithComma)")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text("\(plan.investmentYears)年・\(getFrequencyText(plan.investmentFrequency))")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            NavigationLink(
                destination: PlanningDetailView(plan: plan, onUpdate: { updatedPlan in
                    if let index = plans.firstIndex(where: { $0.id == updatedPlan.id }) {
                        plans[index] = updatedPlan
                        savePlans()
                    }
                },
                                                stocks: $stocks,
                                                banks: $banks
                )
            ) {
                EmptyView()
            }
            .opacity(0)
        }
        .frame(height: 100)
    }

    // 添加輔助函數用來格式化頻率文本
    private func getFrequencyText(_ frequency: Int) -> String {
        switch frequency {
        case 1:
            return "每年"
        case 4:
            return "每季"
        case 12:
            return "每月"
        default:
            return "自訂"
        }
    }
    
    // MARK: - Helper Methods
    
    private func deletePlan(at offsets: IndexSet) {
        plans.remove(atOffsets: offsets)
        savePlans()
    }
    
    private func movePlans(from source: IndexSet, to destination: Int) {
        plans.move(fromOffsets: source, toOffset: destination)
        savePlans()
    }
    
    private func renameSelectedPlan() {
        let trimmedName = newPlanName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "規劃名稱不能為空"
            showingErrorAlert = true
            return
        }
        
        if let plan = planToRename,
           let planIndex = plans.firstIndex(where: { $0.id == plan.id }) {
            if plans.contains(where: { $0.title == trimmedName && $0.id != plan.id }) {
                errorMessage = "已存在相同名稱的規劃"
                showingErrorAlert = true
                return
            }
            
            var updatedPlan = plan
            updatedPlan.title = trimmedName
            plans[planIndex] = updatedPlan
            savePlans()
            resetRenameState()
        }
    }
    
    private func resetRenameState() {
        planToRename = nil
        newPlanName = ""
        showingRenameAlert = false
    }
    
    // 添加新的屬性來緩存股票名稱
    @State private var stockNameCache: [String: String] = [:]
    private let stockService = LocalStockService()

    // 同步獲取股票名稱（優先從緩存獲取）

    private func getStockName(_ symbol: String) -> String {
        // 1. 檢查緩存
        if let cachedName = stockNameCache[symbol], !cachedName.isEmpty {
            return cachedName
        }
        
        // 2. 檢查用戶投資組合
        if let stockInPortfolio = stocks.first(where: { $0.symbol == symbol }) {
            // 不在這裡直接更新緩存，而是通過異步操作更新
            // 在下一個事件循環中更新緩存
            Task { @MainActor in
                stockNameCache[symbol] = stockInPortfolio.name
            }
            return stockInPortfolio.name
        }
        
        // 3. 如果沒有找到，觸發異步加載
        fetchStockNameAsync(symbol)
        
        // 4. 返回一個臨時值
        return symbol // 暫時返回股票代號作為名稱
    }

    // 異步加載股票名稱
    private func fetchStockNameAsync(_ symbol: String) {
        Task {
            // 如果已經在緩存中且不為空，則跳過
            if let cached = stockNameCache[symbol], !cached.isEmpty {
                return
            }
            
            // 從服務獲取名稱
            if let name = await stockService.getTaiwanStockInfo(symbol: symbol), !name.isEmpty {
                await MainActor.run {
                    // 更新緩存
                    stockNameCache[symbol] = name
                    
                    // 由於UI可能已經顯示，所以需要觸發刷新
                    if !self.plans.isEmpty {
                        // 使用一個小技巧觸發視圖重繪
                        let temp = self.plans
                        self.plans = []
                        self.plans = temp
                    }
                }
            }
        }
    }
    
    // MARK: - 數據持久化
    
    private func savePlans() {
        if let encodedPlans = try? JSONEncoder().encode(plans) {
            UserDefaults.standard.set(encodedPlans, forKey: "investmentPlans")
        }
    }
    
    private func loadPlans() {
        if let planData = UserDefaults.standard.data(forKey: "investmentPlans"),
           let decodedPlans = try? JSONDecoder().decode([InvestmentPlan].self, from: planData) {
            plans = decodedPlans
        }
    }
}
