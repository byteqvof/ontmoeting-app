#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

CONFIG="${TOCH_CONFIG:-config/dev.local.json}"
if [ ! -f "$CONFIG" ]; then
  CONFIG="config/dev.example.json"
  echo "Geen config/dev.local.json gevonden; gebruik config/dev.example.json."
  echo "Maak config/dev.local.json voor Firebase/PostHog/Sentry of project-specifieke waarden."
fi

if [ "${1:-}" = "" ]; then
  fvm flutter run --dart-define-from-file="$CONFIG"
else
  fvm flutter run -d "$1" --dart-define-from-file="$CONFIG"
fi
