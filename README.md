<p align="center">
  <img src="asset/icon/Permission Scanner.png" width="128" height="128" alt="Permission Scanner icon" />
</p>

<h1 align="center">Permission Scanner</h1>

<p align="center">
  An Android privacy companion that scans installed apps and APK files, explains their permissions, and highlights risky behavior before it becomes invisible.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-%5E3.11.1-0175C2?logo=dart&logoColor=white" />
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" />
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.4%2B5-brightgreen" />
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-green.svg" /></a>
</p>

<p align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=18&duration=3000&pause=1000&color=0E7B72&center=true&vCenter=true&width=550&height=35&lines=Android+Permission+%26+Privacy+Scanner;Real-Time+App+Risk+Classification;Pre-Install+APK+Vulnerability+Audit;On-Device+Behavioral+Intelligence;Zero+Data+Collection+%E2%80%A2+100%25+Offline" alt="Permission Scanner Dynamic Features" />
</p>

---

## App Preview

<p align="center">
  <img src="asset/github-img/permission_scanner_demo.gif" width="360" alt="Permission Scanner Animated Walkthrough" />
</p>

## Overview

Permission Scanner gives Android users a readable view of what each installed app can access. It combines package-level permission scanning, local risk analysis, app comparison, APK pre-install checks, privacy timelines, and exportable reports in one Flutter app.

The app is designed to be transparent: scanning happens through native Android APIs, analysis runs locally, and the codebase keeps permission explanations and risk rules easy to inspect.

## Features

- **Installed app scanner** - reads installed packages through a native `MethodChannel` and returns permissions, install source, system app status, SDK data, trackers, services, receivers, and app metadata.
- **Privacy risk scoring** - calculates a 0-100 privacy score and classifies apps as safe, medium, dangerous, or critical based on dangerous permissions and high-risk behavior signals.
- **Security dashboard** - summarizes overall device risk, permission exposure, risky apps, and recent permission changes.
- **App detail view** - shows permission groups, risk signals, install details, trackers, and developer-level permission data.
- **Permission justification** - maps common app capabilities to required permissions and helps spot access that does not match an app's purpose.
- **APK scanner** - scans an APK file before installation and reports permissions, trackers, packers, overlays, accessibility use, background behavior, and spyware indicators.
- **App comparison** - compares two installed apps across permission count, dangerous permissions, trackers, background services, auto-start behavior, internet data risk, and open-source status.
- **Privacy tools** - includes a permission library, timeline view, report export, privacy policy, and project transparency links.
- **Smart caching** - uses Hive and package fingerprints to avoid unnecessary full rescans when the installed app set has not changed.
- **Local alerts** - optionally sends notifications when high-risk permission patterns are detected.

## Screenshots

<p align="center">
  <img src="asset/github-img/%233/Screenshot_20261012_224847.jpg" width="180" alt="Security Dashboard" />
  <img src="asset/github-img/%233/Screenshot_20261012_224858.jpg" width="180" alt="Installed Apps" />
  <img src="asset/github-img/%233/Screenshot_20261012_224904.jpg" width="180" alt="Privacy Tools" />
  <img src="asset/github-img/%233/Screenshot_20261012_225022.jpg" width="180" alt="Compare Apps" />
  <img src="asset/github-img/%233/Screenshot_20261012_225031.jpg" width="180" alt="App Details" />
  <img src="asset/github-img/%233/Screenshot_20261012_225043.jpg" width="180" alt="Permission Library" />
  <img src="asset/github-img/%233/Screenshot_20261012_225048.jpg" width="180" alt="Privacy Timeline" />
  <img src="asset/github-img/%233/Screenshot_20261012_225140.jpg" width="180" alt="App Intelligence" />
</p>

## Tech Stack

| Area | Technology |
|---|---|
| App framework | Flutter |
| Language | Dart |
| State management | `flutter_riverpod` |
| Local cache | `hive`, `hive_flutter` |
| Notifications | `flutter_local_notifications` |
| Permissions | `permission_handler` |
| Deep linking / external links | `url_launcher` |
| Storage paths | `path_provider` |
| Native integration | Android `MethodChannel('permission_scanner')` |

## Project Structure

```text
lib/
├── main.dart                         # App bootstrap, splash flow, bottom navigation
├── models/                           # App, permission, loading, and justification models
├── screens/                          # Dashboard, app list, details, compare, tools, APK scan, policy
├── services/                         # Native scanner, cache, providers, risk analysis, notifications
├── utils/                            # Theme, colors, and permission database
└── widgets/                          # Reusable app cards, badges, filters, charts, dialogs

android/
└── app/src/main/                     # Android manifest and native MethodChannel implementation

asset/
├── icon/                             # App icons and QR asset
└── github-img/                       # README screenshots
```

## Getting Started

### Prerequisites

- Flutter stable SDK with Dart `^3.11.1`
- Android SDK
- Android device or emulator
- Java/Kotlin toolchain supported by your Flutter installation

### Run Locally

```bash
git clone https://github.com/AHS-Mobile-Labs/Permission_Scanner.git
cd Permission_Scanner
flutter pub get
flutter run
```

### Analyze and Test

```bash
flutter analyze
flutter test
```

### Build APK

```bash
flutter build apk --release
```

### Generate Launcher Icons

```bash
dart run flutter_launcher_icons
```

## Android Permissions

| Permission | Purpose |
|---|---|
| `QUERY_ALL_PACKAGES` | Allows the app to inspect installed packages and their declared permissions. |
| `POST_NOTIFICATIONS` | Enables optional local alerts about risky app permission patterns on supported Android versions. |
| `WRITE_EXTERNAL_STORAGE` | Used only on Android 9 and below for exporting reports to shared storage. |

## How Scanning Works

1. Flutter requests app data through `PermissionScannerService`.
2. Android native code returns installed app or APK metadata, including target SDK and minimum SDK, through `MethodChannel('permission_scanner')`.
3. JSON parsing and enrichment run off the UI thread with `compute()`.
4. `PermissionAnalyzer` assigns risk levels, privacy scores, and risk signals.
5. Riverpod providers feed the dashboard, app list, compare screen, timeline, and privacy tools.
6. Hive stores cached scan data and invalidates it when the installed app fingerprint changes.

## Key Files

| File | Purpose |
|---|---|
| `lib/services/permission_scanner_service.dart` | Flutter-side native bridge for app scanning, APK scanning, exports, sharing, and fingerprints. |
| `lib/services/permission_analyzer.dart` | Risk scoring and permission analysis rules. |
| `lib/services/app_providers.dart` | Riverpod providers for installed apps, filters, loading state, and permission timeline data. |
| `lib/services/cache_service.dart` | Hive cache initialization and persistence. |
| `lib/utils/permission_database.dart` | Human-readable Android permission reference. |
| `lib/screens/dashboard_screen.dart` | Main security dashboard. |
| `lib/screens/privacy_tools_screen.dart` | APK scanner, timeline, permission library, reports, and transparency tools. |
| `android/app/src/main/kotlin/com/ahsmobilelabs/permissionScanner/PermissionScanner.kt` | Android package scanning, APK inspection, exports, and sharing. |

## Privacy

Permission Scanner is built around local analysis. It reads app metadata from the device, calculates risk locally, and presents results in the app. Exported JSON/PDF reports and shared summaries are created only when the user chooses those actions.

For the full policy text, see `privacypolicy.txt` or the in-app Privacy Policy screen.

## License

This project is licensed under the terms of the [MIT License](LICENSE).

## Author

[Ameer Hamza Saifi](https://github.com/ameerhamzasaifi)

© 2026 AHS Mobile Labs
