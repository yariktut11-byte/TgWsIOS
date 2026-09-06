import SwiftUI

/// Главное окно приложения с интерфейсом управления прокси
struct ContentView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Вкладка Proxy
            ProxyTabView()
                .tabItem {
                    Label("Proxy", systemImage: "network")
                }
                .tag(0)
            
            // Вкладка Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(1)
            
            // Вкладка About
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(2)
        }
        .tint(.blue)
    }
}

// MARK: - Proxy Tab

struct ProxyTabView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatusCard(status: proxyManager.serverStatus)
                    QuickActionsView()
                        .padding(.horizontal)
                    
                    if proxyManager.serverStatus == .running {
                        ConnectionInfoView(connectionCount: proxyManager.connectionCount)
                            .padding(.horizontal)
                    }
                    
                    InstructionView()
                        .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("TgWs Proxy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if proxyManager.serverStatus == .running {
                        Button("Stop") {
                            Task {
                                await proxyManager.stop()
                            }
                        }
                        .foregroundStyle(.red)
                        .font(.headline)
                    }
                }
            }
            .alert("Error", isPresented: $proxyManager.showError) {
                Button("OK") {}
            } message: {
                Text(proxyManager.errorMessage)
            }
        }
        .onAppear {
            proxyManager.loadConfig()
            Task {
                await proxyManager.start()
            }
        }
        .onDisappear {
            Task {
                await proxyManager.stop()
            }
        }
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let status: ProxyManager.ProxyStatus
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .overlay {
                    Circle()
                        .fill(statusColor.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .opacity(status == .running ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0), value: status == .running)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var statusColor: Color {
        switch status {
        case .running: return .green
        case .starting: return .yellow
        case .stopped: return .gray
        case .error: return .red
        }
    }
    
    private var statusTitle: String {
        switch status {
        case .running: return "Proxy Running"
        case .starting: return "Starting..."
        case .stopped: return "Proxy Stopped"
        case .error: return "Error"
        }
    }
    
    private var statusSubtitle: String {
        switch status {
        case .running:
            return "Port \(ProxyManager.shared.config.localPort) • DC: \(ProxyManager.shared.config.dcAddress)"
        case .starting: return "Initializing proxy server"
        case .stopped: return "Tap Start to begin"
        case .error: return ProxyManager.shared.errorMessage
        }
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Главная кнопка Start/Stop
            Button {
                Task {
                    if proxyManager.serverStatus == .running {
                        await proxyManager.stop()
                    } else {
                        await proxyManager.start()
                    }
                }
            } label: {
                Label(proxyManager.serverStatus == .running ? "Stop Proxy" : "Start Proxy",
                      systemImage: proxyManager.serverStatus == .running ? "stop.circle.fill" : "play.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(proxyManager.serverStatus == .running ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .font(.headline)
                    .cornerRadius(14)
            }
            .disabled(proxyManager.serverStatus == .starting)
            
            // Кнопка открытия Telegram
            Button {
                openTelegram()
            } label: {
                Label("Open Telegram", systemImage: "paperplane.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green.opacity(0.9))
                    .foregroundStyle(.white)
                    .font(.headline)
                    .cornerRadius(14)
            }
            
            // Копировать настройки прокси
            Button {
                copyProxyLink()
            } label: {
                Label("Copy Proxy Link", systemImage: "link.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange.opacity(0.9))
                    .foregroundStyle(.white)
                    .font(.headline)
                    .cornerRadius(14)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func openTelegram() {
        if let url = URL(string: "tg://resolve?domain=SetProxy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func copyProxyLink() {
        let config = proxyManager.config
        let link = "tg://proxy?server=\(config.dcAddress)&port=\(config.dcPort)&secret=\(config.secret)"
        UIPasteboard.general.string = link
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
            
            Form {
                // Порт локального прослушивания
                Section("Local Server") {
                    HStack {
                        Text("Port")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("443", value: $proxyManager.config.localPort, format: .number)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.primary)
                            .keyboardType(.numberPad)
                            .disabled(proxyManager.serverStatus == .running)
                    }
                }
                
                // Настройки Telegram DC
                Section("Telegram DC") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DC Address")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        TextField("149.154.167.40", text: $proxyManager.config.dcAddress)
                            .disabled(proxyManager.serverStatus == .running)
                    }
                    
                    HStack {
                        Text("DC Port")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("443", value: $proxyManager.config.dcPort, format: .number)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.primary)
                            .keyboardType(.numberPad)
                            .disabled(proxyManager.serverStatus == .running)
                    }
                }
                
                // Секрет прокси
                Section("Security") {
                    SecureField("Enter proxy secret", text: $proxyManager.config.secret)
                        .disabled(proxyManager.serverStatus == .running)
                }
                
                // Пресеты DC
                Section("Quick DC Presets") {
                    Button {
                        proxyManager.config.dcAddress = "149.154.167.40"
                        proxyManager.config.dcPort = 443
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Main DC (149.154.167.40)")
                            Spacer()
                        }
                    }
                    
                    Button {
                        proxyManager.config.dcAddress = "149.154.167.10"
                        proxyManager.config.dcPort = 8888
                    } label: {
                        HStack {
                            Image(systemName: "globe.americas")
                            Text("DC 2 (149.154.167.10)")
                            Spacer()
                        }
                    }
                    
                    Button {
                        proxyManager.config.dcAddress = "149.154.167.40"
                        proxyManager.config.dcPort = 443
                        proxyManager.config.secret = UUID().uuidString.prefix(16).description
                    } label: {
                        HStack {
                            Image(systemName: "key.fill")
                            Text("Generate New Secret")
                            Spacer()
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Connection Info

struct ConnectionInfoView: View {
    let connectionCount: Int
    
    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("\(connectionCount)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                Text("Connections")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Instruction View

struct InstructionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Connect")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                instructionRow(number: 1, text: "Open Telegram Settings")
                instructionRow(number: 2, text: "Go to Data and Storage → Proxy")
                instructionRow(number: 3, text: "Tap Add Proxy")
                instructionRow(number: 4, text: "Server: 127.0.0.1")
                instructionRow(number: 5, text: "Port: \(ProxyManager.shared.config.localPort)")
                instructionRow(number: 6, text: "Secret: \(ProxyManager.shared.config.secret)")
                instructionRow(number: 7, text: "Enable Proxy and enjoy!")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .foregroundStyle(.blue)
                .fontWeight(.semibold)
            Text(text)
                .flexibleWidth()
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Иконка и название
                    VStack(spacing: 12) {
                        Image(systemName: "network")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                            .padding()
                            .background(.ultraThinMaterial, in: Circle())
                        
                        Text("TgWs Proxy")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // Информация о создателе
                    VStack(spacing: 12) {
                        Text("Created by")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Yarik")
                                    .font(.headline)
                                Text("Developer")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Описание
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)
                        
                        Text("TgWs Proxy is a local MTProto proxy server for iOS. It allows you to connect to Telegram through a custom proxy, similar to tgws proxy for exe and apk, but built natively for iOS.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    
                    // Функции
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(icon: "shield.lefthalf.filled", text: "MTProto Proxy Support")
                        FeatureRow(icon: "iphone.gen3", text: "Optimized for iPhone 17 Pro")
                        FeatureRow(icon: "slider.horizontal.3", text: "Custom DC Configuration")
                        FeatureRow(icon: "link", text: "Quick Telegram Integration")
                        FeatureRow(icon: "lock.shield", text: "Secure Connection")
                    }
                    .padding(.horizontal)
                    
                    // Поддержка
                    VStack(spacing: 12) {
                        Text("Support")
                            .font(.headline)
                        
                        Text("If you have any questions or issues, please contact Yarik.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("About")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(ProxyManager.shared)
}
