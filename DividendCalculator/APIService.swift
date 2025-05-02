//
//  APIService.swift
//  DividendCalculator
//
//  Created on 2025/3/6.
//

import Foundation

// MARK: - API 錯誤
struct APIError: Error {
    let code: Int
    let message: String
}

// MARK: - API 服務
class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://postgres-1-148949302162.asia-east1.run.app"
    
    private init() {}
    
    // MARK: - 通用 GET 請求
    func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(string: "\(baseURL)/\(path)") else {
            throw APIError(code: 400, message: "無效的 URL")
        }
        
        // 添加查詢參數
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components.url else {
            throw APIError(code: 400, message: "無效的 URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加認證頭（如需要）
        // request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return try await performRequest(request)
    }
    
    // MARK: - 獲取股利資料
    func getDividendData(symbol: String) async throws -> DividendResponse {
        // 表名格式為 t_{股票代號}
        let tableName = "t_\(symbol)"
        let queryItems = [URLQueryItem(name: "table_name", value: tableName)]
        
        do {
            return try await get(path: "data", queryItems: queryItems)
        } catch {
            print("獲取股利資料失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 執行請求
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            // 執行請求
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 檢查響應狀態碼
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(code: 0, message: "無效的響應")
            }
            
            // 檢查狀態碼是否表示成功
            guard (200...299).contains(httpResponse.statusCode) else {
                // 嘗試解析錯誤消息
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    throw APIError(code: httpResponse.statusCode, message: errorResponse.message)
                } catch {
                    throw APIError(code: httpResponse.statusCode, message: "請求失敗: \(httpResponse.statusCode)")
                }
            }
            
            // 解碼響應
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError(code: 0, message: "網絡錯誤: \(error.localizedDescription)")
        }
    }
}

// 用於錯誤響應的解碼
struct ErrorResponse: Decodable {
    let success: Bool
    let message: String
}
