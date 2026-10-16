$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$flutterPath = if ($flutterCommand) { $flutterCommand.Source } else { $null }
if (-not $flutterPath -and (Test-Path 'C:\src\flutter\bin\flutter.bat')) {
    $flutterPath = 'C:\src\flutter\bin\flutter.bat'
}
if (-not $flutterPath) {
    throw 'Flutter tidak ditemukan. Atur PATH Flutter, lalu buka terminal baru.'
}

$settingsFile = Join-Path $PSScriptRoot 'settings\private.json'
if (-not (Test-Path $settingsFile)) { throw 'Salin settings/private.example.json menjadi settings/private.json dan isi API key Gemini.' }
$config = Get-Content -Raw $settingsFile | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($config.GEMINI_API_KEY)) { throw 'Isi GEMINI_API_KEY di settings/private.json terlebih dahulu. Jangan kirim kunci melalui chat.' }
& $flutterPath pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get gagal.' }

& $flutterPath build apk --release --dart-define-from-file=settings/private.json
if ($LASTEXITCODE -ne 0) { throw 'Build APK gagal. Baca error Flutter di atas.' }

Write-Host 'APK berhasil dibuat: build\app\outputs\flutter-apk\app-release.apk' -ForegroundColor Green
