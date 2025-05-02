//
//  APIService.swift
//  DividendCalculator
//
//  Created on 2025/3/6.
//

import Foundation
import Network

// MARK: - API 錯誤
struct APIError: Error {
    let code: Int
    let message: String
}

// MARK: - API 服務
class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://dividend-app-148949302162.asia-east1.run.app"
    private let networkMonitor = NWPathMonitor()
    private let timeoutInterval: TimeInterval = 30.0 // 增加超時時間
    
    private init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { path in
            print("網絡狀態變更: \(path.status == .satisfied ? "已連接" : "未連接")")
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    // 檢查網絡連接
    private func checkNetworkConnection() -> Bool {
        return networkMonitor.currentPath.status == .satisfied
    }
    
    // MARK: - 通用 GET 請求
    func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        // 先檢查網絡連接
        guard checkNetworkConnection() else {
            throw APIError(code: 1, message: "網絡未連接，請檢查您的網絡設置")
        }
        
        guard var components = URLComponents(string: "\(baseURL)/\(path)") else {
            throw APIError(code: 400, message: "無效的 URL")
        }
        
        // 添加查詢參數
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            throw APIError(code: 400, message: "無效的 URL")
        }
        
        print("發送請求到: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval // 設置更長的超時時間
        
        // 添加認證頭（如需要）
        // request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return try await performRequest(request)
    }
    
    // APIService.swift 中修改的內容
    
    // MARK: - 獲取股利資料
    func getDividendData(symbol: String) async throws -> DividendResponse {
        // 修改 path 的格式，確保股票代號前面添加 t_ 後面添加 _data
        let path = "get_t_\(symbol)_data"
        
        do {
            // 添加打印來追蹤API調用
            print("正在獲取股利資料，股票代號: \(symbol), 路徑: \(path)")
            
            // 修改：添加重試機制
            let maxRetries = 3
            var retryCount = 0
            var lastError: Error? = nil
            
            while retryCount < maxRetries {
                do {
                    // 修改這裡，直接使用 path 而不是使用 queryItems
                    let response: DividendResponse = try await get(path: path)
                    print("API返回：\(response.data.count) 條股利記錄")
                    return response
                } catch let error {
                    lastError = error
                    print("嘗試 #\(retryCount + 1) 失敗: \(error.localizedDescription)")
                    retryCount += 1
                    
                    // 添加延遲重試
                    if retryCount < maxRetries {
                        try await Task.sleep(nanoseconds: UInt64(1_000_000_000)) // 延遲1秒
                    }
                }
            }
            
            // 所有重試失敗後，拋出最後一個錯誤
            throw lastError ?? APIError(code: 1, message: "多次嘗試後仍無法連接")
        } catch {
            print("獲取股利資料失敗: \(error.localizedDescription)")
            
            // 增加更詳細的錯誤處理
            if let apiError = error as? APIError {
                throw apiError
            } else if let urlError = error as? URLError {
                throw APIError(code: urlError.code.rawValue, message: "連接服務器失敗: \(urlError.localizedDescription)")
            }
            
            throw APIError(code: 1, message: "網絡錯誤: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 執行請求
    private func performRequest<DiviModel: Decodable>(_ request: URLRequest) async throws -> DiviModel {
        do {
            // 執行請求
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 簡化日誌記錄
            if let httpResponse = response as? HTTPURLResponse {
                print("收到HTTP狀態碼: \(httpResponse.statusCode)")
            }
            
            // 檢查響應狀態碼
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(code: 0, message: "無效的響應")
            }
            
            // 檢查狀態碼是否表示成功
            guard (200...299).contains(httpResponse.statusCode) else {
                // 處理錯誤響應
                return try handleErrorResponse(data: data, statusCode: httpResponse.statusCode)
            }
            
            // 解碼響應
            return try decodeResponse(data: data)
        } catch let error as APIError {
            throw error
        } catch let urlError as URLError {
            // 更簡潔的URL錯誤處理
            throw handleURLError(urlError)
        } catch {
            throw APIError(code: 0, message: "未知錯誤: \(error.localizedDescription)")
        }
    }
    
    // 處理HTTP錯誤響應
    private func handleErrorResponse<DiviModel: Decodable>(data: Data, statusCode: Int) throws -> DiviModel {
        do {
            // 嘗試解析錯誤消息
            let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError(code: statusCode, message: errorResponse.message)
        } catch let decodeError where !(decodeError is APIError) {
            // 返回更有描述性的錯誤信息
            let errorMessage: String
            switch statusCode {
            case 400...499:
                errorMessage = "請求錯誤，請檢查API參數: \(statusCode)"
            case 500...599:
                errorMessage = "服務器內部錯誤，請聯繫後端開發人員: \(statusCode)"
            default:
                errorMessage = "請求失敗: \(statusCode)"
            }
            
            throw APIError(code: statusCode, message: errorMessage)
        }
    }
    
    // 處理URL錯誤
    private func handleURLError(_ error: URLError) -> APIError {
        switch error.code {
        case .timedOut:
            return APIError(code: 3, message: "請求超時，請檢查網絡連接或稍後再試")
        case .notConnectedToInternet:
            return APIError(code: 1, message: "網絡未連接，請檢查您的網絡設置")
        case .cannotFindHost, .cannotConnectToHost:
            return APIError(code: 4, message: "無法連接到服務器，請檢查服務器是否在線")
        default:
            return APIError(code: error.code.rawValue, message: "網絡錯誤: \(error.localizedDescription)")
        }
    }
    
    // 解碼響應數據
    private func decodeResponse<DiviModel: Decodable>(data: Data) throws -> DiviModel {
        // 設置解碼器
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
        
        // 嘗試直接解析
        do {
            return try decoder.decode(DiviModel.self, from: data)
        } catch {
            // 如果是DividendResponse類型且解析失敗，嘗試特殊處理
            if DiviModel.self == DividendResponse.self {
                return try handleDividendResponseParsing(data: data, error: error) as! DiviModel
            }
            throw APIError(code: 2, message: "解析數據失敗: \(error.localizedDescription)")
        }
    }
    
    // 處理DividendResponse解析的特殊情況
    private func handleDividendResponseParsing(data: Data, error: Error) throws -> DividendResponse {
        // 嘗試解析為JSON數組
        if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [Any] {
            print("API 返回的是陣列，而非字典，嘗試使用備用模型解析")
            
            var dividendRecords: [DividendRecord] = []
            
            // 解析每一項
            for (index, item) in jsonArray.enumerated() {
                if let itemDict = item as? [String: Any] {
                    // 處理id欄位
                    var safeDict = itemDict
                    safeDict["id"] = safeDict["id"] != nil ? "\(safeDict["id"]!)" : "\(index)"
                    
                    // 處理特殊欄位
                    for (key, value) in itemDict {
                        if value is NSNull {
                            handleNullValue(key: key, dict: &safeDict)
                        } else if let strValue = value as? String, strValue == "nan" {
                            handleNanValue(key: key, dict: &safeDict)
                        }
                    }
                    
                    // 轉換為DividendRecord
                    if let itemData = try? JSONSerialization.data(withJSONObject: safeDict),
                       let record = try? JSONDecoder().decode(DividendRecord.self, from: itemData) {
                        dividendRecords.append(record)
                    }
                }
            }
            
            print("API返回：\(dividendRecords.count) 條股利記錄")
            
            // 創建響應
            if !dividendRecords.isEmpty {
                return DividendResponse(success: true, data: dividendRecords, message: nil)
            }
        }
        
        // 如果上述處理都失敗，返回空結果集
        return DividendResponse(success: false, data: [], message: "解析失敗: \(error.localizedDescription)")
    }
    
    // 處理空值
    private func handleNullValue(key: String, dict: inout [String: Any]) {
        if key == "ex_dividend_reference_price" ||
            key == "ex_rights_reference_price" ||
            key.hasSuffix("_dividend") ||
            key.hasSuffix("_earnings") ||
            key.hasSuffix("_surplus") {
            dict[key] = 0.0
        } else if key.hasSuffix("_days") {
            dict[key] = 0
        } else if key.hasSuffix("_date") {
            dict[key] = ""
        }
    }
    
    // 處理"nan"值
    private func handleNanValue(key: String, dict: inout [String: Any]) {
        if key == "ex_dividend_reference_price" ||
            key == "ex_rights_reference_price" ||
            key.hasSuffix("_dividend") ||
            key.hasSuffix("_earnings") ||
            key.hasSuffix("_surplus") {
            dict[key] = 0.0
        } else if key.hasSuffix("_days") {
            dict[key] = 0
        } else {
            dict[key] = ""
        }
    }
}
