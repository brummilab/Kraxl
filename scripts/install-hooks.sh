#!/bin/sh
# Aktiviert die Repo-Hooks aus scripts/hooks/.
set -e
cd "$(git rev-parse --show-toplevel)"
chmod +x scripts/hooks/*
git config core.hooksPath scripts/hooks
echo "Hooks aktiv: core.hooksPath = scripts/hooks"
