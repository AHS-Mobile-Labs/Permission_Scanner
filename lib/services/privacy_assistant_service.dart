import 'package:permission_scanner/models/app_info.dart';
import 'package:permission_scanner/utils/permission_database.dart';

class PrivacyAssistantService {
  static String answerQuestion(AppInfo app, String question) {
    final lower = question.toLowerCase();
    if (lower.contains('microphone') || lower.contains('record audio')) {
      return _explainPermission(app, 'android.permission.RECORD_AUDIO');
    }
    if (lower.contains('camera')) {
      return _explainPermission(app, 'android.permission.CAMERA');
    }
    if (lower.contains('location') || lower.contains('nearby')) {
      return _explainPermission(app, 'android.permission.ACCESS_FINE_LOCATION');
    }
    if (lower.contains('contacts')) {
      return _explainPermission(app, 'android.permission.READ_CONTACTS');
    }
    if (lower.contains('sms') || lower.contains('message')) {
      return _explainPermission(app, 'android.permission.READ_SMS');
    }
    if (lower.contains('tracker') || lower.contains('analytics')) {
      if (app.trackers.isEmpty) {
        return 'I did not match a known tracker SDK in ${app.appName}. That does not guarantee zero tracking, but the lightweight APK scan found no listed SDK signature.';
      }
      final names = app.trackers.map((tracker) => tracker.name).join(', ');
      return '${app.appName} contains ${app.trackers.length} tracker SDKs: $names. These usually support analytics, ads, crash reporting, attribution, or push messaging.';
    }
    return buildPlainLanguageSummary(app);
  }

  static List<String> recommendations(AppInfo app) {
    final items = <String>[];
    if (app.dangerousPermissionCount > 0) {
      items.add('Review and disable permissions you do not actively use.');
    }
    if (app.requestsOverlayPermission) {
      items.add(
        'Disable display-over-apps unless this app truly needs floating controls.',
      );
    }
    if (app.declaresAccessibilityService) {
      items.add(
        'Keep accessibility access off unless you intentionally enabled it.',
      );
    }
    if (app.runsAtBoot ||
        app.usesForegroundService ||
        app.requestsBatteryOptimizationBypass) {
      items.add(
        'Restrict background activity if the app does not need live updates.',
      );
    }
    if (app.trackers.length >= 3) {
      items.add(
        'Consider a privacy-focused alternative with fewer analytics or ad SDKs.',
      );
    }
    if (app.installSource == 'Unknown' && app.riskLevel != RiskLevel.safe) {
      items.add(
        'Remove or reinstall from a trusted source if you do not recognize it.',
      );
    }
    if (app.malwareIndicators.isNotEmpty) {
      items.add(
        'Treat this as suspicious and verify the developer before keeping it installed.',
      );
    }
    if (items.isEmpty) {
      items.add(
        'No urgent action found. Keep the app updated and review permissions occasionally.',
      );
    }
    return items;
  }

  static String buildPlainLanguageSummary(AppInfo app) {
    final buffer = StringBuffer()
      ..writeln(
        '${app.appName} is rated ${app.riskLevel.label} with a privacy score of ${app.privacyScore}/100.',
      )
      ..writeln(
        'It requests ${app.permissions.length} permissions, including ${app.dangerousPermissionCount} sensitive permissions, and contains ${app.trackers.length} tracker SDKs.',
      );

    if (app.riskSignals.isNotEmpty) {
      buffer.writeln('Main concerns:');
      for (final signal in app.riskSignals.take(4)) {
        buffer.writeln('- ${signal.title}: ${signal.description}');
      }
    }

    buffer.writeln('Recommended actions:');
    for (final item in recommendations(app).take(4)) {
      buffer.writeln('- $item');
    }
    return buffer.toString().trim();
  }

  static String buildDeviceShareSummary(List<AppInfo> apps) {
    final topRisk = List<AppInfo>.from(apps)
      ..sort((a, b) {
        final riskCompare = a.riskLevel.sortRank.compareTo(
          b.riskLevel.sortRank,
        );
        if (riskCompare != 0) return riskCompare;
        return a.privacyScore.compareTo(b.privacyScore);
      });
    final deviceScore = apps.isEmpty
        ? 100
        : (apps.fold<int>(0, (sum, app) => sum + app.privacyScore) /
                  apps.length)
              .round();
    final trackerCount = apps.fold<int>(
      0,
      (sum, app) => sum + app.trackers.length,
    );

    final buffer = StringBuffer()
      ..writeln('Permission Scanner privacy summary')
      ..writeln('Device score: $deviceScore/100')
      ..writeln('Apps scanned: ${apps.length}')
      ..writeln('Trackers found: $trackerCount')
      ..writeln('')
      ..writeln('Highest-risk apps:');
    for (final app in topRisk.take(5)) {
      buffer.writeln(
        '- ${app.appName}: ${app.riskLevel.label}, score ${app.privacyScore}, ${app.trackers.length} trackers',
      );
    }
    return buffer.toString().trim();
  }

  static String _explainPermission(AppInfo app, String permission) {
    final info = permissionDatabase[permission];
    final hasPermission =
        app.permissions.contains(permission) ||
        (permission == 'android.permission.ACCESS_FINE_LOCATION' &&
            app.permissions.contains(
              'android.permission.ACCESS_COARSE_LOCATION',
            ));

    if (!hasPermission) {
      return '${app.appName} does not currently request ${info?.displayName ?? permission}.';
    }

    final name = info?.displayName ?? permission.split('.').last;
    final description = info?.description ?? 'access sensitive device data';
    final risk = app.hasInternetAccess
        ? 'Because the app can also access the internet, this data could potentially leave the device if the app chooses to send it.'
        : 'The app does not request internet access, which lowers exfiltration risk.';

    return '$name lets ${app.appName} $description. $risk Only keep this permission enabled if it matches a feature you actually use.';
  }
}
