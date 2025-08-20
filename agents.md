
- Protected paths: **/*.env*, **/secrets/**, **/*_secret.*, **/*_key.*, **/private_keys/**, android/**/keystore*, *.jks.
- Explain high level decisions
## UI/UX Guidelines
    2 
    3 When making changes to the UI, please adhere to the following principles:
    4 
    5 *   **Platform-Specific Design:**
    6     *   For Android, follow the latest Material 3 design guidelines.
    7     *   For iOS, follow the latest Apple Human Interface Guidelines.
    8 *   **Clarity and Simplicity:** The UI should be clean, intuitive, and easy to understand.
    9 *   **Consistency:** UI elements should be consistent throughout the application.
   10 *   **Accessibility:** The UI should be accessible to all users, including those with disabilities.


# Firebase Configuration (contains API keys and sensitive data)
lib/firebase_options.dart
firebase.json
ios/Runner/GoogleService-Info.plist
android/app/google-services.json
ios/Runner/firebase_config.swift

# Environment and secrets
.env
.env.local
.env.production
.env.development
*.env
**/secrets.json
**/config.json

# API Keys and credentials
**/api_keys.dart
**/keys.dart
**/credentials.dart
**/*_secret.dart
**/*_key.dart
**/private_keys/

# Build artifacts and generated files
build/
.dart_tool/
.pub-cache/
.packages
pubspec.lock

# Platform-specific build artifacts
ios/build/
ios/Pods/
ios/Runner.xcworkspace/
ios/Runner.xcodeproj/
android/build/
android/.gradle/
android/app/build/

# IDE and system files
.vscode/
.idea/
*.iml
.DS_Store
*.log

# Temporary and cache files
**/.tmp/
**/tmp/
**/cache/
**/.cache/

# User data and database files
**/database.db
**/*.sqlite
**/user_data/

# Screenshots and sensitive media

**/sensitive_images/
**/private_media/