# Permission Scanner - Quick Reference

## 📁 Project Structure Overview

### Key Directories
```
lib/
├── models/              # Data structures (AppInfo, PermissionInfo)
├── services/            # Business logic (Scanning, Analysis, Providers)
├── screens/             # UI screens (Home, Detail, Info, Dashboard)
├── widgets/             # Reusable UI components
└── utils/               # Utilities (Colors, Permission Database)

android/
└── app/src/main/
    ├── kotlin/          # Kotlin platform channel implementation
    └── AndroidManifest.xml
```

## 🚀 Getting Started

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Run app
flutter run

# 4. Build release
flutter build apk --release
```

## 🎨 Colors & Theme

| Element | Color | Hex |
|---------|-------|-----|
| Primary | #1A73E8 | Blue |
| Secondary | #00BFA6 | Teal |
| Background | #F5F7FA | Light Gray |
| Safe | #43A047 | Green |
| Medium | #FB8C00 | Orange |
| Dangerous | #E53935 | Red |

Edit in: `lib/utils/app_colors.dart`

## 📊 Key Classes

### Models
- **AppInfo**: Represents an installed app with permissions and risk data
- **PermissionInfo**: Represents a single permission with metadata

### Services
- **PermissionScannerService**: Bridge to Kotlin platform channel
- **PermissionAnalyzer**: Calculates risk levels and privacy scores
- **CacheService**: Hive-based local data caching

### Providers (Riverpod)
- **installedAppsProvider**: Loads and enriches app data
- **filteredAppsProvider**: Filters apps by search query
- **dashboardStatsProvider**: Calculates aggregate statistics
- **searchQueryProvider**: Manages search state
- **selectedAppProvider**: Tracks current app selection

## 🔧 Common Customizations

### Add New Permission to Database
```dart
// lib/utils/permission_database.dart
permissionDatabase['android.permission.NEW_PERM'] = PermissionInfo(
  name: 'android.permission.NEW_PERM',
  displayName: 'Display Name',
  description: 'What it does',
  group: 'Category',
  isDangerous: true/false,
);
```

### Adjust Risk Scoring
```dart
// lib/services/permission_analyzer.dart
static int calculatePrivacyScore(List<String> permissions) {
  int score = 100;
  for (final permission in permissions) {
    if (dangerousPermissions.contains(permission)) {
      score -= 10;  // Adjust this value
    }
  }
  return score.clamp(0, 100);
}
```

### Change Risk Thresholds
```dart
// lib/services/permission_analyzer.dart
static RiskLevel analyzeRiskLevel(int dangerousPermissionCount) {
  if (dangerousPermissionCount == 0) return RiskLevel.safe;
  if (dangerousPermissionCount <= 3) return RiskLevel.medium;  // Adjust threshold
  return RiskLevel.dangerous;
}
```

### Modify Color Palette
```dart
// lib/utils/app_colors.dart
static const Color primary = Color(0xFF1A73E8);  // Change hex value
static const Color riskSafe = Color(0xFF43A047);
```

## 🔗 Platform Channel Integration

### Channel Name
```
"permission_scanner"
```

### Available Methods
```
"getInstalledApps()" → Returns JSON string
```

### Expected JSON Format
```json
{
  "apps": [
    {
      "packageName": "com.example.app",
      "appName": "Example App",
      "permissions": ["android.permission.CAMERA", ...]
    }
  ]
}
```

### Kotlin Implementation Locations
- `android/app/src/main/kotlin/com/example/permission_scanner/MainActivity.kt`
- `android/app/src/main/kotlin/com/example/permission_scanner/PermissionScanner.kt`

## 📱 Screens Navigation

```
MainScreen (bottom navigation)
├── HomeScreen (Apps tab)
│   └── AppDetailScreen (on app tap)
├── PermissionInfoScreen (Permissions tab)
└── DashboardScreen (Dashboard tab)
```

## 🛠️ Development Workflow

### Hot Reload
```bash
flutter run
# Press 'r' in terminal to hot reload
# Press 'R' to hot restart
```

### Debug Logging
```dart
print('Debug: $variable');  // Console output
debugPrint('Debug: $variable');  // Flutter debug
```

### Enable Verbose Logging
```bash
flutter run -v
adb logcat | grep flutter
```

### Format Code
```bash
dart format lib/
```

### Analyze Code
```bash
flutter analyze
```

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/widget_test.dart
```

### Build Release
```bash
flutter build apk --release
flutter build appbundle --release
flutter build apk --release --split-per-abi
```

## 📚 State Management (Riverpod)

### Watch Provider in Widget
```dart
final data = ref.watch(installedAppsProvider);
```

### Update State
```dart
ref.read(searchQueryProvider.notifier).state = 'new value';
```

### Async Data Pattern
```dart
asyncData.when(
  data: (data) => Text(data.toString()),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
)
```

## 🔒 Android Permissions

### Declared Permissions
```xml
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

### Location: `android/app/src/main/AndroidManifest.xml`

## 📦 Dependencies

| Package | Command |
|---------|---------|
| Add package | `flutter pub add package_name` |
| Update all | `flutter pub upgrade` |
| Clean cache | `flutter clean && flutter pub get` |
| Show deps | `flutter pub deps` |

## 🐛 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Build fails | `flutter clean && flutter pub get` |
| Hot reload fails | `flutter run` or restart emulator |
| Kotlin error | Check SDK API level ≥ 31 |
| Empty app list | Check QUERY_ALL_PACKAGES permission |
| Crash on startup | Check `flutter logs` for stack trace |

## 📄 Important Files Reference

| File | Purpose |
|------|---------|
| lib/main.dart | App entry point + navigation |
| lib/services/app_providers.dart | All state management |
| lib/utils/permission_database.dart | Permission catalog |
| android/app/build.gradle.kts | Android build config |
| pubspec.yaml | Dependencies |

## 💡 Tips & Tricks

1. **Search optimization**: Searches update instantly with debouncing via Riverpod
2. **Memory efficient**: System apps filtered in Kotlin layer
3. **Caching**: Optional Hive caching for offline support
4. **Charts**: fl_chart handles large datasets efficiently
5. **Theme**: Single source of truth in AppColors

## 🔍 Debugging Tips

### Check Platform Channel
```kotlin
// Add to PermissionScanner.kt
Log.d("PermissionScanner", "Querying packages...")
```

### View Dart Logs
```bash
flutter logs
```

### Check Android Logs
```bash
adb logcat | grep PermissionScanner
adb logcat | grep permission_scanner
```

### Verify JSON Output
```dart
print('Raw JSON: $result');  // In permission_scanner_service.dart
```

## 📞 Support Resources

- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod Guide](https://riverpod.dev)
- [Kotlin Docs](https://kotlinlang.org/docs/)
- [Material 3](https://m3.material.io)
- [Android PackageManager](https://developer.android.com/reference/android/content/pm/PackageManager)

## ✅ Pre-Commit Checklist

- [ ] Code formatted: `dart format lib/`
- [ ] No analysis errors: `flutter analyze`
- [ ] Tested on device
- [ ] Hot reload works
- [ ] Release build succeeds
- [ ] Updated documentation if needed

## 🚢 Deployment Checklist

- [ ] Version bumped in pubspec.yaml
- [ ] Tested on real Android device
- [ ] Release APK builds successfully
- [ ] App installs and launches
- [ ] All features tested
- [ ] Screenshots captured
- [ ] Store listing updated (if Play Store)

---

**Last Updated**: March 17, 2026
**Version**: 1.0.0
**Status**: Production Ready ✅
