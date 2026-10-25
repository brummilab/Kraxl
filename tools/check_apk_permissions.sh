#!/bin/sh
# Gate (ADR 0007): Das APK darf keine einzige <uses-permission> enthalten.
# Aufruf: tools/check_apk_permissions.sh build/android/Kraxl.apk
# Braucht aapt2 aus den Android build-tools (im PATH oder über $ANDROID_HOME).
set -e

apk="${1:?Pfad zum APK fehlt}"
aapt2=$(command -v aapt2 || ls "$ANDROID_HOME"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1)
[ -x "$aapt2" ] || { echo "aapt2 nicht gefunden (ANDROID_HOME setzen)." >&2; exit 2; }

perms=$("$aapt2" dump permissions "$apk" | grep -i 'uses-permission' || true)
if [ -n "$perms" ]; then
	echo "FEHLER: $apk verlangt Berechtigungen:" >&2
	echo "$perms" >&2
	exit 1
fi
echo "OK: $apk verlangt keine Berechtigungen."
