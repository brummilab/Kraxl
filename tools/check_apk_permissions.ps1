# Gate (ADR 0007): Das APK darf keine einzige <uses-permission> enthalten.
# Aufruf: tools\check_apk_permissions.ps1 build\android\Kraxl.apk
param([Parameter(Mandatory = $true)][string]$Apk)
$ErrorActionPreference = "Stop"

$Aapt2 = Get-Command aapt2 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $Aapt2) {
    $Aapt2 = Get-ChildItem "$env:ANDROID_HOME\build-tools\*\aapt2.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName | Select-Object -Last 1 -ExpandProperty FullName
}
if (-not $Aapt2) { Write-Error "aapt2 nicht gefunden (ANDROID_HOME setzen)."; exit 2 }

$Perms = & $Aapt2 dump permissions $Apk | Select-String -Pattern "uses-permission"
if ($Perms) {
    Write-Host "FEHLER: $Apk verlangt Berechtigungen:" -ForegroundColor Red
    $Perms | ForEach-Object { Write-Host $_ }
    exit 1
}
Write-Host "OK: $Apk verlangt keine Berechtigungen." -ForegroundColor Green
