import Foundation

/// Модель конфигурации прокси
struct ProxyConfig {
    /// Порт локального прослушивания
    var localPort: Int
    /// IP-адрес Telegram DC
    var dcAddress: String
    /// Порт Telegram DC
    var dcPort: Int
    /// Секрет прокси (опционально, для проверки клиентами)
    var secret: String
    /// Максимальное количество одновременных соединений
    var maxConnections: Int
    
    init(
        localPort: Int = 443,
        dcAddress: String = "149.154.167.40",
        dcPort: Int = 443,
        secret: String = "YOUR_SECRET_HERE",
        maxConnections: Int = 100
    ) {
        self.localPort = localPort
        self.dcAddress = dcAddress
        self.dcPort = dcPort
        self.secret = secret
        self.maxConnections = maxConnections
    }
}

extension ProxyConfig: Codable {}
