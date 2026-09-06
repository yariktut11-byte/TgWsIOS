# Скрипт быстрой сборки TgWs Proxy
# Created by Yarik

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TgWs Proxy - Быстрая сборка IPA" -ForegroundColor Cyan
Write-Host "  Created by Yarik" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Проверка Git
Write-Host "[1/4] Проверка Git..." -ForegroundColor Yellow
$gitVersion = git --version 2>$null
if (-not $gitVersion) {
    Write-Host "ОШИБКА: Git не установлен!" -ForegroundColor Red
    Write-Host "Установите Git с https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}
Write-Host "  Git установлен: $gitVersion" -ForegroundColor Green

# Инициализация репозитория
Write-Host ""
Write-Host "[2/4] Инициализация Git репозитория..." -ForegroundColor Yellow
git init -q
git branch -M main 2>$null
Write-Host "  Репозиторий инициализирован" -ForegroundColor Green

# Добавление файлов
Write-Host ""
Write-Host "[3/4] Добавление файлов..." -ForegroundColor Yellow
git add . 2>$null
git commit -q -m "Initial commit - TgWs Proxy by Yarik" 2>$null
Write-Host "  Файлы добавлены и закоммичены" -ForegroundColor Green

# Получение URL репозитория
Write-Host ""
Write-Host "[4/4] Настройка удалённого репозитория" -ForegroundColor Yellow
Write-Host ""
$repoUrl = Read-Host "Введите URL репозитория GitHub (https://github.com/username/repo)"

if (-not $repoUrl) {
    Write-Host ""
    Write-Host "АВТОМАТИЧЕСКОЕ СОЗДАНИЕ РЕПОЗИТОРИЯ" -ForegroundColor Yellow
    Write-Host ""
    
    $username = Read-Host "Введите ваш GitHub username"
    $repoName = "TgWsProxy"
    
    Write-Host ""
    Write-Host "Инструкция:" -ForegroundColor Cyan
    Write-Host "1. Откройте https://github.com/new" -ForegroundColor White
    Write-Host "2. Создайте репозиторий: $username/$repoName" -ForegroundColor White
    Write-Host "3. Нажмите OK после создания" -ForegroundColor White
    Write-Host ""
    pause
    
    $repoUrl = "https://github.com/$username/$repoName.git"
}

# Добавление удалённого репозитория
git remote remove origin 2>$null
git remote add origin $repoUrl

# Показ команды для push
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ГОТОВО!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Выполните команду:" -ForegroundColor Yellow
Write-Host "  git push -u origin main" -ForegroundColor Cyan
Write-Host ""
Write-Host "Затем:" -ForegroundColor Yellow
Write-Host "1. Откройте ваш репозиторий на GitHub" -ForegroundColor White
Write-Host "2. Перейдите во вкладку Actions" -ForegroundColor White
Write-Host "3. Запустите workflow 'Build iOS IPA'" -ForegroundColor White
Write-Host "4. Скачайте IPA из Artifacts" -ForegroundColor White
Write-Host ""
Write-Host "Подробная инструкция: BUILD_GUIDE.md" -ForegroundColor Cyan
Write-Host ""
pause
