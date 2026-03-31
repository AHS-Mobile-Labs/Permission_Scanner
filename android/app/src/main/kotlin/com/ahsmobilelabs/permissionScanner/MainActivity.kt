package com.ahsmobilelabs.permissionScanner

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "permission_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    try {
                        val scanner = PermissionScanner(this)
                        val apps = scanner.getInstalledAppsWithPermissions()
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("PERMISSION_ERROR", e.message, null)
                    }
                }
                "getAppsFingerprint" -> {
                    try {
                        val scanner = PermissionScanner(this)
                        val fingerprint = scanner.getAppsFingerprint()
                        result.success(fingerprint)
                    } catch (e: Exception) {
                        result.error("FINGERPRINT_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
