# Level Up Tasks

A gamified task management app that helps you stay productive by turning your daily tasks into an RPG-like experience. Complete tasks to earn XP, level up, and unlock achievements!

## Features

- 🎮 Gamified task management
- 📊 Task statistics and progress tracking
- 🏆 Achievement system
- 🌙 Dark mode support
- 📱 Beautiful, modern UI
- 🔐 User authentication
- 📈 Visual progress tracking

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