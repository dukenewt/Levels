#!/bin/bash

# Create backup directory with timestamp
BACKUP_DIR="level_up_tasks_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Copy essential project files
echo "Copying project files..."

# Copy main project files
cp -R lib "$BACKUP_DIR/"
cp -R assets "$BACKUP_DIR/"
cp -R ios "$BACKUP_DIR/"
cp -R android "$BACKUP_DIR/"
cp -R web "$BACKUP_DIR/"
cp -R macos "$BACKUP_DIR/"
cp -R windows "$BACKUP_DIR/"
cp -R linux "$BACKUP_DIR/"

# Copy configuration files
cp pubspec.yaml "$BACKUP_DIR/"
cp analysis_options.yaml "$BACKUP_DIR/"
cp .metadata "$BACKUP_DIR/"

# Create a zip archive
echo "Creating zip archive..."
zip -r "$BACKUP_DIR.zip" "$BACKUP_DIR"

# Clean up temporary directory
rm -rf "$BACKUP_DIR"

echo "Backup completed! Archive saved as $BACKUP_DIR.zip"
echo "The backup includes:"
echo "- All source code (lib directory)"
echo "- Assets (images, fonts, animations)"
echo "- Platform-specific code (ios, android, web, etc.)"
echo "- Configuration files (pubspec.yaml, etc.)"
echo ""
echo "To restore this backup:"
echo "1. Unzip the archive: unzip $BACKUP_DIR.zip"
echo "2. Run 'flutter pub get' in the restored directory"
echo "3. For iOS: cd ios && pod install && cd .." 