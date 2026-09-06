import Foundation
import Network

/// Прокси-клиент, устанавливающий соединение с серверами Telegram
actor ProxyClient {
    private var connection: NWConnection?
    private var isConnected = false
    private let dcAddress: String
    private let dcPort: Int
    
    /// Closure для уведомлений о статусе
    var statusHandler: ((ClientStatus) -> Void)?
    
    enum ClientStatus {
        case connecting
        case connected
        case disconnected
        case error(String)
    }
    
    init(dcAddress: String, dcPort: Int) {
        self.dcAddress = dcAddress
        self.dcPort = dcPort
    }
    
    /// Подключение к Telegram DC
    func connect() async throws {
        guard !isConnected else { return }
        
        statusHandler?(.connecting)
        
        // Определяем тип подключения (IPv4 или IPv6)
        let endpoint: NWEndpoint
        if let ipv4Addr = IPv4Address(dcAddress) {
            endpoint = .internetHostPort(
                ipv4: ipv4Addr,
                port: .init(UInt16(dcPort))
            )
        } else if let ipv6Addr = IPv6Address(dcAddress) {
            endpoint = .internetHostPort(
                ipv6: ipv6Addr,
                port: .init(UInt16(dcPort))
            )
        } else {
            // Используем хостнейм
            endpoint = .hostPort(
                host: .init(dcAddress) ?? .ipv4Loopback,
                port: .init(UInt16(dcPort))
            )
        }
        
        let connection = NWConnection(to: endpoint, using: parameters)
        self.connection = connection
        isConnected = true
        
        // Начинаем соединение
        connection.start(queue: .global(qos: .userInitiated))
        
        // Ждём установки соединения
        await withCheckedContinuation { continuation in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    self.statusHandler?(.connected)
                    continuation.resume()
                case .failed(let error):
                    self.statusHandler?(.error(error.localizedDescription))
                    self.isConnected = false
                    continuation.resume()
                case .cancelled:
                    self.isConnected = false
                    continuation.resume()
                default:
                    break
                }
            }
        }
    }
    
    /// Отправка данных на сервер Telegram
    func send(data: Data) async throws {
        guard let connection = connection, isConnected else {
            throw ProxyError.notConnected
        }
        
        try await connection.send(content: data)
    }
    
    /// Получение данных от сервера Telegram
    func receive() async throws -> Data {
        guard let connection = connection else {
            throw ProxyError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Получаем данные с минимальным размером буфера
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, context, error in
                if let error = error {
                    self?.statusHandler?(.error(error.localizedDescription))
                    continuation.resume(throwing: error)
                    return
                }
                
                if let content = content, !content.isEmpty {
                    continuation.resume(returning: content)
                } else if context?.isFinal == true {
                    self?.isConnected = false
                    self?.statusHandler?(.disconnected)
                    continuation.resume(throwing: ProxyError.connectionClosed)
                } else {
                    continuation.resume(throwing: ProxyError.emptyData)
                }
            }
        }
    }
    
    /// Закрытие соединения
    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
        statusHandler?(.disconnected)
    }
    
    private var parameters: NWParameters {
        let options: NWProtocolTCP.Options = .tcp
        options.enableTCPKeepalive = true
        options.keepaliveIdleTime = 30
        
        let params = NWParameters.tcp
        params.defaultProtocolStack.applicationProtocols = [options]
        params.allowLocalEndpointReuse = true
        
        return params
    }
}

// MARK: - Errors

enum ProxyError: Error, LocalizedError {
    case notConnected
    case connectionClosed
    case emptyData
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to Telegram DC"
        case .connectionClosed:
            return "Connection closed"
        case .emptyData:
            return "Empty data received"
        }
    }
}
