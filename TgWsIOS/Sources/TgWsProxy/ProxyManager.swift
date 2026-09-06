import Foundation
import Network
import Combine

/// Менеджер прокси, управляющий жизненным циклом сервера
class ProxyManager: ObservableObject {
    static let shared = ProxyManager()
    
    /// Состояние прокси
    enum ProxyStatus: String {
        case stopped = "Stopped"
        case starting = "Starting..."
        case running = "Running"
        case error = "Error"
    }
    
    @Published var serverStatus: ProxyStatus = .stopped
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var connectionCount: Int = 0
    
    var config = ProxyConfig() {
        didSet {
            saveConfig()
        }
    }
    
    private var proxyServer: ProxyServer?
    private let configFileName = "tgws_proxy_config.json"
    
    private init() {
        loadConfig()
    }
    
    // MARK: - Start/Stop
    
    /// Запуск прокси-сервера
    func start() async {
        guard serverStatus != .running, serverStatus != .starting else { return }
        
        serverStatus = .starting
        errorMessage = ""
        
        do {
            proxyServer = ProxyServer(config: config)
            
            proxyServer?.statusHandler = { [weak self] status in
                self?.handleServerStatus(status)
            }
            
            await proxyServer?.start()
            
        } catch {
            serverStatus = .error
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    /// Остановка прокси-сервера
    func stop() async {
        guard serverStatus == .running else { return }
        
        proxyServer?.stop()
        serverStatus = .stopped
        connectionCount = 0
    }
    
    // MARK: - Status Handler
    
    private func handleServerStatus(_ status: ProxyServer.ProxyServerStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch status {
            case .starting:
                self.serverStatus = .starting
            case .started:
                self.serverStatus = .running
            case .stopped:
                self.serverStatus = .stopped
                self.connectionCount = 0
            case .error(let message):
                self.serverStatus = .error
                self.errorMessage = message
                self.showError = true
            case .connectionOpened:
                self.connectionCount += 1
            case .connectionClosed:
                self.connectionCount = max(0, self.connectionCount - 1)
            }
        }
    }
    
    // MARK: - Config Persistence
    
    private func getConfigDirectory() -> URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    func loadConfig() {
        guard let url = getConfigDirectory()?.appendingPathComponent(configFileName) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(ProxyConfig.self, from: data)
            config = decoded
        } catch {
            // Используем конфиг по умолчанию
            print("Failed to load config: \(error)")
        }
    }
    
    func saveConfig() {
        guard let url = getConfigDirectory()?.appendingPathComponent(configFileName) else {
            return
        }
        
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: url)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
