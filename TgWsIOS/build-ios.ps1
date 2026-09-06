# Скрипт для сборки IPA файла
# Запустите этот скрипт для создания IPA файла

Write-Host "TgWs Proxy - Build Script" -ForegroundColor Blue
Write-Host "=========================" -ForegroundColor Blue
Write-Host ""

# Проверка существования проекта
$projectPath = ".\TgWsIOS.xcodeproj"
if (-not (Test-Path $projectPath)) {
    Write-Host "ERROR: Project not found!" -ForegroundColor Red
    exit 1
}

# Настройки сборки
$scheme = "TgWsApp"
$configuration = "Release"
$destination = "generic/platform=iOS"
$buildDir = ".\build"

Write-Host "Building project..." -ForegroundColor Yellow

# Очистка предыдущей сборки
if (Test-Path $buildDir) {
    Remove-Item -Recurse -Force $buildDir
}
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# Сборка проекта
$xcodebuild = & which xcodebuild 2>$null
if (-not $xcodebuild) {
    $xcodebuild = "xcodebuild"
}

& $xcodebuild build `
    -project $projectPath `
    -scheme $scheme `
    -configuration $configuration `
    -destination $destination `
    -derivedDataPath (Join-Path $buildDir "DerivedData") `
    2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host ""

# Поиск IPA файла
$ipaPath = Join-Path $buildDir "DerivedData" "Build" "Products" "$configuration-iphoneos" "*.ipa"
$ipaFiles = Get-ChildItem -Path $ipaPath -ErrorAction SilentlyContinue

if ($ipaFiles.Count -eq 0) {
    Write-Host "ERROR: IPA file not found!" -ForegroundColor Red
    exit 1
}

$ipaFile = $ipaFiles[0]
Write-Host "IPA file created:" -ForegroundColor Green
Write-Host $ipaFile.FullName -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Copy the IPA file to your iPhone" -ForegroundColor White
Write-Host "2. Install via Apple Configurator or iMazing" -ForegroundColor White
Write-Host "3. Open the app and tap 'Start Proxy'" -ForegroundColor White
Write-Host ""
