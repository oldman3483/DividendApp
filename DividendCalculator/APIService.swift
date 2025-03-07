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
    
    private let baseURL = "https://postgres-1-148949302162.asia-east1.run.app/data" // 替換成實際 API URL
    
    private init() {}
    
    // MARK: - 通用 GET 請求
    func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        guard var components = URLComponents(string: "\(baseURL)/\(path)") else {
            throw APIError(code: 400, message: "無效的 URL")
        }
        
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
    
    // MARK: - 通用 POST 請求
    func post<T: Decodable, E: Encodable>(path: String, body: E) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(path)") else {
            throw APIError(code: 400, message: "無效的 URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加認證頭（如需要）
        // request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // 編碼請求體
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        return try await performRequest(request)
    }
    
    // MARK: - 通用 PUT 請求
    func put<T: Decodable, E: Encodable>(path: String, body: E) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(path)") else {
            throw APIError(code: 400, message: "無效的 URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 編碼請求體
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        return try await performRequest(request)
    }
    
    // MARK: - 通用 DELETE 請求
    func delete<T: Decodable>(path: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(path)") else {
            throw APIError(code: 400, message: "無效的 URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return try await performRequest(request)
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
