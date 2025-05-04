# Female Health App - Frontend

This is the Flutter mobile app I developed for my final year project, designed to provide women with a comprehensive tool for understanding their menstrual cycles.


## Features

- **Period Tracking**: Easily log flow levels and symptoms with intuitive UI
- **Mood Tracking**: Record your daily moods and energy levels
- **Cycle Visualization**: See where you are in your cycle with my custom phase visualizer
- **Trend Analysis**: Interactive charts show your patterns over time
- **Personalized Insights**: The app gets to know your unique patterns


## Getting Started

### Prerequisites

- Flutter SDK (I used version 3.7.0)
- Android Studio or VS Code with Flutter extensions
- An emulator or physical device for testing

### Installation

1. Clone my repository
```bash
git clone https://github.com/AishaKram/Nur..git
cd Frontend
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

### Configuration

The app connects to my Flask backend. You'll need to update the API URL in `lib/api_service.dart` if you're running the backend somewhere other than localhost:

```dart
static const String baseUrl = "http://127.0.0.1:5000";  
```


## Challenges Overcome

Some of the challenges I tackled during frontend development:
- Creating an intuitive UI for tracking flow levels
- Building responsive layouts that work on different devices
- Implementing interactive charts for data visualization
- Connecting to the ML backend for predictions

## Testing

Run the tests with:

```bash
flutter test
```

