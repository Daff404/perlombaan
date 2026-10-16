param([string]$ProjectPath = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path (Join-Path $ProjectPath 'pubspec.yaml'))) { throw "Project tidak ditemukan: $ProjectPath" }
$relativePaths = @('android\gradle\wrapper\gradle-wrapper.properties', 'android\settings.gradle.kts', 'android\gradle.properties', 'android\app\build.gradle.kts')
$changes = @{}
foreach ($relative in $relativePaths) {
    $path = Join-Path $ProjectPath $relative
    if (-not (Test-Path $path)) { throw "File tidak ditemukan: $path. Patch ini untuk Kotlin DSL (.kts)." }
    $changes[$relative] = [IO.File]::ReadAllText($path)
}
$wrapper = $relativePaths[0]
if ($changes[$wrapper] -notmatch 'gradle-[0-9.]+-(bin|all)\.zip') { throw 'distributionUrl Gradle tidak dikenali.' }
$changes[$wrapper] = $changes[$wrapper] -replace 'gradle-[0-9.]+-(bin|all)\.zip','gradle-9.3.1-bin.zip'
$settings = $relativePaths[1]
foreach ($plugin in @(@('com.android.application','9.1.0'), @('org.jetbrains.kotlin.android','2.4.0'))) {
    $pattern = '(id\("' + [regex]::Escape($plugin[0]) + '"\)\s+version\s+")[^"]+("\s+apply\s+false)'
    if ($changes[$settings] -notmatch $pattern) { throw "Deklarasi plugin tidak dikenali: $($plugin[0]). Tidak ada file diubah." }
    $replacement = '${1}' + $plugin[1] + '${2}'
    $changes[$settings] = [regex]::Replace($changes[$settings], $pattern, $replacement)
}
$properties = $relativePaths[2]
foreach ($flag in @('android.builtInKotlin','android.newDsl')) {
    $pattern = '(?m)^' + [regex]::Escape($flag) + '\s*=.*$'
    if ($changes[$properties] -match $pattern) { $changes[$properties] = [regex]::Replace($changes[$properties], $pattern, "$flag=false") }
    else { $changes[$properties] += "`r`n$flag=false`r`n" }
}
$app = $relativePaths[3]
# Migrate only the standard Java 11 kotlinOptions block. Preserve namespace,
# applicationId, dependencies, signing, NDK, SDK versions, and all app code.
$oldOptions = '(?ms)^\s*kotlinOptions\s*\{\s*jvmTarget\s*=\s*JavaVersion\.VERSION_11\.toString\(\)\s*\}'
if ($changes[$app] -match $oldOptions) {
    $changes[$app] = [regex]::Replace($changes[$app], $oldOptions, '')
    if ($changes[$app] -match '(?m)^kotlin\s*\{') { throw 'Ada konfigurasi kotlin khusus. Gabungkan compilerOptions secara manual; tidak ada file diubah.' }
    $changes[$app] += "`r`nkotlin {`r`n    compilerOptions {`r`n        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)`r`n    }`r`n}`r`n"
} elseif ($changes[$app] -match 'kotlinOptions') {
    throw 'kotlinOptions berbeda dari base. Gunakan compilerOptions dengan target yang sama; tidak ada file diubah.'
}
$backup = Join-Path $ProjectPath ('java25-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($relative in $relativePaths) {
    $source = Join-Path $ProjectPath $relative
    $saved = Join-Path $backup $relative
    [IO.Directory]::CreateDirectory((Split-Path $saved)) | Out-Null
    Copy-Item -LiteralPath $source -Destination $saved
    [IO.File]::WriteAllText($source, $changes[$relative], $utf8)
}
Write-Host "Patch selesai. Backup: $backup" -ForegroundColor Green
Write-Host 'Berikutnya jalankan Build-Java25.ps1 dengan ProjectPath yang sama.'
