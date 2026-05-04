package com.ahsmobilelabs.permissionScanner.opensoucre

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.security.MessageDigest

class PermissionScanner(private val context: Context) {
    private val packageManager = context.packageManager

    // Allowlist: only these installer package names are considered trusted app stores.
    // Any installer NOT in this list (including browsers, file managers, etc.) → "Unknown Source".
    private val trustedInstallers = mapOf(
        "com.android.vending"               to "Play Store",
        "com.google.android.feedback"       to "Play Store",
        "com.sec.android.app.samsungapps"   to "Galaxy Store",
        "com.samsung.android.app.samsungapps" to "Galaxy Store",
        "com.amazon.venezia"                to "Amazon Appstore",
        "com.huawei.appmarket"              to "Huawei AppGallery",
        "com.xiaomi.market"                 to "Mi Store",
        "com.xiaomi.mipicks"                to "Mi Store",
        "com.oppo.market"                   to "OPPO Store",
        "com.heytap.market"                 to "OPPO Store",
        "com.vivo.appstore"                 to "Vivo Store",
        "com.bbk.appstore"                  to "Vivo Store",
        "com.oneplus.store"                 to "OnePlus Store",
        "com.lenovo.leos.appstore"          to "Lenovo Store",
        "com.realme.store"                  to "Realme Store"
    )

    /**
     * Batch-fetches all installed packages with their permissions in a single
     * PackageManager call, avoiding per-app getPackageInfo round-trips.
     */
    fun getInstalledAppsWithPermissions(): String {
        try {
            val apps = mutableListOf<JSONObject>()

            // Single batch query: GET_PERMISSIONS includes requestedPermissions per package
            val packages: List<PackageInfo> =
                packageManager.getInstalledPackages(PackageManager.GET_PERMISSIONS)

            for (pkg in packages) {
                val appInfo = pkg.applicationInfo ?: continue

                val appJson = JSONObject()
                appJson.put("packageName", pkg.packageName)
                appJson.put("appName", getAppName(appInfo))
                appJson.put("isSystemApp", isSystemApp(appInfo))

                val installerRaw = getRawInstallerPackage(pkg.packageName)
                appJson.put("installerPackageName", installerRaw ?: "")
                appJson.put("installSource", classifyInstallSource(appInfo, installerRaw))
                appJson.put("iconPath", getAppIcon(appInfo))

                val permissionsArray = JSONArray()
                pkg.requestedPermissions?.forEach { permissionsArray.put(it) }
                appJson.put("permissions", permissionsArray)

                apps.add(appJson)
            }

            val result = JSONObject()
            val appsArray = JSONArray()
            for (app in apps) { appsArray.put(app) }
            result.put("apps", appsArray)

            return result.toString()
        } catch (e: Exception) {
            return ""
        }
    }

    /**
     * Returns a lightweight fingerprint (SHA-256 hash) of the currently installed
     * package set plus their lastUpdateTime. The Dart side compares this to a
     * cached value to decide whether a full re-scan is necessary.
     */
    fun getAppsFingerprint(): String {
        return try {
            val packages = packageManager.getInstalledPackages(0)
            val sb = StringBuilder()
            for (pkg in packages.sortedBy { it.packageName }) {
                sb.append(pkg.packageName)
                sb.append(':')
                sb.append(pkg.lastUpdateTime)
                sb.append(';')
            }
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(sb.toString().toByteArray())
            hash.joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            ""
        }
    }

    // ── Classification ───────────────────────────────────────────────────

    /**
     * Determines the human-readable install source label.
     *
     * Priority:
     * 1. System flag check (FLAG_SYSTEM | FLAG_UPDATED_SYSTEM_APP) → "System"
     * 2. Installer in trustedInstallers allowlist → store label (e.g. "Play Store")
     * 3. Everything else (null, empty, browser, file-manager, unknown pkg) → "Unknown"
     */
    private fun classifyInstallSource(appInfo: ApplicationInfo, installerPackage: String?): String {
        // System apps always override installer-based classification
        if (isSystemApp(appInfo)) return "System"

        if (installerPackage.isNullOrEmpty()) return "Unknown"

        return trustedInstallers[installerPackage] ?: "Unknown"
    }

    /**
     * Reads the raw installer package name using the appropriate API level.
     * Returns null when the information is unavailable or restricted.
     */
    private fun getRawInstallerPackage(packageName: String): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val sourceInfo = packageManager.getInstallSourceInfo(packageName)
                // Prefer installingPackageName; fall back to initiatingPackageName
                sourceInfo.installingPackageName
                    ?: sourceInfo.initiatingPackageName
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(packageName)
            }
        } catch (_: Exception) {
            null
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private fun getAppName(app: ApplicationInfo): String {
        return try {
            packageManager.getApplicationLabel(app).toString()
        } catch (e: Exception) {
            app.packageName
        }
    }

    /**
     * Checks both FLAG_SYSTEM and FLAG_UPDATED_SYSTEM_APP to correctly identify
     * system apps even after OEM updates (e.g. Samsung Clock updated via Galaxy Store).
     */
    private fun isSystemApp(app: ApplicationInfo): Boolean {
        return (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
               (app.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
    }

    /**
     * Clears the app icon cache directory.
     * Useful when user requests a refresh or for cleanup.
     */
    fun clearIconCache() {
        try {
            val cacheDir = context.cacheDir
            val iconCacheDir = File(cacheDir, "app_icons")
            if (iconCacheDir.exists()) {
                iconCacheDir.deleteRecursively()
            }
        } catch (e: Exception) {
            // Silently ignore cache clear errors
        }
    }

    private fun getAppIcon(app: ApplicationInfo): String {
        return try {
            val drawable: Drawable = packageManager.getApplicationIcon(app)
            val bitmap: Bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
                drawable.bitmap
            } else {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 48
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 48
                val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }
            val scaled = Bitmap.createScaledBitmap(bitmap, 192, 192, true)
            
            // NEW: Save to file instead of base64
            // This eliminates expensive base64 decoding on every widget rebuild
            val cacheDir = context.cacheDir
            val iconCacheDir = File(cacheDir, "app_icons")
            if (!iconCacheDir.exists()) {
                iconCacheDir.mkdirs()
            }
            
            val iconFile = File(iconCacheDir, "${app.packageName}.png")
            
            // Only write if file doesn't already exist (avoid redundant I/O)
            if (!iconFile.exists()) {
                val stream = java.io.FileOutputStream(iconFile)
                scaled.compress(Bitmap.CompressFormat.PNG, 85, stream)
                stream.close()
            }
            
            // Return file path instead of base64 string
            iconFile.absolutePath
        } catch (e: Exception) {
            ""
        }
    }
}
