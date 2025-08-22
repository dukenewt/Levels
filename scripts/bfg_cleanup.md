# BFG/Filter-Repo Cleanup Playbook

Use this guide to remove sensitive files from git history. Schedule a maintenance window and coordinate if collaborating.

## 0) Preconditions
- Rotate affected credentials first (Firebase, signing keys, etc.).
- Protect branches in Git hosting to prevent new pushes during maintenance.

## Option A) git-filter-repo (recommended)
```
git clone --mirror <REPO_URL> repo.git && cd repo.git
git filter-repo --force --invert-paths \
  --path-glob '**/GoogleService-Info.plist' \
  --path-glob '**/google-services.json' \
  --path-glob '**/firebase_options.dart' \
  --path 'firebase.json' \
  --path-glob '**/.env*' \
  --path-glob '**/secrets/**' \
  --path-glob '**/*_secret.*' \
  --path-glob '**/*_key.*' \
  --path-glob '**/private_keys/**' \
  --path-glob 'android/**/keystore*' \
  --path-glob '**/*.jks' \
  --path-glob '**/secrets.json' \
  --path-glob '**/config.json'
git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git remote add origin <REPO_URL>
git push --force --all && git push --force --tags
```

## Option B) BFG
```
java -jar bfg.jar --delete-files GoogleService-Info.plist
java -jar bfg.jar --delete-files google-services.json
java -jar bfg.jar --delete-files firebase_options.dart
java -jar bfg.jar --delete-files firebase_config.swift
java -jar bfg.jar --delete-files firebase.json
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force --all && git push --force --tags
```

## Verify
In a fresh clone:
```
git rev-list --all --objects | awk '{print $2}' | \
  grep -E 'GoogleService-Info\.plist|google-services\.json|firebase_options\.dart|(^|/)firebase\.json|\.env($|[^/])' || echo "No matches"
```

