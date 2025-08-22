#!/usr/bin/env bash
set -euo pipefail

# Untrack sensitive files that may be present in the working tree.
# Run this BEFORE committing, and after adding entries to .gitignore.

declare -a FILES=(
  "android/app/google-services.json"
  "ios/Runner/GoogleService-Info.plist"
  "lib/firebase_options.dart"
  "ios/Runner/firebase_config.swift"
  "firebase.json"
)

for f in "${FILES[@]}"; do
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    echo "Removing from git index: $f"
    git rm --cached -f "$f"
  fi
done

echo "Done. Commit the removal and proceed with history cleanup as needed."

