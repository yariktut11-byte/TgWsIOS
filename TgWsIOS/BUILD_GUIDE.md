# Инструкция по сборке IPA

## Шаг 1: Создайте репозиторий на GitHub

1. Перейдите на https://github.com/new
2. Создайте новый приватный или публичный репозиторий
3. Скопируйте URL репозитория

## Шаг 2: Загрузите код

Откройте PowerShell в папке проекта и выполните:

```powershell
# Инициализация git
git init

# Добавление всех файлов
git add .

# Первый коммит
git commit -m "Initial commit - TgWs Proxy by Yarik"

# Переименование ветки в main
git branch -M main

# Добавление удалённого репозитория (замените URL на ваш)
git remote add origin https://github.com/ВАШ_НИК/TgWsProxy.git

# Загрузка на GitHub
git push -u origin main
```

## Шаг 3: Запустите автоматическую сборку

1. Откройте ваш репозиторий на GitHub
2. Перейдите во вкладку **Actions**
3. Нажмите на workflow **"Build iOS IPA"**
4. Нажмите кнопку **"Run workflow"**
5. Подождите 3-5 минут

## Шаг 4: Скачайте IPA файл

1. В списке jobs нажмите на завершённый run
2. Прокрутите вниз до раздела **Artifacts**
3. Нажмите на `TgWsApp-IPA`
4. Скачайте ZIP архив
5. Извлеките `TgWsApp.ipa`

## Шаг 5: Установите на iPhone

### Вариант A: Sideloadly (БЕСПЛАТНО)
1. Скачайте https://sideloadly.io/
2. Подключите iPhone к компьютеру
3. Перетащите TgWsApp.ipa в Sideloadly
4. Введите ваш Apple ID
5. Нажмите Install

### Вариант B: AltStore
1. Скачайте https://altstore.io/
2. Установите AltServer на компьютер
3. Откройте AltStore на iPhone
4. Добавьте IPA через AltStore

### Вариант C: Apple Configurator (только Mac)
1. Установите Apple Configurator из App Store
2. Подключите iPhone
3. Перетащите IPA в окно

## Готово!

Откройте приложение на iPhone и нажмите **"Start Proxy"**

## ⚠️ Важно

- После установки через Sideloadly/AltStore прокси нужно обновлять каждые 7 дней
- Для автоматического обновления используйте AltStore (Wi-Fi синхронизация)
- Нужен только Apple ID (можно бесплатный)
