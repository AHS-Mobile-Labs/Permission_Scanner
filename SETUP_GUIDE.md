# Permission Scanner - Setup & Build Guide

## Project Overview

Permission Scanner is a production-ready Flutter application that demonstrates:
- Modern Material 3 UI design
- Clean architecture with separation of concerns
- Kotlin platform channels for Android integration
- Riverpod state management
- Hive local storage
- Statistical visualization with fl_chart

## Quick Start

### Prerequisites
```bash
# Verify Flutter installation
flutter doctor

# Required:
# - Flutter SDK 3.11.1+
# - Dart SDK (included with Flutter)
# - Android SDK API 31+
# - Kotlin 1.7+

# Optional:
# - VS Code with Flutter/Dart extensions
# - Android Studio for emulator management
```

### Setup Steps

#### 1. Get Dependencies
```bash
cd /home/Linox/permission_scanner
flutter pub get
```

#### 2. Generate Code
```bash
# Generate Hive adapters and other generated files
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 3. Run on Device/Emulator
```bash
# List available devices
flutter devices

# Run app
flutter run

# Run with debug logging
flutter run -v

# Run release build
flutter run --release
```

### Building for Release

#### APK Build (for direct installation)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Split APKs (for multiple architectures)
```bash
flutter build apk --release --split-per-abi
# Output: build/app/outputs/flutter-apk/
#   - app-armeabi-v7a-release.apk
#   - app-arm64-v8a-release.apk
#   - app-x86-release.apk
#   - app-x86_64-release.apk
```

## Project Structure

### Dart/Flutter Code
```
lib/
├── main.dart                           # App entry point
├── models/                             # Data models
│   ├── app_info.dart                  # App representation
│   └── permission_info.dart           # Permission metadata
├── services/                           # Business logic
│   ├── permission_scanner_service.dart # Kotlin bridge
│   ├── permission_analyzer.dart        # Risk calculation
│   ├── app_providers.dart              # Riverpod providers
│   └── cache_service.dart              # Hive caching
├── screens/                            # UI screens
│   ├── home_screen.dart               # App list
│   ├── app_detail_screen.dart         # App permissions
│   ├── permission_info_screen.dart    # Permission guide
│   └── dashboard_screen.dart          # Statistics
├── widgets/                            # Reusable components
│   ├── app_card.dart                  # App list item
│   ├── permission_item.dart           # Permission widget
│   ├── risk_badge.dart                # Risk indicator
│   └── stat_card.dart                 # Stats display
└── utils/                              # Utilities
    ├── app_colors.dart                # Theme & colors
    └── permission_database.dart       # Permission catalog
```

### Kotlin/Android Code
```
android/
├── app/
│   ├── src/main/
│   │   ├── kotlin/com/example/permission_scanner/
│   │   │   ├── MainActivity.kt         # Method channel setup
│   │   │   └── PermissionScanner.kt    # Permission querying
│   │   ├── AndroidManifest.xml        # Permissions & metadata
│   │   └── res/                       # Resources
│   └── build.gradle.kts               # App build config
├── build.gradle.kts                   # Root build config
└── settings.gradle.kts                # Settings
```

## Architecture Details

### Platform Channel Communication
```
Flutter → Method Channel → Kotlin
  "permission_scanner"
    └── "getInstalledApps()" → JSON String
```

### Data Flow
```
1. User opens app → Home screen initialized
2. Riverpod installedAppsProvider triggers
3. PermissionScannerService calls Kotlin
4. Kotlin PermissionScanner queries PackageManager
5. JSON returned and parsed in Dart
6. PermissionAnalyzer enriches data (risk scores)
7. UI renders app list with risk indicators
```

### State Management
```
FutureProvider → Async data loading
StateProvider → Search query state
Derived providers → Filtered results, statistics
```

## Kotlin Implementation

### Method Channel Handler (MainActivity.kt)
- Directly receives "getInstalledApps" calls
- Delegates to PermissionScanner utility
- Handles errors and returns JSON

### Permission Scanner (PermissionScanner.kt)
- Uses PackageManager.getInstalledApplications()
- Filters system apps
- Queries PackageInfo for permissions
- Returns JSON: `{"apps": [{packageName, appName, permissions}]}`

### Android Permissions
```xml
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```
- Required for Android 11+
- Declared in AndroidManifest.xml
- Query all installed packages

## Configuration

### Minimum SDK
- minSdkVersion: 31 (5.0 Lollipop equivalent for Flutter)
- targetSdkVersion: 34 (Latest at publication)

### Kotlin Version
- kotlin-gradle-plugin: 1.9.x
- JVM target: 17

### Flutter Version
- Minimum: 3.11.1
- Recommended: Latest stable

## Customization

### Change App Name
```bash
# Android
android/app/build.gradle.kts:
  applicationId = "com.example.permission_scanner"

android/app/src/main/AndroidManifest.xml:
  android:label="@string/app_name"
```

### Change Colors
Edit `lib/utils/app_colors.dart`:
```dart
static const Color primary = Color(0xFF1A73E8);
static const Color riskSafe = Color(0xFF43A047);
// etc.
```

### Add More Permissions to Database
Edit `lib/utils/permission_database.dart`:
```dart
'android.permission.NEW_PERM': PermissionInfo(
  name: 'android.permission.NEW_PERM',
  displayName: 'Permission Name',
  description: 'What this does',
  group: 'Category',
  isDangerous: true/false,
),
```

### Adjust Risk Scoring
Edit `lib/services/permission_analyzer.dart`:
```dart
static int calculatePrivacyScore(List<String> permissions) {
  int score = 100;
  for (final permission in permissions) {
    if (dangerousPermissions.contains(permission)) {
      score -= 10;  // Adjust penalty
    }
  }
  return score.clamp(0, 100);
}
```

## Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test --concurrency=1
```

### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

### Manual Testing Checklist
- [ ] App list loads within 5 seconds
- [ ] Search filters apps correctly
- [ ] Tapping app shows all permissions
- [ ] Risk colors display correctly
- [ ] Dashboard stats are accurate
- [ ] No UI blocking during app scan

## Troubleshooting

### Issue: Build fails with "Kotlin not found"
```bash
# Solution: Update Android plugin in settings.gradle.kts
flutter upgrade
flutter pub get
```

### Issue: "QUERY_ALL_PACKAGES permission denied"
```bash
# Solution: Install app with permission on Android 11+
adb install -g build/app/outputs/flutter-apk/app-release.apk
```

### Issue: Kotlin platform channel returning empty list
```bash
# Solution: Check Kotlin implementation
adb logcat | grep PermissionScanner
# Verify PackageManager.GET_META_DATA flag
```

### Issue: App crashes on startup
```bash
# Solution: Check Firebase/Riverpod initialization
flutter run -v
# Look for stack trace in console
```

### Issue: Permissions not showing in details screen
```bash
# Solution: Verify JSON parsing in permission_scanner_service.dart
# Add debug prints:
print('Raw JSON: $result');
print('Parsed apps: $apps');
```

## Performance Optimization

### Current Optimizations
1. **Async scanning**: Non-blocking UI
2. **Single-pass JSON parsing**: No redundant processing
3. **Lazy loading**: Load permission details on demand
4. **Riverpod caching**: Automatic state caching
5. **Hive compression**: Efficient local storage

### Further Optimization Ideas
1. Implement pagination for large app lists
2. Cache app metadata between sessions
3. Use compute() for JSON parsing on isolate
4. Implement incremental search with debouncing
5. Optimize Kotlin queries with parallel processing

## Dependencies Summary

| Package | Version | Size | Purpose |
|---------|---------|------|---------|
| flutter_riverpod | 2.4.1 | 300KB | State management |
| hive | 2.2.3 | 200KB | Local data storage |
| hive_flutter | 1.1.0 | 50KB | Hive Flutter integration |
| fl_chart | 0.65.0 | 400KB | Charts & graphs |

**Total APK size**: ~15-20MB (varies by architecture)

## Security Considerations

1. **Sensitive Data**: Permission data reflects installed apps (non-sensitive)
2. **Storage**: Hive cache stored in app-specific directory (secure)
3. **Network**: No network calls in current implementation
4. **Permissions**: Requested only necessary permissions
5. **Code Obfuscation**: Enable for release builds

## Next Steps

### Immediate Enhancements
- [ ] Add app grouping by risk level
- [ ] Implement permission sorting options
- [ ] Add app launch from scanner

### Short Term
- [ ] Export reports feature
- [ ] Dark mode support
- [ ] Multiple language support
- [ ] Real-time permission monitoring

### Long Term
- [ ] Permission policy database
- [ ] Privacy score comparison
- [ ] AI-powered risk prediction
- [ ] Cloud sync for settings

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Guide](https://riverpod.dev)
- [Android PackageManager API](https://developer.android.com/reference/android/content/pm/PackageManager)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [Material 3 Design](https://m3.material.io)

## Support

For issues or questions:
1. Check troubleshooting section
2. Review logcat output: `flutter logs`
3. Check Android Studio / logcat for Kotlin errors
4. Verify device is Android 5.0+ with API 31+

## License

MIT License - See LICENSE file for details
