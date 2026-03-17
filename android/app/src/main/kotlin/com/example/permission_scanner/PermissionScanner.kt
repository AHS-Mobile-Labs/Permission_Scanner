package com.example.permission_scanner

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import org.json.JSONArray
import org.json.JSONObject

class PermissionScanner(private val context: Context) {
    private val packageManager = context.packageManager

    fun getInstalledAppsWithPermissions(): String {
        try {
            val apps = mutableListOf<JSONObject>()
            val packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)

            for (app in packages) {
                if (!isSystemApp(app)) {
                    val appJson = JSONObject()
                    appJson.put("packageName", app.packageName)
                    appJson.put("appName", getAppName(app))
                    
                    val permissions = getAppPermissions(app.packageName)
                    val permissionsArray = JSONArray()
                    for (permission in permissions) {
                        permissionsArray.put(permission)
                    }
                    appJson.put("permissions", permissionsArray)
                    
                    apps.add(appJson)
                }
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
}
