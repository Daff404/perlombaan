$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter tidak ditemukan. Tambahkan folder flutter\bin ke PATH, lalu buka terminal baru.'
}

if (-not (Test-Path 'android\app\build.gradle.kts') -and -not (Test-Path 'android\app\build.gradle')) {
    flutter create --platforms=android --org=id.shion.app .
    if ($LASTEXITCODE -ne 0) { throw 'Pembuatan proyek Android gagal.' }
}

flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Pengambilan dependency gagal.' }

flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Analisis Flutter gagal. Perbaiki error sebelum build.' }

flutter test test/local_store_test.dart
if ($LASTEXITCODE -ne 0) { throw 'Tes Flutter gagal. Perbaiki error sebelum build.' }

flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'Build APK gagal.' }

Write-Host 'APK: build\app\outputs\flutter-apk\app-release.apk' -ForegroundColor Green
