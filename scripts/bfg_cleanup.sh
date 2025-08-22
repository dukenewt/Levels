#!/usr/bin/env bash
set -euo pipefail

# Helper script to remove common sensitive files with BFG from a mirror repo.
# Usage: BFG_JAR=/path/to/bfg.jar REPO_MIRROR=/path/to/repo.git bash scripts/bfg_cleanup.sh

: "${BFG_JAR:?Set BFG_JAR to the path of bfg-*.jar}"
: "${REPO_MIRROR:?Set REPO_MIRROR to the path of your mirror clone (ends with .git)}"

pushd "$REPO_MIRROR" >/dev/null

declare -a FILES=(
  "GoogleService-Info.plist"
  "google-services.json"
  "firebase_options.dart"
  "firebase_config.swift"
  "firebase.json"
)

for f in "${FILES[@]}"; do
  echo "Removing $f from history..."
  java -jar "$BFG_JAR" --delete-files "$f"
done

echo "Running git GC..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "Done. Force-push the rewritten refs:"
echo "  git push --force --all && git push --force --tags"

popd >/dev/null

