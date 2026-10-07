#!/bin/bash
# Sets up everything needed to build the widgets in a new session (user, 07-Oct-2026: "keep the library in GitHub").
#   bash tools/widget-toolchain.sh        then, in a widget folder:  ANDROID_JAR=$HOME/tc/android.jar bash build.sh
# The build tools come from Ubuntu; android.jar (API 34, 77 MB) comes from this repo's "build-tools" branch, because
# Google's download server is blocked in cloud sessions. It is checked against android.jar.sha256 from the same branch.
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v aapt >/dev/null || ! command -v dalvik-exchange >/dev/null || ! command -v zipalign >/dev/null || ! command -v apksigner >/dev/null || ! command -v javac >/dev/null; then
  apt-get update -q >/dev/null && apt-get install -y -q aapt dalvik-exchange zipalign apksigner default-jdk-headless >/dev/null
fi
mkdir -p "$HOME/tc"
git fetch -q --depth 1 origin build-tools
want=$(git show FETCH_HEAD:android.jar.sha256 | cut -d' ' -f1)
if [ -f "$HOME/tc/android.jar" ] && [ "$(sha256sum "$HOME/tc/android.jar" | cut -d' ' -f1)" = "$want" ]; then echo "android.jar already in place"; else
  git show FETCH_HEAD:android.jar > "$HOME/tc/android.jar"
  [ "$(sha256sum "$HOME/tc/android.jar" | cut -d' ' -f1)" = "$want" ] || { echo "android.jar checksum mismatch"; exit 1; }
  echo "android.jar ready: $HOME/tc/android.jar"
fi
echo "Widget build tools ready."
