## 6.2.25 Refactoring starting  added the core folder in lib. 
## 6.3.25 added the error handling to the taskCompletion widget within the task_tile and added a testing structure to be able to scale the error handling as the app grows. 
## Getting Started

### Prerequisites

- Flutter SDK (latest version)
- Firebase account
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/level-up-tasks.git
cd level-up-tasks
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Firebase:
   - Create a new Firebase project
   - Add Android and iOS apps
   - Download and add the configuration files:
     - Android: `google-services.json` to `android/app/`
     - iOS: `GoogleService-Info.plist` to `ios/Runner/`

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── widgets/         # Reusable widgets
└── main.dart        # App entry point
```

## Dependencies

- `firebase_core`: Firebase initialization
- `firebase_auth`: User authentication
- `provider`: State management
- `fl_chart`: Charts and graphs
- `lottie`: Animations

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for the backend services
- All contributors and users of the app

## Security and Secrets Policy

- Protected assets and secrets are ignored via `.gitignore` to prevent accidental commits:
  - Generic: `**/secrets/**`, `**/*_secret.*`, `**/*_key.*`, `**/private_keys/**`, `**/*.jks`, `android/**/keystore*`, `**/secrets.json`, `**/config.json`, common cache/tmp paths, local databases, and sensitive media folders.
  - Firebase client config (treated as sensitive per policy): `lib/firebase_options.dart`, `firebase.json`, `ios/Runner/firebase_config.swift`, plus platform files already ignored: `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json`.

### Regenerating Firebase Config Locally

This repo does not track Firebase client config. To build locally:

1. Install FlutterFire CLI (one-time):
   - `dart pub global activate flutterfire_cli`
2. Configure Firebase and generate options:
   - From the project root: `flutterfire configure`
   - This creates `lib/firebase_options.dart` and updates platform configs.
3. Platform files remain untracked; ensure they exist locally:
   - iOS: place `ios/Runner/GoogleService-Info.plist` in the Xcode target.
   - Android: place `android/app/google-services.json` under the app module.

If you rotate Firebase credentials or add environments, re-run `flutterfire configure` and keep generated files uncommitted.

### History Cleanup Guidance (if sensitive files were committed)

If any sensitive files were previously committed, consider purging them from git history and rotating credentials:

- Rotate Firebase keys in the Firebase Console (download fresh `GoogleService-Info.plist` / `google-services.json`).
- Purge history using `git filter-repo` or BFG (run outside CI):
  - `git filter-repo --path lib/firebase_options.dart --path ios/Runner/GoogleService-Info.plist --path android/app/google-services.json --invert-paths`
  - Force-push to protected branches following your org’s policies.

## UI/UX Notes

- The app uses Material 3 (`useMaterial3: true`) via `AppTheme.toThemeData()` to align with Android’s latest guidelines.
- For iOS, audit key flows for HIG-aligned interactions and accessibility (contrast, minimum tap targets, dynamic text).
