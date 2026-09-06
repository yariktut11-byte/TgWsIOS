import Foundation
import Network

/// Прокси-сервер, прослушивающий входящие TCP-соединения
/// и перенаправляющий их на серверы Telegram
actor ProxyServer {
    private var listener: NWListener?
    private var isRunning = false
    private var activeConnections: [UInt64: ProxyConnection] = [:]
    private let config: ProxyConfig
    private var connectionCounter: UInt64 = 0
    
    /// Closure для уведомлений о статусе
    var statusHandler: ((ProxyServerStatus) -> Void)?
    
    enum ProxyServerStatus {
        case starting
        case started(port: Int)
        case stopped
        case error(String)
        case connectionOpened(id: UInt64)
        case connectionClosed(id: UInt64)
    }
    
    init(config: ProxyConfig) {
        self.config = config
    }
    
    /// Запуск прослушивания
    func start() async {
        guard !isRunning else { return }
        
        isRunning = true
        statusHandler?(.starting)
        
        do {
            // Настраиваем параметры для MTProto-прокси
            // Используем TCP без TLS, т.к. прокси сам обрабатывает MTProto
            let parameters = NWListener.Parameters()
            parameters.requireLocalNetworkEnclosure = false
            
            listener = try NWListener(using: parameters)
            listener?.port = .init(UInt16(config.localPort))
            
            // Обработка входящих соединений
            listener?.newConnectionHandler = { [weak self] connection in
                guard let self = self else { return }
                self.handleNewConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] newState in
                switch newState {
                case .ready:
                    self?.statusHandler?(.started(port: self?.config.localPort ?? 0))
                case .failed(let error):
                    self?.statusHandler?(.error("Listener failed: \(error.localizedDescription)"))
                    self?.stop()
                case .cancelled:
                    self?.statusHandler?(.stopped)
                    self?.isRunning = false
                default:
                    break
                }
            }
            
            listener?.start(queue: .main)
            statusHandler?(.started(port: config.localPort))
            
        } catch {
            statusHandler?(.error("Failed to start listener: \(error.localizedDescription)"))
            isRunning = false
        }
    }
    
    /// Обработка нового входящего соединения
    private func handleNewConnection(_ connection: NWConnection) {
        guard isRunning else { return }
        
        // Проверка лимита соединений
        if activeConnections.count >= config.maxConnections {
            connection.cancel()
            return
        }
        
        let connectionId = connectionCounter
        connectionCounter += 1
        
        // Создаём прокси-соединение
        let proxyConnection = ProxyConnection(
            id: connectionId,
            clientConnection: connection,
            config: config
        )
        
        proxyConnection.statusHandler = { [weak self] status in
            self?.handleConnectionStatus(status)
        }
        
        activeConnections[connectionId] = proxyConnection
        statusHandler?(.connectionOpened(id: connectionId))
        
        // Запускаем прокси-соединение
        Task {
            await proxyConnection.start()
        }
    }
    
    /// Обработка статуса соединения
    private func handleConnectionStatus(_ status: ProxyConnection.ConnectionStatus) {
        switch status {
        case .closed(let id):
            activeConnections.removeValue(forKey: id)
            statusHandler?(.connectionClosed(id: id))
        default:
            break
        }
    }
    
    /// Остановка сервера
    func stop() {
        isRunning = false
        listener?.cancel()
        listener = nil
        
        // Закрытие всех активных соединений
        for (_, connection) in activeConnections {
            connection.close()
        }
        activeConnections.removeAll()
        
        statusHandler?(.stopped)
    }
    
    /// Количество активных соединений
    var connectionCount: Int {
        return activeConnections.count
    }
}
