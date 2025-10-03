#!/usr/bin/env bash
set -euo pipefail

# Background Agent Flutter/Dart environment bootstrap
# - Ensures Flutter SDK exists
# - Exposes Flutter & Dart on PATH
# - Pre-caches platform artifacts for Linux & Web

FLUTTER_HOME_DEFAULT="/usr/local/flutter"
FLUTTER_HOME="${FLUTTER_HOME:-$FLUTTER_HOME_DEFAULT}"
export FLUTTER_HOME
export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"

# Install Flutter if missing
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "[agent_env] Installing Flutter to $FLUTTER_HOME (stable channel)"
  sudo mkdir -p "$FLUTTER_HOME"
  sudo chown -R "$USER":"$USER" "$(dirname "$FLUTTER_HOME")" || true
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

# Avoid analytics noise from agents
export FLUTTER_DISABLE_ANALYTICS=true

# Prepare pub cache for the current user
mkdir -p "$HOME/.pub-cache"

# Verify Flutter & Dart
flutter --version

# Accept Android licenses if Android tooling present (no-op otherwise)
yes | flutter doctor --android-licenses || true

# Pre-download artifacts for common headless workflows
flutter precache --linux --web || true

# If invoked from repo root with pubspec, hydrate deps to warm cache
if [ -f "pubspec.yaml" ]; then
  flutter pub get || true
fi

echo "[agent_env] Environment ready. flutter=$(command -v flutter) dart=$(command -v dart)"
