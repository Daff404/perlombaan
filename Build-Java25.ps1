param([string]$ProjectPath = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $ProjectPath
function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program gagal (exit $LASTEXITCODE). Periksa output di atas." }
}
# Reuse the installed Java. Never download or switch to a different JDK.
$java = (Get-Command java -ErrorAction Stop).Source
$process = New-Object System.Diagnostics.Process
$process.StartInfo.FileName = $java
$process.StartInfo.Arguments = '-XshowSettings:properties -version'
$process.StartInfo.UseShellExecute = $false
$process.StartInfo.RedirectStandardOutput = $true
$process.StartInfo.RedirectStandardError = $true
$process.Start() | Out-Null
$javaInfo = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()
$process.WaitForExit()
if ($process.ExitCode -ne 0) { throw 'Gagal membaca versi Java aktif.' }
$process.Dispose()
if ($javaInfo -notmatch 'java\.version\s*=\s*25\.0\.3(?:\s|$)') { throw 'Java aktif bukan 25.0.3. Arahkan PATH ke instalasi Java 25.0.3 Anda yang sudah ada.' }
$javaHomeMatch = [regex]::Match($javaInfo, '(?m)^\s*java\.home\s*=\s*(.+)$')
if (-not $javaHomeMatch.Success) { throw 'java.home tidak terbaca.' }
$jdkPath = $javaHomeMatch.Groups[1].Value.Trim()
$env:JAVA_HOME = $jdkPath
$env:Path = (Join-Path $jdkPath 'bin') + ';' + $env:Path
$sdkPath = Join-Path $env:LOCALAPPDATA 'Android\sdk'
if (-not (Test-Path $sdkPath)) { throw "Android SDK tidak ditemukan: $sdkPath" }
Invoke-Checked 'flutter' @('config', '--jdk-dir', $jdkPath)
Invoke-Checked 'flutter' @('config', '--android-sdk', $sdkPath)
$sdkManager = Join-Path $sdkPath 'cmdline-tools\latest\bin\sdkmanager.bat'
if (-not (Test-Path $sdkManager)) {
    throw 'cmdline-tools/latest belum tersedia. Android Studio > SDK Manager > SDK Tools > Android SDK Command-line Tools (latest). Pasang lalu jalankan ulang.'
}
# Existing Gradle JVM overrides can take priority over JAVA_HOME.
foreach ($props in @((Join-Path $ProjectPath 'android\gradle.properties'), (Join-Path $env:USERPROFILE '.gradle\gradle.properties'))) {
    if ((Test-Path $props) -and (Select-String -Path $props -Pattern '^\s*org\.gradle\.java\.home\s*=' -Quiet)) {
        Write-Warning "Periksa org.gradle.java.home di $props; harus menunjuk Java 25.0.3 yang sama."
    }
}
if (Test-Path 'android\gradle\gradle-daemon-jvm.properties') { Write-Warning 'Periksa gradle-daemon-jvm.properties: kriteria JVM daemon harus cocok dengan Java 25.' }
Invoke-Checked $sdkManager @("--sdk_root=$sdkPath", '--list_installed')
Invoke-Checked 'flutter' @('doctor', '--android-licenses')
Invoke-Checked 'flutter' @('doctor', '-v')
Invoke-Checked '.\android\gradlew.bat' @('-p', 'android', '--stop')
Invoke-Checked '.\android\gradlew.bat' @('-p', 'android', '--version')
Invoke-Checked 'flutter' @('clean')
Invoke-Checked 'flutter' @('pub', 'get')
$buildArgs = @('build', 'apk', '--release')
if (Test-Path 'settings\private.json') {
    $settings = Get-Content -Raw 'settings\private.json' | ConvertFrom-Json
    if (-not [string]::IsNullOrWhiteSpace($settings.GEMINI_API_KEY)) { $buildArgs += '--dart-define-from-file=settings/private.json' }
}
Invoke-Checked 'flutter' $buildArgs
$apk = Join-Path $ProjectPath 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path $apk)) { throw 'Flutter selesai tetapi APK tidak ditemukan di lokasi target.' }
Write-Host "APK tersedia: $apk" -ForegroundColor Green
