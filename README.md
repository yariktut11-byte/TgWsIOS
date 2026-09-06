# TgWs Proxy - MTProto Proxy for iOS

**Created by Yarik**

Локальный MTProto прокси-сервер для iOS. Позволяет подключаться к Telegram через кастомный прокси на вашем iPhone.

## 📱 Совместимость

- iPhone 17 Pro и другие модели iPhone/iPad
- iOS 16.0+
- SwiftUI

## ✨ Возможности

- 🔄 Локальный MTProto прокси-сервер
- 🎨 Красивый интерфейс SwiftUI
- ⚙️ Настраиваемый порт и адрес Telegram DC
- 🚀 Быстрое подключение через Telegram
- 📊 Мониторинг активных соединений
- 🔒 Безопасное соединение

## 🚀 Установка (2 способа)

### Способ 1: Автоматическая сборка через GitHub (РЕКОМЕНДУЕТСЯ)

Этот способ НЕ требует Mac! GitHub автоматически соберёт IPA файл.

1. **Создайте репозиторий на GitHub:**
   ```bash
   git init
   git add .
   git commit -m "Initial commit - TgWs Proxy by Yarik"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/TgWsProxy.git
   git push -u origin main
   ```

2. **Включите GitHub Actions:**
   - Перейдите в вкладку **Actions** на GitHub
   - Нажмите "I understand my workflows, go ahead and enable them"

3. **Запустите сборку:**
   - Нажмите на workflow "Build iOS IPA" → "Run workflow"
   - Подождите 3-5 минут

4. **Скачайте IPA:**
   - В конце jobs нажмите на артефакт `TgWsApp-IPA`
   - Скачайте файл `TgWsApp.ipa`

5. **Установите на iPhone:**
   - Загрузите IPA через [AltStore](https://altstore.io)
   - Или через [Sideloadly](http://sideloadly.io)
   - Или через Apple Configurator

### Способ 2: Сборка на Mac через Xcode

1. Откройте проект в Xcode:
   ```
   TgWsIOS.xcodeproj
   ```

2. Выберите ваше устройство iPhone в списке устройств

3. Нажмите `Cmd + B` для сборки проекта

4. Нажмите `Cmd + R` для запуска на устройстве

5. Для создания IPA:
   - Archive (`Cmd + Shift + K`)
   - Export as IPA

## ⚙️ Настройка прокси в Telegram

После запуска прокси в приложении:

1. Откройте Telegram
2. Перейдите в **Настройки** → **Конфиденциальность** → **Прокси**
3. Нажмите **Добавить прокси**
4. Настройки:
   - **Сервер:** `127.0.0.1`
   - **Порт:** `443` (или ваш настроенный порт)
   - **Секрет:** (ваш секрет из приложения)
5. Включите прокси

Или используйте кнопку **"Copy Proxy Link"** в приложении — она скопирует ссылку для быстрого подключения.

## 📂 Структура проекта

```
TgWsIOS/
├── .github/workflows/
│   └── build-ios.yml        # GitHub Actions для сборки IPA
├── Sources/
│   ├── TgWsApp/
│   │   ├── TgWsApp.swift      # Точка входа
│   │   └── ContentView.swift  # UI интерфейс
│   └── TgWsProxy/
│       ├── ProxyConfig.swift       # Конфигурация
│       ├── ProxyServer.swift       # Сервер прослушивания
│       ├── ProxyClient.swift       # Клиент Telegram DC
│       ├── ProxyConnection.swift   # Форвардинг трафика
│       └── ProxyManager.swift      # Менеджер прокси
├── TgWsIOS/
│   ├── Info.plist              # Настройки приложения
│   └── Assets.xcassets/        # Ресурсы
├── TgWsIOS.xcodeproj/          # Проект Xcode
├── README.md                   # Эта инструкция
└── Package.swift               # Swift Package Manager
```

## 🛠 Технологии

- **SwiftUI** — пользовательский интерфейс
- **Network Framework** — работа с TCP соединениями
- **Combine** — реактивное программирование
- **Async/Await** — асинхронная обработка

## 📝 Примечания

- Приложение требует разрешения на доступ к локальной сети
- Для работы прокси необходимо включить его в настройках Telegram
- Поддерживает до 100 одновременных соединений
- Для sideloading нужен Apple ID

## 👨‍💻 Автор

**Yarik** — разработчик приложения TgWs Proxy

## 📄 Лицензия

MIT License
