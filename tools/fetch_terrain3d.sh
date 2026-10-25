#!/bin/sh
# Lädt die gepinnte Terrain3D-Version nach addons/terrain_3d (ADR 0001).
# Version und Prüfsumme nur zusammen ändern; Windows-Gegenstück: tools/fetch_terrain3d.ps1
set -e

VERSION="v1.0.2-stable"
ZIP="Terrain3D_v1.0.2-stable.zip"
SHA256="a071850250ec5e596aa54da61c01d75768774eb379ee997584d426a45f4884a2"
URL="https://github.com/TokisanGames/Terrain3D/releases/download/$VERSION/$ZIP"

cd "$(git rev-parse --show-toplevel)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "Lade Terrain3D $VERSION …"
curl -fsSL -o "$tmp/$ZIP" "$URL"
echo "$SHA256  $tmp/$ZIP" | sha256sum -c -

rm -rf addons/terrain_3d
unzip -q "$tmp/$ZIP" 'addons/terrain_3d/*' -d .
echo "Terrain3D $(grep '^version=' addons/terrain_3d/plugin.cfg) installiert."
