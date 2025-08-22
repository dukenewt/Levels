#!/usr/bin/env bash
set -euo pipefail

echo "🔐 DailyXP bootstrap: Firebase + tooling setup"

# Verify required tools
need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Missing $1. Please install it." >&2; exit 1; }; }

need dart
need flutter

if ! command -v firebase >/dev/null 2>&1; then
  echo "ℹ️ Install Firebase CLI first: npm install -g firebase-tools"
  exit 1
fi

if ! command -v flutterfire >/dev/null 2>&1; then
  echo "📦 Installing FlutterFire CLI via Dart Pub"
  dart pub global activate flutterfire_cli
  export PATH="$HOME/.pub-cache/bin:$PATH"
fi

PROJECT_ID=${FIREBASE_PROJECT_ID:-}
ANDROID_PACKAGE=${ANDROID_APP_ID:-com.dailyxp}
IOS_BUNDLE_ID=${IOS_BUNDLE_ID:-com.sam.dailyxp}

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Set FIREBASE_PROJECT_ID in your environment before running."
  echo "   Example: export FIREBASE_PROJECT_ID=your-firebase-project"
  exit 1
fi

echo "🔥 Running flutterfire configure for $PROJECT_ID"
flutterfire configure \
  --yes \
  --project="$PROJECT_ID" \
  --platforms=ios,android \
  --android-package-name="$ANDROID_PACKAGE" \
  --ios-bundle-id="$IOS_BUNDLE_ID" \
  --out=lib/firebase_options.dart

echo "✅ Firebase configuration generated at lib/firebase_options.dart (git-ignored)"

