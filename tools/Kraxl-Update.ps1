# Kraxl-Update: holt die neueste Kraxl-Version von GitHub (Releases von brummilab/Kraxl)
# und ersetzt die Dateien in diesem Ordner. Das Spiel selbst geht nie ins Internet (Kinder-Regel 3);
# nur dieses Skript, und nur wenn ein Erwachsener es per Doppelklick auf Kraxl-Update.cmd startet.
# Gespeicherte Crawler liegen in %APPDATA%\Godot\app_userdata\Kraxl und bleiben erhalten.
# ADR 0012. Test ohne Rückfragen: KRAXL_UPDATE_NOPAUSE=1, eigene Quelle: KRAXL_UPDATE_BASE=<URL>.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # sonst ist Invoke-WebRequest in PowerShell 5.1 sehr langsam
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Repo = 'brummilab/Kraxl'
$Base = if ($env:KRAXL_UPDATE_BASE) { $env:KRAXL_UPDATE_BASE } else { "https://github.com/$Repo/releases/latest/download" }
$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Temp = Join-Path ([IO.Path]::GetTempPath()) ("kraxl-update-" + [Guid]::NewGuid().ToString('N'))
$Interactive = -not $env:KRAXL_UPDATE_NOPAUSE

function Finish([string]$Message, [int]$Code = 0) {
    Write-Host ''
    Write-Host $Message
    if (Test-Path $Temp) { Remove-Item -Recurse -Force $Temp -ErrorAction SilentlyContinue }
    if ($Interactive) { Read-Host 'Zum Schliessen Enter druecken' | Out-Null }
    exit $Code
}

function Download([string]$Name) {
    $target = Join-Path $Temp $Name
    Invoke-WebRequest -UseBasicParsing -Uri "$Base/$Name" -OutFile $target
    return $target
}

Write-Host 'Kraxl-Update'
Write-Host '============'
New-Item -ItemType Directory -Force -Path $Temp | Out-Null

try {
    $versionFile = Join-Path $Dir 'version.txt'
    $local = if (Test-Path $versionFile) { (Get-Content -Raw $versionFile).Trim() } else { '(unbekannt)' }
    $remote = (Get-Content -Raw (Download 'version.txt')).Trim()
} catch {
    Finish "Keine Verbindung zu GitHub ($($_.Exception.Message)). Bitte Internet pruefen und spaeter nochmal versuchen." 1
}

Write-Host "Installiert: $local"
Write-Host "Neueste:     $remote"
if ($local -eq $remote) {
    Finish 'Kraxl ist schon aktuell.'
}

while (Get-Process -Name 'Kraxl' -ErrorAction SilentlyContinue) {
    if (-not $Interactive) { Finish 'Kraxl laeuft noch. Bitte zuerst beenden.' 1 }
    Read-Host 'Kraxl laeuft noch. Bitte das Spiel beenden und dann Enter druecken' | Out-Null
}

try {
    Write-Host 'Lade die neue Version (ca. 40 MB) ...'
    $zip = Download 'Kraxl-windows.zip'
    $expected = ((Get-Content -Raw (Download 'Kraxl-windows.zip.sha256')).Trim() -split '\s+')[0]
    $actual = (Get-FileHash -Algorithm SHA256 $zip).Hash
    if ($actual -ne $expected) {
        Finish "Download beschaedigt (Pruefsumme passt nicht). Nichts wurde veraendert." 1
    }
    $unpacked = Join-Path $Temp 'neu'
    Expand-Archive -Path $zip -DestinationPath $unpacked -Force
    if (-not (Test-Path (Join-Path $unpacked 'Kraxl.exe'))) {
        Finish 'Im Download fehlt Kraxl.exe. Nichts wurde veraendert.' 1
    }
    # Die laufende .cmd-Datei nicht ueberschreiben (cmd liest sie zeilenweise weiter).
    Get-ChildItem -Path $unpacked -Recurse -File | Where-Object { $_.Name -ne 'Kraxl-Update.cmd' } | ForEach-Object {
        $relative = $_.FullName.Substring($unpacked.Length).TrimStart('\', '/')
        $dest = Join-Path $Dir $relative
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
        Copy-Item -Force -Path $_.FullName -Destination $dest
    }
} catch {
    Finish "Update fehlgeschlagen: $($_.Exception.Message)" 1
}

Write-Host "Fertig: Kraxl ist jetzt auf $remote."
if ($Interactive) {
    $answer = Read-Host 'Kraxl jetzt starten? (j/n)'
    if ($answer -match '^[jJyY]') { Start-Process (Join-Path $Dir 'Kraxl.exe') -WorkingDirectory $Dir }
}
Finish 'Viel Spass!'
