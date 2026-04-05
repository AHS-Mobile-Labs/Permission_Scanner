# Permission Scanner

Android app that scans installed apps and shows what permissions they use. Helps you spot apps requesting sensitive access like camera, location, storage, or contacts.

## Features

- Scans all installed apps and their permissions
- Shows app icons, risk level, and privacy score
- Filters by user apps, system apps, or unknown sources
- Sort by name or risk level
- Dev permission toggle to show/hide technical permissions
- App verification with capability tagging
- Risk dashboard with stats and distribution chart
- Notifications for high-risk apps

## Setup

Requires Flutter SDK. Built for Android.

```
flutter pub get
flutter run
```

## Permissions

The app needs `QUERY_ALL_PACKAGES` to read other apps' permissions and `POST_NOTIFICATIONS` for risk alerts.

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
