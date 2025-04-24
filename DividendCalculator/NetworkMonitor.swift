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
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
