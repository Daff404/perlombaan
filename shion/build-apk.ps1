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

& $flutterPath pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get gagal.' }

& $flutterPath build apk --release
if ($LASTEXITCODE -ne 0) { throw 'Build APK gagal. Baca error Flutter di atas.' }

Write-Host 'APK berhasil dibuat: build\app\outputs\flutter-apk\app-release.apk' -ForegroundColor Green
