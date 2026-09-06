import Foundation
import Network

/// Соединение прокси, перенаправляющее трафик между клиентом и Telegram DC
actor ProxyConnection {
    let id: UInt64
    private let clientConnection: NWConnection
    private let config: ProxyConfig
    private var clientTask: Task<Void, Error>?
    private var serverTask: Task<Void, Error>?
    private var serverClient: ProxyClient?
    
    /// Closure для уведомлений о статусе
    var statusHandler: ((ConnectionStatus) -> Void)?
    
    enum ConnectionStatus {
        case connecting
        case active
        case closed(id: UInt64)
        case error(String)
        case bytesTransferred(direction: Direction, bytes: Int)
    }
    
    enum Direction: String {
        case clientToServer
        case serverToClient
    }
    
    init(id: UInt64, clientConnection: NWConnection, config: ProxyConfig) {
        self.id = id
        self.clientConnection = clientConnection
        self.config = config
    }
    
    /// Запуск прокси-соединения
    func start() async {
        statusHandler?(.connecting)
        
        // Создаём клиент для подключения к Telegram DC
        serverClient = ProxyClient(dcAddress: config.dcAddress, dcPort: config.dcPort)
        serverClient?.statusHandler = { [weak self] status in
            self?.handleServerStatus(status)
        }
        
        do {
            try await serverClient?.connect()
            statusHandler?(.active)
            
            // Запускаем двунаправленную передачу данных
            clientTask = Task { [weak self] in
                await self?.forwardData(fromClient: true)
            }
            
            serverTask = Task { [weak self] in
                await self?.forwardData(fromClient: false)
            }
            
            // Ждём завершения одного из потоков
            let result = await Task {
                if let clientTask = self?.clientTask {
                    _ = await clientTask.value
                    return true
                }
                return false
            }.value
            
            // Закрываем соединение
            close()
            
        } catch {
            statusHandler?(.error("Connection failed: \(error.localizedDescription)"))
            close()
        }
    }
    
    /// Двунаправленная передача данных
    private func forwardData(fromClient: Bool) async {
        guard let serverClient = serverClient else { return }
        
        while true {
            do {
                var data: Data
                
                if fromClient {
                    // Читаем от клиента
                    data = try await readFromClient()
                    
                    // Отправляем на сервер Telegram
                    try await serverClient.send(data: data)
                    statusHandler?(.bytesTransferred(direction: .clientToServer, bytes: data.count))
                } else {
                    // Читаем от сервера Telegram
                    data = try await serverClient.receive()
                    
                    // Отправляем клиенту
                    try await sendToClient(data: data)
                    statusHandler?(.bytesTransferred(direction: .serverToClient, bytes: data.count))
                }
            } catch {
                // Соединение закрыто или ошибка
                break
            }
        }
    }
    
    /// Чтение данных от клиента
    private func readFromClient() async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            clientConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, context, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let content = content, !content.isEmpty {
                    continuation.resume(returning: content)
                } else if context?.isFinal == true {
                    continuation.resume(throwing: ProxyError.connectionClosed)
                } else {
                    continuation.resume(throwing: ProxyError.emptyData)
                }
            }
        }
    }
    
    /// Отправка данных клиенту
    private func sendToClient(data: Data) async throws {
        try await withCheckedThrowingContinuation { continuation in
            clientConnection.send(content: data) { [weak self] in
                self?.statusHandler?(.bytesTransferred(direction: .serverToClient, bytes: data.count))
                continuation.resume()
            }
        }
    }
    
    /// Обработка статуса серверного клиента
    private func handleServerStatus(_ status: ProxyClient.ClientStatus) {
        switch status {
        case .error(let message):
            statusHandler?(.error(message))
        case .disconnected:
            break
        default:
            break
        }
    }
    
    /// Закрытие соединения
    func close() {
        clientTask?.cancel()
        serverTask?.cancel()
        clientConnection.cancel()
        serverClient?.disconnect()
        statusHandler?(.closed(id: id))
    }
}
