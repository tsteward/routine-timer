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

persist_path_updates() {
  local snippet="# Added by routine_timer scripts/agent_env.sh\nexport FLUTTER_HOME=\"$FLUTTER_HOME\"\nexport PATH=\"$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:\$PATH\""

  # System-wide via /etc/profile.d if possible
  if command -v sudo >/dev/null 2>&1 || [ "$(id -u)" -eq 0 ]; then
    if [ "$(id -u)" -eq 0 ]; then
      echo -e "$snippet" > /etc/profile.d/flutter.sh
      chmod 644 /etc/profile.d/flutter.sh
    else
      echo -e "$snippet" | sudo tee /etc/profile.d/flutter.sh >/dev/null
      sudo chmod 644 /etc/profile.d/flutter.sh || true
    fi
    echo "[agent_env] Persisted PATH to /etc/profile.d/flutter.sh"
  fi

  # User-level fallbacks
  append_if_missing "$HOME/.profile" "$snippet"
  append_if_missing "$HOME/.bashrc" "$snippet"
  append_if_missing "$HOME/.zshrc" "$snippet"
}

append_if_missing() {
  local file="$1"
  local content="$2"
  mkdir -p "$(dirname "$file")"
  if [ ! -f "$file" ]; then
    echo -e "$content" > "$file"
    echo "[agent_env] Created $file with Flutter PATH"
    return
  fi
  if ! grep -qs "FLUTTER_HOME=.*flutter" "$file"; then
    echo -e "\n$content" >> "$file"
    echo "[agent_env] Appended Flutter PATH to $file"
  fi
}

# Install Flutter if missing (with fallback to user directory when system path is not writable)
if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  # If installing to /usr/local/flutter and parent is not writable, fall back to user dir
  parent_dir="$(dirname "$FLUTTER_HOME")"
  if [ ! -w "$parent_dir" ] && ! { [ "$(id -u)" -eq 0 ] || command -v sudo >/dev/null 2>&1; }; then
    FLUTTER_HOME="$HOME/.local/flutter"
    export FLUTTER_HOME
    export PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"
    echo "[agent_env] Falling back to user install at $FLUTTER_HOME"
  fi

  echo "[agent_env] Installing Flutter to $FLUTTER_HOME (stable channel)"
  if [ "$(id -u)" -eq 0 ]; then
    mkdir -p "$FLUTTER_HOME"
    chown -R "$USER":"$USER" "$FLUTTER_HOME" || true
  elif command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p "$FLUTTER_HOME"
    sudo chown -R "$USER":"$USER" "$FLUTTER_HOME" || true
  else
    mkdir -p "$FLUTTER_HOME" || true
    chown -R "$USER":"$USER" "$FLUTTER_HOME" || true
  fi
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

persist_path_updates

echo "[agent_env] Environment ready. flutter=$(command -v flutter) dart=$(command -v dart)"
