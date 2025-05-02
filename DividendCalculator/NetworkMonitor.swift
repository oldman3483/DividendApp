//
//  NetworkMonitor.swift
//  DividendCalculator
//
//  Created by Heidie Lee on 2025/4/25.
//

import Foundation
import Network

// 創建一個專門用於監視網絡狀態的類
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    // 連接類型枚舉
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    var currentPath: NWPath {
        return monitor.currentPath
    }
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
    
    // 檢查特定服務器連接
    func checkServerConnection(urlString: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false, "無效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD" // 只檢查連接，不下載內容
        request.timeoutInterval = 10.0
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(false, "連接失敗: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "無效的響應")
                return
            }
            
            // 檢查狀態碼，2xx 和 3xx 表示服務器正常
            let isSuccess = (200...399).contains(httpResponse.statusCode)
            let message = isSuccess ? "連接成功" : "服務器返回錯誤: \(httpResponse.statusCode)"
            completion(isSuccess, message)
        }
        
        task.resume()
    }
    
    // 測試下載速度
    func testDownloadSpeed(completion: @escaping (Double?) -> Void) {
        let testFileURL = URL(string: "https://speed.cloudflare.com/10mb")!
        let startTime = Date()
        
        let task = URLSession.shared.dataTask(with: testFileURL) { data, _, _ in
            if let data = data {
                let endTime = Date()
                let timeInterval = endTime.timeIntervalSince(startTime)
                let bytesPerSecond = Double(data.count) / timeInterval
                let mbps = (bytesPerSecond * 8) / 1_000_000 // 轉換為 Mbps
                completion(mbps)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    // 測試特定 API 端點
    func testAPIEndpoint(urlString: String, queryItems: [URLQueryItem] = [], completion: @escaping (Result<Data, Error>) -> Void) {
        guard var urlComponents = URLComponents(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        
        urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = urlComponents.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "Invalid response", code: 0, userInfo: nil)))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let statusError = NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)
                completion(.failure(statusError))
                return
            }
            
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
            }
        }
        
        task.resume()
    }
    
    // 診斷網絡問題 - 修正版，處理 NSError
    func diagnoseNetworkIssues(completion: @escaping (String) -> Void) {
        guard isConnected else {
            completion("網絡未連接，請檢查您的網絡設置")
            return
        }
        
        var diagnosticReport = "網絡診斷報告：\n"
        diagnosticReport += "連接類型：\(connectionType)\n"
        
        // 檢查服務器連接
        let serverURLs = [
            "https://www.google.com",
            "https://www.apple.com",
            "https://postgres-1-148949302162.asia-east1.run.app"
        ]
        
        let group = DispatchGroup()
        var accessibleServers = 0
        
        for urlString in serverURLs {
            group.enter()
            
            checkServerConnection(urlString: urlString) { isConnected, message in
                if isConnected {
                    accessibleServers += 1
                    diagnosticReport += "\(urlString) 可以訪問\n"
                } else {
                    diagnosticReport += "\(urlString) 無法訪問: \(message ?? "未知錯誤")\n"
                }
                group.leave()
            }
        }
        
        // 當所有服務器檢查完成後
        group.notify(queue: .main) {
            if accessibleServers == 0 {
                diagnosticReport += "所有目標服務器均不可訪問，可能是網絡問題\n"
            } else if accessibleServers < serverURLs.count {
                diagnosticReport += "部分服務器不可訪問，可能是特定服務器的問題\n"
            } else {
                diagnosticReport += "所有服務器均可訪問，網絡連接正常\n"
            }
            
            // 測試下載速度
            self.testDownloadSpeed { speed in
                if let speed = speed {
                    diagnosticReport += "網絡下載速度：\(String(format: "%.2f", speed)) Mbps\n"
                    
                    if speed < 1.0 {
                        diagnosticReport += "網絡速度非常慢，可能會影響應用程序性能\n"
                    } else if speed < 5.0 {
                        diagnosticReport += "網絡速度較慢，可能會導致某些操作延遲\n"
                    } else {
                        diagnosticReport += "網絡速度良好\n"
                    }
                } else {
                    diagnosticReport += "無法測試網絡速度\n"
                }
                
                // 測試 API 端點
                let apiURL = "https://postgres-1-148949302162.asia-east1.run.app/data"
                let queryItems = [URLQueryItem(name: "table_name", value: "t_0050")]
                
                self.testAPIEndpoint(urlString: apiURL, queryItems: queryItems) { result in
                    switch result {
                    case .success:
                        diagnosticReport += "API 端點測試成功，能夠訪問資料庫\n"
                    case .failure(let error):
                        diagnosticReport += "API 端點測試失敗: \(error.localizedDescription)\n"
                        
                        // 修正的部分 - 不使用 if let 判斷 NSError
                        let nsError = error as NSError
                        switch nsError.code {
                        case NSURLErrorTimedOut:
                            diagnosticReport += "連接超時，服務器回應時間過長\n"
                        case NSURLErrorCannotConnectToHost:
                            diagnosticReport += "無法連接到服務器，請檢查服務器是否在線\n"
                        case NSURLErrorNetworkConnectionLost:
                            diagnosticReport += "網絡連接中斷，請檢查您的網絡穩定性\n"
                        case 400...499:
                            diagnosticReport += "客戶端錯誤，請檢查請求參數是否正確\n"
                        case 500...599:
                            diagnosticReport += "服務器錯誤，請聯繫後端開發人員\n"
                        default:
                            diagnosticReport += "未知錯誤，錯誤代碼: \(nsError.code)\n"
                        }
                    }
                    
                    diagnosticReport += "\n解決建議：\n"
                    
                    if accessibleServers < serverURLs.count {
                        let backendNotAccessible = !serverURLs.contains { urlString in
                            urlString.contains("postgres-1-148949302162.asia-east1.run.app") &&
                            accessibleServers > 0
                        }
                        
                        if backendNotAccessible {
                            diagnosticReport += "- 您的後端服務器可能未啟動或地址錯誤，請檢查\n"
                        }
                    }
                    
                    if case .failure = result {
                        diagnosticReport += "- 嘗試重啟應用程序\n"
                        diagnosticReport += "- 檢查您的網絡連接是否穩定\n"
                        diagnosticReport += "- 確認 API 地址和參數是否正確\n"
                        diagnosticReport += "- 聯繫後端維護人員檢查服務器狀態\n"
                    }
                    
                    completion(diagnosticReport)
                }
            }
        }
    }
}
