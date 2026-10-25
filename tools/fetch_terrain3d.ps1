# Lädt die gepinnte Terrain3D-Version nach addons\terrain_3d (ADR 0001).
# Version und Prüfsumme nur zusammen ändern; Linux/macOS-Gegenstück: tools/fetch_terrain3d.sh
$ErrorActionPreference = "Stop"

$Version = "v1.0.2-stable"
$Zip = "Terrain3D_v1.0.2-stable.zip"
$Sha256 = "a071850250ec5e596aa54da61c01d75768774eb379ee997584d426a45f4884a2"
$Url = "https://github.com/TokisanGames/Terrain3D/releases/download/$Version/$Zip"

$Root = git rev-parse --show-toplevel
$Tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp | Out-Null
try {
    Write-Host "Lade Terrain3D $Version ..."
    $ZipPath = Join-Path $Tmp $Zip
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
    $Hash = (Get-FileHash -Algorithm SHA256 $ZipPath).Hash.ToLower()
    if ($Hash -ne $Sha256) { throw "Prüfsumme stimmt nicht: $Hash" }

    Expand-Archive -Path $ZipPath -DestinationPath $Tmp
    $Target = Join-Path $Root "addons\terrain_3d"
    if (Test-Path $Target) { Remove-Item -Recurse -Force $Target }
    New-Item -ItemType Directory -Path (Join-Path $Root "addons") -Force | Out-Null
    Copy-Item -Recurse (Join-Path $Tmp "addons\terrain_3d") $Target
    Write-Host "Terrain3D installiert: $Target"
}
finally {
    Remove-Item -Recurse -Force $Tmp
}
