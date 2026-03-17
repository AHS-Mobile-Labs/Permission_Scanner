# Permission Scanner - Build Commands Quick Reference

## 🚀 Getting Started (Copy & Paste Commands)

### 1️⃣ Initial Setup
```bash
cd /home/Linox/permission_scanner
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2️⃣ Run on Device/Emulator
```bash
# Basic run
flutter run

# Debug mode with verbose output
flutter run -v

# Release mode
flutter run --release

# Specify device
flutter devices                          # List devices
flutter run -d <device_id>              # Run on specific device
```

### 3️⃣ Build Variants

#### Debug APK
```bash
flutter build apk --debug
```

#### Release APK (Single)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Release APK (Split by Architecture)
```bash
flutter build apk --release --split-per-abi
# Output: 
# - app-armeabi-v7a-release.apk
# - app-arm64-v8a-release.apk
# - app-x86-release.apk
# - app-x86_64-release.apk
```

#### Release App Bundle (Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 4️⃣ Install & Test
```bash
# List connected devices
adb devices

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Install with grant permissions
adb install -g build/app/outputs/flutter-apk/app-release.apk

# Uninstall app
adb uninstall com.example.permission_scanner

# View logs
flutter logs

# Android logcat
adb logcat | grep flutter
adb logcat | grep PermissionScanner
```

### 5️⃣ Development Workflow
```bash
# Start app
flutter run

# Hot reload (press 'r' in terminal)
r

# Hot restart (press 'R' in terminal)
R

# Stop app (press 'q' in terminal)
q

# Analyze code
flutter analyze

# Format code
dart format lib/

# Check outdated packages
flutter pub outdated
```

### 6️⃣ Clean & Reset
```bash
# Clean build artifacts
flutter clean

# Get dependencies fresh
flutter pub get

# Rebuild everything
flutter clean && flutter pub get && flutter pub run build_runner build --delete-conflicting-outputs

# Remove all generated files
rm -rf ios android build .dart_tool pubspec.lock
flutter pub get
```

### 7️⃣ Release Preparation
```bash
# Check for build errors
flutter analyze

# Format all code
dart format lib/

# Build release APK
flutter build apk --release

# Verify APK
unzip -t build/app/outputs/flutter-apk/app-release.apk

# Get APK info
aapt dump badging build/app/outputs/flutter-apk/app-release.apk
```

## 📋 Project Files Reference

### Essential Commands by File Type

#### Run Tests
```bash
flutter test
flutter test test/widget_test.dart
flutter test --concurrency=1
```

#### Code Generation
```bash
flutter pub run build_runner build
flutter pub run build_runner watch
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Update Dependencies
```bash
flutter pub upgrade
flutter pub upgrade --major-versions
flutter pub get
flutter pub add package_name
flutter pub remove package_name
```

## 🎯 Common Tasks

### Task: Run app on specific Android device
```bash
flutter devices                    # Get device ID
flutter run -d emulator-5554      # Run on device
```

### Task: Build and install release APK
```bash
flutter build apk --release
adb install -g build/app/outputs/flutter-apk/app-release.apk
```

### Task: Debug Kotlin platform channel
```bash
flutter run -v                             # Start with verbose
adb logcat | grep PermissionScanner        # Watch logs
```

### Task: Create signed APK for Play Store
```bash
# First time: create keystore
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build signed bundle
flutter build appbundle --release
```

### Task: Test on emulator
```bash
flutter emulators                   # List emulators
flutter emulators launch Pixel_2_API_31    # Start emulator
flutter run -d emulator-5554       # Run app
```

### Task: View app package info
```bash
adb shell pm list packages | grep permission_scanner
adb shell dumpsys package com.example.permission_scanner
```

## 📊 File Locations

```
Source Code:
├── lib/main.dart
├── lib/models/*.dart
├── lib/services/*.dart
├── lib/screens/*.dart
├── lib/widgets/*.dart
└── lib/utils/*.dart

Kotlin Code:
└── android/app/src/main/kotlin/com/example/permission_scanner/*.kt

Config Files:
├── pubspec.yaml
├── android/app/build.gradle.kts
└── android/app/src/main/AndroidManifest.xml

Build Outputs:
└── build/app/outputs/
    ├── flutter-apk/app-release.apk
    └── bundle/release/app-release.aab

Documentation:
├── APP_GUIDE.md
├── SETUP_GUIDE.md
├── QUICK_REFERENCE.md
├── PROJECT_SUMMARY.md
└── IMPLEMENTATION_STATUS.md
```

## 🔍 Debugging Commands

```bash
# View all logs
flutter logs

# View only Flutter/Dart logs
flutter logs -c

# Start app with debug mode info
flutter run --profile

# Use Dart DevTools
flutter pub global activate devtools
devtools

# Run app with DevTools
flutter run --devtools-server-address localhost:9100

# View widget hierarchy
flutter run --debug-ui

# Monitor performance
flutter run --profile

# Trace performance
flutter run --trace-skia

# Check memory usage
adb shell dumpsys meminfo com.example.permission_scanner
```

## 🆘 Troubleshooting Commands

```bash
# Check environment
flutter doctor
flutter doctor -v

# Verify device connection
adb devices
adb devices -l

# Clear device cache
adb shell pm clear com.example.permission_scanner

# Force stop app
adb shell am force-stop com.example.permission_scanner

# Get app crash logs
adb logcat *:E | grep permission_scanner

# Check if app is running
adb shell pidof com.example.permission_scanner

# Get detailed package info
adb shell pm dump com.example.permission_scanner
```

## 📦 Play Store Deployment

```bash
# Build for Play Store
flutter build appbundle --release

# Verify bundle
unzip -t build/app/outputs/bundle/release/app-release.aab

# Upload to Play Console via web interface or:
# Use internal testing track: build/app/outputs/bundle/release/app-release.aab
```

## ✅ Pre-Deployment Checklist Commands

```bash
# Run all checks
flutter clean
flutter pub get
flutter analyze
dart format lib/
flutter test
flutter build apk --release

# Verify builds succeed
echo "Debug: $?" && flutter build apk --debug && echo "Debug OK"
echo "Release: $?" && flutter build apk --release && echo "Release OK"
```

## 🚀 One-Liner Build Commands

```bash
# Quick dev build
flutter run

# Quick release build
flutter build apk --release && adb install -g build/app/outputs/flutter-apk/app-release.apk

# Full clean build
flutter clean && flutter pub get && flutter build apk --release

# Build and test
flutter test && flutter build apk --release

# Clean, test, build, and install
flutter clean && flutter pub get && flutter test && flutter build apk --release && adb install -g build/app/outputs/flutter-apk/app-release.apk
```

---

## 📌 Bookmark These Locations

### Configuration
- Gradle Config: `android/app/build.gradle.kts`
- Manifest: `android/app/src/main/AndroidManifest.xml`
- Pubspec: `pubspec.yaml`

### Source Code
- Main App: `lib/main.dart`
- Kotlin Channel: `android/app/src/main/kotlin/com/example/permission_scanner/`

### Output
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Bundle: `build/app/outputs/bundle/release/app-release.aab`

### Documentation
- Setup: `SETUP_GUIDE.md`
- Reference: `QUICK_REFERENCE.md`
- Full Guide: `APP_GUIDE.md`

---

**Last Updated**: March 17, 2026
**Version**: 1.0.0
