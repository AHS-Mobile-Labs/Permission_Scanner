# Permission Scanner

A comprehensive Android app built with Flutter that scans installed applications and displays their permissions with risk assessment. The app provides an intuitive Material 3 interface with real-time permission analysis, risk dashboard, and privacy scoring.

## Features

### Core Functionality
- **App Scanning**: Scans all installed third-party applications on Android device
- **Permission Analysis**: Extracts and displays requested permissions for each app
- **Risk Assessment**: Categorizes permissions and calculates privacy risk levels
- **Search & Filter**: Real-time search across installed apps by name or package
- **Privacy Scoring**: Assigns a 0-100 privacy score based on dangerous permissions

### UI Screens
- **Home Screen**: Lists all apps with permission count, risk level, and privacy score
- **App Detail Screen**: Shows complete permission list with descriptions and risk indicators
- **Permission Info Screen**: Educational screen explaining all available permissions
- **Risk Dashboard**: Statistical overview with charts showing risk distribution

### Design
- Material 3 design system with custom color palette
- Color-coded permission risk levels (Green/Safe, Orange/Medium, Red/Dangerous)
- Responsive layout optimized for various screen sizes
- Smooth animations and transitions

## Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point with bottom navigation
├── models/
│   ├── app_info.dart        # App model with permissions and risk data
│   └── permission_info.dart # Permission metadata model
├── services/
│   ├── permission_scanner_service.dart  # Kotlin platform channel bridge
│   ├── permission_analyzer.dart         # Permission risk calculation
│   ├── app_providers.dart              # Riverpod state management
│   └── cache_service.dart              # Hive-based local caching
├── screens/
│   ├── home_screen.dart     # App list with search
│   ├── app_detail_screen.dart    # Detailed permission view
│   ├── permission_info_screen.dart   # Permission reference
│   └── dashboard_screen.dart    # Risk statistics & charts
├── widgets/
│   ├── app_card.dart        # Reusable app list item
│   ├── permission_item.dart  # Permission detail widget
│   ├── risk_badge.dart      # Risk level indicator
│   └── stat_card.dart       # Statistics display
└── utils/
    ├── app_colors.dart      # Theme colors and design system
    └── permission_database.dart  # Permission catalog and classification
```

### Technology Stack
- **UI Framework**: Flutter with Material 3
- **State Management**: Riverpod (Functional State Management)
- **Local Storage**: Hive for caching app data
- **Charts**: fl_chart for statistical visualizations
- **Platform Integration**: Kotlin via Method Channels
- **Build System**: Gradle KTS

## Android Implementation

### Kotlin Platform Channel
Located in `android/app/src/main/kotlin/com/example/permission_scanner/`

**Files**:
- `MainActivity.kt`: Implements MethodChannel "permission_scanner" with method "getInstalledApps"
- `PermissionScanner.kt`: Utility class handling PackageManager queries

**Responsibilities**:
- Queries installed applications using PackageManager
- Extracts requested permissions via PackageInfo
- Filters out system applications
- Returns JSON-formatted app data with package name, app name, and permissions

### Permissions Required (AndroidManifest.xml)
- `android.permission.QUERY_ALL_PACKAGES`: Required for Android 11+ to query all apps

## Permission Risk Classification

### Dangerous Permissions (Max 10 points each)
- Camera, Microphone
- Contacts (Read/Write)
- Location (Fine/Coarse)
- SMS (Read/Send)
- Call Log (Read/Write)
- Storage (Read/Write)
- Phone State, Call

### Safe Permissions
- Internet, Network State
- Vibration, Wake Lock
- System alerts, Notifications

### Risk Levels
- **Safe**: 0 dangerous permissions → 100% privacy score
- **Medium**: 1-3 dangerous permissions → 70-90% privacy score
- **Dangerous**: 4+ dangerous permissions → 0-60% privacy score

## State Management (Riverpod)

### Key Providers
- `installedAppsProvider`: Fetches and enriches app data
- `filteredAppsProvider`: Filters apps based on search query
- `dashboardStatsProvider`: Calculates aggregate statistics
- `searchQueryProvider`: Manages search state
- `selectedAppProvider`: Tracks currently viewed app

## Color Palette

| Element | Color | Hex |
|---------|-------|-----|
| Primary | Blue | #1A73E8 |
| Secondary | Teal | #00BFA6 |
| Background | Light Gray | #F5F7FA |
| Cards | White | #FFFFFF |
| Text | Dark Gray | #1F2933 |
| Risk Safe | Green | #43A047 |
| Risk Medium | Orange | #FB8C00 |
| Risk Dangerous | Red | #E53935 |

## Performance Optimizations

1. **Async Loading**: App scanning is fully asynchronous, never blocking the UI
2. **Efficient Parsing**: Single-pass JSON parsing from Kotlin
3. **Lazy Data Loading**: Permissions loaded only when detailed view accessed
4. **Provider Caching**: Riverpod automatically caches computed state
5. **Hive Compression**: Optional local caching with fast key-value access

## Building and Running

### Prerequisites
- Flutter SDK (3.11.1+)
- Android SDK (API 31+)
- Kotlin 1.7+

### Build Steps
```bash
# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release

# Build release App Bundle
flutter build appbundle --release
```

### Development
```bash
# Hot reload during development
flutter run

# Run with verbose logging
flutter run -v
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.4.1 | State management |
| hive | ^2.2.3 | Local storage |
| hive_flutter | ^1.1.0 | Flutter Hive integration |
| fl_chart | ^0.65.0 | Statistics charts |

## Future Enhancements

- Export permission reports to PDF/CSV
- Real-time permission monitoring
- Historical permission tracking
- App permission comparison
- Custom permission risk scoring
- Integration with known privacy policies
- Offline permission database updates

## Troubleshooting

### Issue: Apps not loading
- Ensure Android 11+ device or emulator
- Verify QUERY_ALL_PACKAGES permission granted
- Check logcat for platform channel errors

### Issue: Permissions not showing
- Check if Kotlin service properly parsing JSON
- Verify PackageManager queries return data
- Ensure system apps are filtered correctly

## License

MIT License

## Author

Built as a comprehensive Flutter + Android integration example demonstrating modern app architecture, Material Design 3, and cross-platform development patterns.
