<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white" />
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" />
  <img alt="License" src="https://img.shields.io/github/license/AHS-Mobile-Labs/Permission_Scanner" />
</p>
<p align="center">
  <img src="asset/icon/Permission Scanner.png" width="128" height="128" alt="Permission Scanner icon" />
</p>

<h1 align="center">Permission Scanner</h1>

<p align="center">
  A lightweight Android app that reveals exactly what permissions every installed app holds — and whether they actually need them.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.11+-02569B?logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white" />
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" />
  <img alt="License" src="https://img.shields.io/github/license/AHS-Mobile-Labs/Permission_Scanner" />
  <img alt="Release" src="https://img.shields.io/github/v/release/AHS-Mobile-Labs/Permission_Scanner?color=brightgreen&logo=github" />
</p>

---

## Features

- **Full app scan** — scans every installed app via a native `MethodChannel`, returning permissions, install source, and system flag
- **Risk analysis** — assigns each app a privacy score (0–100) and risk level (safe / medium / dangerous) based on dangerous permission count
- **Justification engine** — maps app capabilities (e.g. "Take Photos") to the permissions they require and flags unjustified access
- **Smart caching** — fingerprint-based cache invalidation means the UI loads instantly on repeat visits; only re-scans when apps change
- **Interactive dashboard** — animated security score ring, risk distribution bar, quick actions, and per-app tiles
- **Permission database** — searchable reference of all Android permissions with descriptions, grouped by category
- **Notifications** — optional local alerts when a newly installed app requests a high number of dangerous permissions
- **Filter & sort** — segment by user apps, system apps, or unknown sources; sort by name or risk level
- **Developer mode** — toggle to reveal low-level / non-dangerous permissions on the detail screen
- **Verification dialog** — tag an app's capabilities and see which permissions are justified by those capabilities

## Screenshots

<p align="center">
  <img src="asset/github-img/%231/Screenshot_20260413_173040.jpg" width="180" alt="Security Dashboard" />
  <img src="asset/github-img/%231/Screenshot_20260413_173051.jpg" width="180" alt="App List" />
  <img src="asset/github-img/%231/Screenshot_20260413_173105.jpg" width="180" alt="Permission Info" />
  <img src="asset/github-img/%231/Screenshot_20260413_173114.jpg" width="180" alt="Dashboard Risk Filter" />
</p>

## Architecture

```
lib/
├── main.dart                          # App entry, splash → main flow
├── models/
│   ├── app_info.dart                  # AppInfo model with RiskLevel enum
│   ├── permission_info.dart           # PermissionInfo model
│   └── permission_justification.dart  # Capability → permission mapping
├── screens/
│   ├── splash_screen.dart             # Animated splash with progress
│   ├── home_screen.dart               # App list with search & filters
│   ├── app_detail_screen.dart         # Per-app permission breakdown
│   ├── permission_info_screen.dart    # Permission reference database
│   └── dashboard_screen.dart          # Security overview dashboard
├── services/
│   ├── app_providers.dart             # Riverpod state providers
│   ├── cache_service.dart             # Hive-backed cache (5 boxes)
│   ├── notification_service.dart      # Local notification service
│   ├── permission_analyzer.dart       # Risk scoring & analysis
│   ├── permission_justification_service.dart
│   └── permission_scanner_service.dart # Native bridge
├── utils/
│   ├── app_colors.dart                # Material 3 theme & palette
│   └── permission_database.dart       # Permission definitions
└── widgets/
    ├── app_card.dart
    ├── filter_sort_bar.dart
    ├── permission_history_chart.dart
    ├── permission_item.dart
    ├── permission_verification_dialog.dart
    ├── risk_badge.dart
    └── stat_card.dart
```

### Key design decisions

| Pattern | Detail |
|---|---|
| State management | `flutter_riverpod` — `AsyncNotifierProvider` for app list, `StateProvider` for filters |
| Caching | Hive with 5 boxes; fingerprint check avoids redundant native calls |
| Background work | `compute()` isolate for permission enrichment off the main thread |
| Native bridge | `MethodChannel('permission_scanner')` with `getInstalledApps` / `getAppsFingerprint` |
| Risk scoring | 100 − (10 × dangerous permissions), clamped 0–100; justification can reduce risk one level |

## Getting started

### Prerequisites

- Flutter SDK ≥ 3.11.1
- Android SDK (minSdk 21 / targetSdk 35)
- An Android device or emulator

### Build & run

```bash
git clone https://github.com/AHS-Mobile-Labs/Permission_Scanner.git
cd Permission_Scanner
flutter pub get
flutter run
```

### Generate launcher icon

```bash
dart run flutter_launcher_icons
```

## Permissions

| Permission | Why |
|---|---|
| `QUERY_ALL_PACKAGES` | Read the permission manifest of every installed app |
| `POST_NOTIFICATIONS` | Send local alerts for high-risk apps (requested at runtime, non-blocking) |

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.4.1 | State management |
| `hive` / `hive_flutter` | ^2.2.3 / ^1.1.0 | Local key-value cache |
| `fl_chart` | ^0.65.0 | Data visualization |
| `flutter_local_notifications` | ^17.1.0 | Local push notifications |
| `permission_handler` | ^11.0.0 | Runtime permission requests |
| `intl` | ^0.19.0 | Date formatting |

## Star History

<a href="https://www.star-history.com/?repos=AHS-Mobile-Labs%2FPermission_Scanner&type=date&legend=bottom-right">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=AHS-Mobile-Labs/Permission_Scanner&type=date&theme=dark&legend=bottom-right" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=AHS-Mobile-Labs/Permission_Scanner&type=date&legend=bottom-right" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=AHS-Mobile-Labs/Permission_Scanner&type=date&legend=bottom-right" />
 </picture>
</a>

## Author

[Ameer Hamza Saifi](https://github.com/ameerhamzasaifi)

© 2026 AHS Mobile Labs
