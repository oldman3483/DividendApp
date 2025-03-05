import Foundation
import PostgresClientKit

class PostgresService {
    // MARK: - 單例模式
    static let shared = PostgresService()
    
    // MARK: - 資料庫連接配置
    private var connectionConfiguration: ConnectionConfiguration!
    
    // MARK: - 初始化
    private init() {
        setupConnectionConfiguration()
    }
    
    private func setupConnectionConfiguration() {
        // 配置資料庫連接參數（請替換為您的實際連接信息）
        var config = PostgresClientKit.ConnectionConfiguration()
        
        // 資料庫連接信息
        config.host = "34.56.5.186" // 主機地址
        config.port = 5432 // 預設 PostgreSQL 端口
        config.database = "postgres-1" // 資料庫名稱
        config.user = "postgres" // 使用者名稱
        config.credential = .md5Password(password: "000000")
        
        // 配置 SSL（根據 GCP 的要求，通常需要啟用）
        config.ssl = true
        
        // 保存配置
        self.connectionConfiguration = config
    }
    
    // MARK: - 輔助方法
    
    // 將Date轉換為PostgreSQL可接受的時間戳字符串
    private func dateToPostgresString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // MARK: - 公共方法
    
    /// 測試資料庫連接
    func testConnection() async throws -> Bool {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            let statement = try connection.prepareStatement(text: "SELECT 1")
            defer { statement.close() }
            
            let cursor = try statement.execute()
            defer { cursor.close() }
            
            return true
        } catch {
            print("資料庫連接測試失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 獲取所有銀行
    func fetchBanks() async throws -> [Bank] {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            let statement = try connection.prepareStatement(text: "SELECT id, name, created_date FROM banks ORDER BY name")
            defer { statement.close() }
            
            let cursor = try statement.execute()
            defer { cursor.close() }
            
            var banks: [Bank] = []
            
            for row in cursor {
                let columns = try row.get().columns
                do {
                    if let uuidString = try columns[0].optionalString(),
                       let id = UUID(uuidString: uuidString),
                       let name = try columns[1].optionalString(),
                       let postgresDate = try columns[2].optionalTimestamp() {
                        
                        // 將 PostgresTimestamp 轉換為 Date
                        let createdDate = postgresDate.date(in: TimeZone.current)

                        banks.append(Bank(id: id, name: name, createdDate: createdDate))
                    }
                } catch {
                    print("處理銀行行資料時出錯: \(error)")
                    continue
                }
            }
            
            return banks
        } catch {
            print("獲取銀行失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 新增銀行
    func addBank(_ bank: Bank) async throws -> Bank {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            let statement = try connection.prepareStatement(
                text: "INSERT INTO banks (id, name, created_date) VALUES ($1, $2, $3) RETURNING id"
            )
            defer { statement.close() }
            
            // 使用自定義方法轉換日期
            let postgresCreatedDate = dateToPostgresString(bank.createdDate)
            
            let cursor = try statement.execute(parameterValues: [
                PostgresValue(bank.id.uuidString),
                PostgresValue(bank.name),
                PostgresValue(postgresCreatedDate)
            ])
            defer { cursor.close() }
            
            return bank
        } catch {
            print("新增銀行失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 更新銀行
    func updateBank(_ bank: Bank) async throws {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            let statement = try connection.prepareStatement(
                text: "UPDATE banks SET name = $1 WHERE id = $2"
            )
            defer { statement.close() }
            
            let _ = try statement.execute(parameterValues: [
                PostgresValue(bank.name),
                PostgresValue(bank.id.uuidString)
            ])
        } catch {
            print("更新銀行失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 刪除銀行
    func deleteBank(withId id: UUID) async throws {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            // 首先刪除相關的股票（假設有外鍵關係）
            let deleteStocksStatement = try connection.prepareStatement(
                text: "DELETE FROM stocks WHERE bank_id = $1"
            )
            defer { deleteStocksStatement.close() }
            
            let _ = try deleteStocksStatement.execute(parameterValues: [
                PostgresValue(id.uuidString)
            ])
            
            // 然後刪除銀行
            let deleteBankStatement = try connection.prepareStatement(
                text: "DELETE FROM banks WHERE id = $1"
            )
            defer { deleteBankStatement.close() }
            
            let _ = try deleteBankStatement.execute(parameterValues: [
                PostgresValue(id.uuidString)
            ])
        } catch {
            print("刪除銀行失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 獲取所有股票
    func fetchStocks() async throws -> [Stock] {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            let statement = try connection.prepareStatement(text: """
                SELECT 
                    id, symbol, name, shares, dividend_per_share, 
                    dividend_year, is_historical, frequency, purchase_date, 
                    purchase_price, bank_id, regular_investment
                FROM stocks
                ORDER BY symbol, purchase_date
            """)
            defer { statement.close() }
            
            let cursor = try statement.execute()
            defer { cursor.close() }
            
            var stocks: [Stock] = []
            
            for row in cursor {
                do {
                    let columns = try row.get().columns
                    
                    // 讀取並轉換UUID
                    guard let idString = try columns[0].optionalString(),
                          let id = UUID(uuidString: idString),
                          let symbol = try columns[1].optionalString(),
                          let name = try columns[2].optionalString(),
                          let shares = try columns[3].optionalInt(),
                          let dividendPerShare = try columns[4].optionalDouble(),
                          let dividendYear = try columns[5].optionalInt(),
                          let isHistorical = try columns[6].optionalBool(),
                          let frequency = try columns[7].optionalInt(),
                          let purchaseDatePostgres = try columns[8].optionalTimestamp(),
                          let bankIdString = try columns[10].optionalString(),
                          let bankId = UUID(uuidString: bankIdString) else {
                        continue
                    }
                    
                    // Int類型已經是正確類型，無需轉換
                    
                    // 將 PostgresTimestamp 轉換為 Date
                    let purchaseDate = purchaseDatePostgres.date(in: TimeZone.current)

                    // 處理可為空的欄位
                    let purchasePrice: Double?
                    if try columns[9].isNull {
                        purchasePrice = nil
                    } else {
                        purchasePrice = try columns[9].optionalDouble()
                    }
                    
                    // 處理 JSON 欄位 regular_investment
                    let regularInvestment: RegularInvestment?
                    if try columns[11].isNull {
                        regularInvestment = nil
                    } else if let jsonString = try columns[11].optionalString() {
                        let jsonData = jsonString.data(using: .utf8)!
                        let decoder = JSONDecoder()
                        regularInvestment = try decoder.decode(RegularInvestment.self, from: jsonData)
                    } else {
                        regularInvestment = nil
                    }
                    
                    stocks.append(Stock(
                        id: id,
                        symbol: symbol,
                        name: name,
                        shares: shares,
                        dividendPerShare: dividendPerShare,
                        dividendYear: dividendYear,
                        isHistorical: isHistorical,
                        frequency: frequency,
                        purchaseDate: purchaseDate,
                        purchasePrice: purchasePrice,
                        bankId: bankId,
                        regularInvestment: regularInvestment
                    ))
                } catch {
                    print("處理股票行資料時出錯: \(error)")
                    continue
                }
            }
            
            return stocks
        } catch {
            print("獲取股票失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 添加股票
    func addStock(_ stock: Stock) async throws -> Stock {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            // 將 RegularInvestment 轉換為 JSON 字符串
            let regularInvestmentJson: String?
            if let regularInvestment = stock.regularInvestment {
                let encoder = JSONEncoder()
                let jsonData = try encoder.encode(regularInvestment)
                regularInvestmentJson = String(data: jsonData, encoding: .utf8)
            } else {
                regularInvestmentJson = nil
            }
            
            let statement = try connection.prepareStatement(text: """
                INSERT INTO stocks (
                    id, symbol, name, shares, dividend_per_share, 
                    dividend_year, is_historical, frequency, purchase_date, 
                    purchase_price, bank_id, regular_investment
                ) VALUES (
                    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
                ) RETURNING id
            """)
            defer { statement.close() }
            
            // 使用自定義方法轉換日期
            let postgresPurchaseDate = dateToPostgresString(stock.purchaseDate)
            
            var parameterValues: [PostgresValue] = [
                PostgresValue(stock.id.uuidString),
                PostgresValue(stock.symbol),
                PostgresValue(stock.name),
                PostgresValue(String(stock.shares)),
                PostgresValue(String(stock.dividendPerShare)),
                PostgresValue(String(stock.dividendYear)),
                PostgresValue(String(stock.isHistorical)),
                PostgresValue(String(stock.frequency)),
                PostgresValue(postgresPurchaseDate)
            ]
            
            // 處理可為空的購買價格
            if let purchasePrice = stock.purchasePrice {
                parameterValues.append(PostgresValue(String(purchasePrice)))
            } else {
                parameterValues.append(PostgresValue.null)
            }
            
            // 添加銀行ID
            parameterValues.append(PostgresValue(stock.bankId.uuidString))
            
            // 處理可為空的定期定額設定JSON
            if let regularInvestmentJson = regularInvestmentJson {
                parameterValues.append(PostgresValue(regularInvestmentJson))
            } else {
                parameterValues.append(PostgresValue.null)
            }
            
            let cursor = try statement.execute(parameterValues: parameterValues)
            defer { cursor.close() }
            
            return stock
        } catch {
            print("添加股票失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 更新股票
    func updateStock(_ stock: Stock) async throws {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            // 將 RegularInvestment 轉換為 JSON 字符串
            let regularInvestmentJson: String?
            if let regularInvestment = stock.regularInvestment {
                let encoder = JSONEncoder()
                let jsonData = try encoder.encode(regularInvestment)
                regularInvestmentJson = String(data: jsonData, encoding: .utf8)
            } else {
                regularInvestmentJson = nil
            }
            
            // 使用自定義方法轉換日期
            let postgresPurchaseDate = dateToPostgresString(stock.purchaseDate)
            
            let statement = try connection.prepareStatement(text: """
                UPDATE stocks 
                SET 
                    symbol = $1, 
                    name = $2, 
                    shares = $3, 
                    dividend_per_share = $4,
                    dividend_year = $5, 
                    is_historical = $6, 
                    frequency = $7, 
                    purchase_date = $8,
                    purchase_price = $9, 
                    regular_investment = $10
                WHERE id = $11
            """)
            defer { statement.close() }
            
            var parameterValues: [PostgresValue] = [
                PostgresValue(stock.symbol),
                PostgresValue(stock.name),
                PostgresValue(String(stock.shares)),
                PostgresValue(String(stock.dividendPerShare)),
                PostgresValue(String(stock.dividendYear)),
                PostgresValue(String(stock.isHistorical)),
                PostgresValue(String(stock.frequency)),
                PostgresValue(postgresPurchaseDate)
            ]
            
            // 處理可為空的購買價格
            if let purchasePrice = stock.purchasePrice {
                parameterValues.append(PostgresValue(String(purchasePrice)))
            } else {
                parameterValues.append(PostgresValue.null)
            }
            
            // 處理可為空的定期定額設定JSON
            if let regularInvestmentJson = regularInvestmentJson {
                parameterValues.append(PostgresValue(regularInvestmentJson))
            } else {
                parameterValues.append(PostgresValue.null)
            }
            
            // 添加ID
            parameterValues.append(PostgresValue(stock.id.uuidString))
            
            let _ = try statement.execute(parameterValues: parameterValues)
        } catch {
            print("更新股票失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 刪除股票
    func deleteStock(withId id: UUID) async throws {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            let statement = try connection.prepareStatement(
                text: "DELETE FROM stocks WHERE id = $1"
            )
            defer { statement.close() }
            
            let _ = try statement.execute(parameterValues: [
                PostgresValue(id.uuidString)
            ])
        } catch {
            print("刪除股票失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 獲取觀察清單
    func fetchWatchlist() async throws -> [WatchStock] {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            let statement = try connection.prepareStatement(text: """
                SELECT 
                    id, symbol, name, added_date, list_name
                FROM watchlist
                ORDER BY list_name, added_date
            """)
            defer { statement.close() }
            
            let cursor = try statement.execute()
            defer { cursor.close() }
            
            var watchlist: [WatchStock] = []
            
            for row in cursor {
                do {
                    let columns = try row.get().columns
                    
                    guard let idString = try columns[0].optionalString(),
                          let id = UUID(uuidString: idString),
                          let symbol = try columns[1].optionalString(),
                          let name = try columns[2].optionalString(),
                          let addedDatePostgres = try columns[3].optionalTimestamp(),
                          let listName = try columns[4].optionalString() else {
                        continue
                    }
                    
                    // 將 PostgresTimestamp 轉換為 Date
                    let addedDate = addedDatePostgres.date(in: TimeZone.current)

                    watchlist.append(WatchStock(
                        id: id,
                        symbol: symbol,
                        name: name,
                        addedDate: addedDate,
                        listName: listName
                    ))
                } catch {
                    print("處理觀察清單行資料時出錯: \(error)")
                    continue
                }
            }
            
            return watchlist
        } catch {
            print("獲取觀察清單失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 添加觀察股票
    func addWatchStock(_ watchStock: WatchStock) async throws -> WatchStock {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            let statement = try connection.prepareStatement(text: """
                INSERT INTO watchlist (
                    id, symbol, name, added_date, list_name
                ) VALUES (
                    $1, $2, $3, $4, $5
                ) RETURNING id
            """)
            defer { statement.close() }
            
            // 使用自定義方法轉換日期
            let postgresAddedDate = dateToPostgresString(watchStock.addedDate)
            
            let cursor = try statement.execute(parameterValues: [
                PostgresValue(watchStock.id.uuidString),
                PostgresValue(watchStock.symbol),
                PostgresValue(watchStock.name),
                PostgresValue(postgresAddedDate),
                PostgresValue(watchStock.listName)
            ])
            defer { cursor.close() }
            
            return watchStock
        } catch {
            print("添加觀察股票失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 更新觀察股票
    func updateWatchStock(_ watchStock: WatchStock) async throws {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            let statement = try connection.prepareStatement(text: """
                UPDATE watchlist 
                SET 
                    symbol = $1, 
                    name = $2, 
                    list_name = $3
                WHERE id = $4
            """)
            defer { statement.close() }
            
            let _ = try statement.execute(parameterValues: [
                PostgresValue(watchStock.symbol),
                PostgresValue(watchStock.name),
                PostgresValue(watchStock.listName),
                PostgresValue(watchStock.id.uuidString)
            ])
        } catch {
            print("更新觀察股票失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 刪除觀察股票
    func deleteWatchStock(withId id: UUID) async throws {
        do {
            let connection = try Connection(configuration: connectionConfiguration)
            defer { connection.close() }
            
            let statement = try connection.prepareStatement(
                text: "DELETE FROM watchlist WHERE id = $1"
            )
            defer { statement.close() }
            
            let _ = try statement.execute(parameterValues: [
                PostgresValue(id.uuidString)
            ])
        } catch {
            print("刪除觀察股票失敗: \(error.localizedDescription)")
            throw error
        }
    }
}

// 擴展 PostgresValue 以提供 null 值支持
extension PostgresValue {
    static var null: PostgresValue {
        // 根據 PostgresClientKit 的文檔，這是創建 NULL 值的方式
        return PostgresValue(nil as String?)
    }
}

// 添加擴展方法來更安全地處理可選值
extension PostgresValue {
    func optionalString() throws -> String? {
        do {
            return try isNull ? nil : string()
        } catch {
            return nil
        }
    }
    
    func optionalInt() throws -> Int? {
        do {
            return try isNull ? nil : int()
        } catch {
            return nil
        }
    }
    
    func optionalDouble() throws -> Double? {
        do {
            return try isNull ? nil : double()
        } catch {
            return nil
        }
    }
    
    func optionalBool() throws -> Bool? {
        do {
            return try isNull ? nil : bool()
        } catch {
            return nil
        }
    }
    
    func optionalTimestamp() throws -> PostgresTimestamp? {
        do {
            return try isNull ? nil : timestamp()
        } catch {
            return nil
        }
    }
}
