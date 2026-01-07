# CoWorkly - Flutter Mobile App

A Flutter-based mobile application for co-working space management.

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)
- Android Studio or Xcode (for iOS development)
- Node.js (for running the backend server)

## Setup Instructions

### 1. Install Dependencies

```bash
cd flutter_coworkly
flutter pub get
```

### 2. Start the Backend Server

Make sure the backend server is running on port 4000:

```bash
cd ../server
npm install
npm start
```

### 3. Configure for Your Device

The app uses `localhost` by default, which works automatically for:

#### **Android Emulator** ✅
Works out of the box - automatically uses `10.0.2.2`

#### **iOS Simulator** ✅
Works out of the box - uses `localhost` directly

#### **Physical Android Device** 📱
Run this command once before starting the app:
```bash
adb reverse tcp:4000 tcp:4000
```
This forwards the device's port 4000 to your computer's port 4000.

#### **Physical iOS Device** 📱
Edit `lib/services/api_config.dart` and set `_developmentHost` to your computer's local IP:
1. Find your IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
2. Update line 25: `static const String _developmentHost = '192.168.x.x';`
3. Ensure both device and computer are on the same Wi-Fi network

### 4. Run the App

```bash
flutter run
```

Or use your IDE's run button (VS Code/Android Studio)

## Building APK for Distribution

To create an APK file for sharing with others:

```bash
# Release APK (optimized, smaller size)
flutter build apk --release

# The APK will be located at:
# build/app/outputs/flutter-apk/app-release.apk
```

## Project Structure

- `lib/` - Main application code
  - `models/` - Data models
  - `providers/` - State management
  - `screens/` - UI screens
  - `services/` - API services and configuration
  - `widgets/` - Reusable UI components
- `server/` - Backend Node.js server

## Troubleshooting

**Error: Connection refused**
- Ensure the backend server is running
- For physical Android devices, run `adb reverse tcp:4000 tcp:4000`
- Check firewall settings

**Error: No Android SDK found**
- Install Android Studio
- Set `ANDROID_HOME` environment variable
- Run `flutter doctor` to verify setup

**App can't connect to server**
- Verify backend is running: `curl http://localhost:4000` should return a response
- Check the API configuration in `lib/services/api_config.dart`
