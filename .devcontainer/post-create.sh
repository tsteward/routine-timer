#!/usr/bin/env bash
set -euo pipefail

export FLUTTER_HOME=/usr/local/flutter
export PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

# Ensure permissions in case image user changed
if [ -d "$FLUTTER_HOME" ]; then
  sudo chown -R "$USER":"$USER" "$FLUTTER_HOME" || true
fi
mkdir -p "$HOME/.pub-cache" && sudo chown -R "$USER":"$USER" "$HOME/.pub-cache" || true

flutter --version

# Accept Android licenses if android tools are present (no-op otherwise)
yes | flutter doctor --android-licenses || true

# Pre-download Flutter artifacts for this platform
flutter precache --linux --web || true

# Get pub packages
if [ -f "pubspec.yaml" ]; then
  flutter pub get
fi

# Run a basic doctor output for visibility
flutter doctor -v || true
