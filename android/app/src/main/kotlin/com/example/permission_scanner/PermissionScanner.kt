package com.example.permission_scanner

import android.content.Context
import android.content.pm.ApplicationInfo
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

class PermissionScanner(private val context: Context) {
    private val packageManager = context.packageManager

    // Maps known installer package names to human-readable source labels
    private val trustedInstallers = mapOf(
        "com.android.vending"               to "Play Store",
        "com.google.android.feedback"       to "Play Store",
        "com.sec.android.app.samsungapps"   to "Galaxy Store",
        "com.amazon.venezia"                to "Amazon Appstore",
        "com.huawei.appmarket"              to "Huawei AppGallery",
        "com.xiaomi.market"                 to "Mi Store",
        "com.oppo.market"                   to "OPPO Store",
        "com.vivo.appstore"                 to "Vivo Store"
    )

    fun getInstalledAppsWithPermissions(): String {
        try {
            val apps = mutableListOf<JSONObject>()
            val packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)

            for (app in packages) {
                val appJson = JSONObject()
                appJson.put("packageName", app.packageName)
                appJson.put("appName", getAppName(app))
                appJson.put("isSystemApp", isSystemApp(app))
                appJson.put("installSource", getInstallSource(app))
                appJson.put("iconPath", getAppIcon(app))

                val permissions = getAppPermissions(app.packageName)
                val permissionsArray = JSONArray()
                for (permission in permissions) {
                    permissionsArray.put(permission)
                }
                appJson.put("permissions", permissionsArray)

                apps.add(appJson)
            }

            val result = JSONObject()
            val appsArray = JSONArray()
            for (app in apps) {
                appsArray.put(app)
            }
            result.put("apps", appsArray)
            
            return result.toString()
        } catch (e: Exception) {
            return ""
        }
    }

    private fun getInstallSource(app: ApplicationInfo): String {
        // Preinstalled system apps have a well-known origin
        if (isSystemApp(app)) return "System"

        return try {
            val installerPackage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                packageManager.getInstallSourceInfo(app.packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(app.packageName)
            }

            if (installerPackage.isNullOrEmpty()) {
                "Unknown"
            } else {
                trustedInstallers[installerPackage] ?: "Unknown"
            }
        } catch (e: Exception) {
            "Unknown"
        }
    }

    private fun getAppName(app: ApplicationInfo): String {
        return try {
            packageManager.getApplicationLabel(app).toString()
        } catch (e: Exception) {
            app.packageName
        }
    }

    private fun getAppPermissions(packageName: String): List<String> {
        val permissions = mutableListOf<String>()
        try {
            val packageInfo = packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_PERMISSIONS
            )
            packageInfo.requestedPermissions?.forEach {
                permissions.add(it)
            }
        } catch (e: PackageManager.NameNotFoundException) {
            // Package not found
        }
        return permissions
    }

    private fun isSystemApp(app: ApplicationInfo): Boolean {
        return (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0
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
            // Scale to 192x192 for sharp display on high-DPI screens
            val scaled = Bitmap.createScaledBitmap(bitmap, 192, 192, true)
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.PNG, 100, stream)
            val byteArray = stream.toByteArray()
            Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            ""
        }
    }
}
