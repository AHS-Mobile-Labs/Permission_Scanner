package com.ahsmobilelabs.permissionScanner.opensoucre

import android.content.ContentValues
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.ComponentInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.graphics.pdf.PdfDocument
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.security.MessageDigest
import java.util.Locale
import java.util.zip.ZipFile

class PermissionScanner(private val context: Context) {
    private val packageManager = context.packageManager

    @Suppress("DEPRECATION")
    private val signingQueryFlags =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            PackageManager.GET_SIGNATURES
        }

    private val packageQueryFlags =
        PackageManager.GET_PERMISSIONS or
            PackageManager.GET_SERVICES or
            PackageManager.GET_RECEIVERS or
            PackageManager.GET_ACTIVITIES or
            PackageManager.GET_PROVIDERS or
            signingQueryFlags or
            PackageManager.GET_META_DATA

    private val trustedInstallers = mapOf(
        "com.android.vending" to "Play Store",
        "com.google.android.feedback" to "Play Store",
        "com.sec.android.app.samsungapps" to "Galaxy Store",
        "com.samsung.android.app.samsungapps" to "Galaxy Store",
        "com.amazon.venezia" to "Amazon Appstore",
        "com.huawei.appmarket" to "Huawei AppGallery",
        "com.xiaomi.market" to "Mi Store",
        "com.xiaomi.mipicks" to "Mi Store",
        "com.oppo.market" to "OPPO Store",
        "com.heytap.market" to "OPPO Store",
        "com.vivo.appstore" to "Vivo Store",
        "com.bbk.appstore" to "Vivo Store",
        "com.oneplus.store" to "OnePlus Store",
        "com.lenovo.leos.appstore" to "Lenovo Store",
        "com.realme.store" to "Realme Store"
    )

    private val advertisingIdentifierConsumerIds = setOf(
        "admob",
        "facebook_sdk",
        "facebook_audience_network",
        "appsflyer",
        "adjust",
        "branch",
        "kochava",
        "airbridge",
        "singular",
        "tenjin",
        "unity_ads",
        "applovin",
        "ironsource",
        "inmobi",
        "pangle",
        "vungle",
        "chartboost",
        "tapjoy",
        "mintegral",
        "fyber"
    )

    private val trackerSignatures = listOf(
        TrackerSignature(
            "firebase_analytics",
            "Firebase Analytics",
            "Analytics",
            "Measures app usage, audiences, campaigns, and engagement.",
            5,
            listOf(
                "com/google/firebase/analytics",
                "com/google/android/gms/measurement",
                "firebase-analytics",
                "google_app_id",
                "firebase_analytics_collection_enabled",
                "app_measurement"
            )
        ),
        TrackerSignature(
            "facebook_sdk",
            "Facebook SDK",
            "Social/Ads",
            "Supports Facebook login, app events, attribution, and ad measurement.",
            7,
            listOf(
                "com/facebook",
                "com.facebook.sdk.ApplicationId",
                "facebook_app_id",
                "facebook_client_token",
                "facebook_auto_log_app_events_enabled"
            )
        ),
        TrackerSignature(
            "appsflyer",
            "AppsFlyer",
            "Attribution",
            "Tracks installs, campaigns, referrals, and marketing attribution.",
            8,
            listOf("com/appsflyer", "appsflyer")
        ),
        TrackerSignature(
            "admob",
            "Google AdMob",
            "Advertising",
            "Displays ads and measures ad interactions.",
            8,
            listOf(
                "com/google/android/gms/ads",
                "com/google/ads",
                "play-services-ads",
                "com.google.android.gms.ads.APPLICATION_ID",
                "MobileAdsInitProvider",
                "AdActivity"
            )
        ),
        TrackerSignature(
            "onesignal",
            "OneSignal",
            "Messaging",
            "Push messaging and audience segmentation.",
            5,
            listOf("com/onesignal", "onesignal")
        ),
        TrackerSignature(
            "xiaomi_analytics",
            "Xiaomi/MiUI Analytics",
            "Analytics",
            "Xiaomi analytics and device telemetry integrations.",
            7,
            listOf("com/xiaomi/analytics", "com/xiaomi/onetrack", "miui/analytics")
        ),
        TrackerSignature(
            "adjust",
            "Adjust",
            "Attribution",
            "Marketing attribution, campaign measurement, and fraud checks.",
            7,
            listOf("com/adjust/sdk", "adjust_config")
        ),
        TrackerSignature(
            "branch",
            "Branch",
            "Attribution",
            "Deep linking, referrals, and install attribution.",
            6,
            listOf("io/branch/referral", "branch_key")
        ),
        TrackerSignature(
            "crashlytics",
            "Firebase Crashlytics",
            "Crash reporting",
            "Collects crash traces and diagnostics to debug failures.",
            4,
            listOf("com/google/firebase/crashlytics", "crashlytics")
        ),
        TrackerSignature(
            "mixpanel",
            "Mixpanel",
            "Analytics",
            "Product analytics and behavioral event tracking.",
            7,
            listOf("com/mixpanel/android", "mixpanel")
        ),
        TrackerSignature(
            "flurry",
            "Flurry",
            "Analytics",
            "Mobile analytics, sessions, and audience metrics.",
            7,
            listOf("com/flurry", "flurryagent")
        ),
        TrackerSignature(
            "unity_ads",
            "Unity Ads",
            "Advertising",
            "Game advertising and monetization SDK.",
            8,
            listOf("com/unity3d/ads", "unityads")
        ),
        TrackerSignature(
            "applovin",
            "AppLovin",
            "Advertising",
            "Ad mediation, monetization, and attribution.",
            8,
            listOf("com/applovin", "applovin")
        ),
        TrackerSignature(
            "ironsource",
            "ironSource",
            "Advertising",
            "Ad mediation and monetization SDK.",
            8,
            listOf("com/ironsource", "ironsource")
        ),
        TrackerSignature(
            "inmobi",
            "InMobi",
            "Advertising",
            "Mobile advertising and monetization SDK.",
            8,
            listOf("com/inmobi", "inmobi")
        ),
        TrackerSignature(
            "pangle",
            "Pangle/ByteDance Ads",
            "Advertising",
            "ByteDance advertising and monetization SDK.",
            8,
            listOf("com/bytedance/sdk/openadsdk", "pangle")
        ),
        TrackerSignature(
            "kochava",
            "Kochava",
            "Attribution",
            "Install attribution and campaign analytics.",
            7,
            listOf("com/kochava", "kochava")
        ),
        TrackerSignature(
            "google_analytics",
            "Google Analytics",
            "Analytics",
            "Measures sessions, screens, events, and campaign performance.",
            6,
            listOf("com/google/android/gms/analytics", "google-analytics-services", "ga_trackingid")
        ),
        TrackerSignature(
            "google_tag_manager",
            "Google Tag Manager",
            "Analytics",
            "Loads analytics and marketing tags through a remote container.",
            6,
            listOf("com/google/android/gms/tagmanager", "googletagmanager", "gtm_container")
        ),
        TrackerSignature(
            "firebase_messaging",
            "Firebase Cloud Messaging",
            "Messaging",
            "Push notification delivery and topic messaging.",
            3,
            listOf("com/google/firebase/messaging", "firebase-messaging")
        ),
        TrackerSignature(
            "facebook_audience_network",
            "Meta Audience Network",
            "Advertising",
            "Meta ad monetization and audience measurement.",
            8,
            listOf("com/facebook/ads", "audience_network", "fan_placement")
        ),
        TrackerSignature(
            "sentry",
            "Sentry",
            "Crash reporting",
            "Crash reporting, performance monitoring, and release diagnostics.",
            4,
            listOf("io/sentry", "sentry.properties", "sentry_dsn")
        ),
        TrackerSignature(
            "bugsnag",
            "Bugsnag",
            "Crash reporting",
            "Crash reporting, stability monitoring, and diagnostics.",
            4,
            listOf("com/bugsnag", "bugsnag", "bugsnag_api_key")
        ),
        TrackerSignature(
            "instabug",
            "Instabug",
            "Diagnostics",
            "Bug reporting, crash reporting, surveys, and session diagnostics.",
            5,
            listOf("com/instabug", "instabug")
        ),
        TrackerSignature(
            "datadog",
            "Datadog RUM",
            "Analytics",
            "Real user monitoring, logs, traces, and performance telemetry.",
            6,
            listOf("com/datadog", "datadog", "dd-sdk-android")
        ),
        TrackerSignature(
            "amplitude",
            "Amplitude",
            "Analytics",
            "Product analytics, funnels, cohorts, and behavioral event tracking.",
            7,
            listOf("com/amplitude", "amplitude-android", "amplitude_api_key")
        ),
        TrackerSignature(
            "segment",
            "Segment",
            "Analytics",
            "Customer data routing to analytics and marketing destinations.",
            7,
            listOf("com/segment/analytics", "segment_write_key", "segment.io")
        ),
        TrackerSignature(
            "clevertap",
            "CleverTap",
            "Engagement",
            "Analytics, push messaging, segmentation, and lifecycle campaigns.",
            7,
            listOf("com/clevertap", "clevertap")
        ),
        TrackerSignature(
            "moengage",
            "MoEngage",
            "Engagement",
            "Customer engagement, push campaigns, analytics, and segmentation.",
            7,
            listOf("com/moengage", "moengage")
        ),
        TrackerSignature(
            "airbridge",
            "Airbridge",
            "Attribution",
            "Marketing attribution, deep links, and campaign measurement.",
            7,
            listOf("co/ab180/airbridge", "airbridge")
        ),
        TrackerSignature(
            "singular",
            "Singular",
            "Attribution",
            "Mobile attribution, campaign analytics, and fraud measurement.",
            7,
            listOf("com/singular/sdk", "singular_sdk")
        ),
        TrackerSignature(
            "tenjin",
            "Tenjin",
            "Attribution",
            "Install attribution and campaign analytics for mobile apps.",
            7,
            listOf("com/tenjin/android", "tenjin")
        ),
        TrackerSignature(
            "yandex_appmetrica",
            "Yandex AppMetrica",
            "Analytics",
            "App analytics, attribution, crash reporting, and audience metrics.",
            7,
            listOf("com/yandex/metrica", "appmetrica")
        ),
        TrackerSignature(
            "countly",
            "Countly",
            "Analytics",
            "Product analytics, crash reporting, and remote configuration.",
            5,
            listOf("ly/count/android", "countly")
        ),
        TrackerSignature(
            "matomo",
            "Matomo",
            "Analytics",
            "Privacy-focused analytics for sessions, events, and campaigns.",
            4,
            listOf("org/matomo/sdk", "matomo")
        ),
        TrackerSignature(
            "vungle",
            "Liftoff/Vungle",
            "Advertising",
            "Video advertising, monetization, and campaign measurement.",
            8,
            listOf("com/vungle", "vungle")
        ),
        TrackerSignature(
            "chartboost",
            "Chartboost",
            "Advertising",
            "Game advertising, mediation, and monetization.",
            8,
            listOf("com/chartboost", "chartboost")
        ),
        TrackerSignature(
            "tapjoy",
            "Tapjoy",
            "Advertising",
            "Offerwall advertising, rewards, monetization, and analytics.",
            8,
            listOf("com/tapjoy", "tapjoy")
        ),
        TrackerSignature(
            "mintegral",
            "Mintegral",
            "Advertising",
            "Mobile ad mediation, monetization, and campaign measurement.",
            8,
            listOf("com/mbridge/msdk", "mintegral", "mbridge")
        ),
        TrackerSignature(
            "fyber",
            "Digital Turbine/Fyber",
            "Advertising",
            "Ad mediation, monetization, and campaign measurement.",
            8,
            listOf("com/fyber", "com/inneractive", "digitalturbine")
        )
    )

    private val staticSignalSignatures = listOf(
        StaticSignalSignature(
            "dynamic_code_loading",
            "Dynamic code loading",
            "The APK references APIs that can load code at runtime. This may be legitimate for plugin systems, but it can also hide behavior from static review.",
            "high",
            14,
            "DexClassLoader or related class loader",
            listOf(
                "dalvik/system/dexclassloader",
                "dalvik/system/pathclassloader",
                "dalvik/system/inmemorydexclassloader",
                "dexclassloader",
                "loadclass"
            )
        ),
        StaticSignalSignature(
            "runtime_command_execution",
            "Runtime command execution",
            "The APK references command execution APIs or shell paths. Apps that run system commands deserve careful review.",
            "high",
            12,
            "Runtime.exec, ProcessBuilder, or shell command path",
            listOf(
                "java/lang/runtime",
                "runtime.exec",
                "processbuilder",
                "/system/bin/sh",
                "/system/xbin/su",
                "/system/bin/su"
            )
        ),
        StaticSignalSignature(
            "reflection",
            "Reflection-heavy code",
            "The APK references reflection APIs that can hide which methods are called until runtime.",
            "medium",
            6,
            "Java reflection API",
            listOf(
                "java/lang/reflect",
                "class.forname",
                "class;->forname",
                "method.invoke",
                "getdeclaredmethod"
            )
        ),
        StaticSignalSignature(
            "native_code_loading",
            "Native code loading",
            "The APK references native library loading. Native code is common, but it is harder to explain from Android permissions alone.",
            "medium",
            5,
            "System.loadLibrary or dlopen",
            listOf(
                "system.loadlibrary",
                "system;->loadlibrary",
                "loadlibrary",
                "dlopen"
            )
        ),
        StaticSignalSignature(
            "accessibility_automation",
            "Accessibility automation APIs",
            "The APK references APIs that can inspect the screen or automate user actions when paired with accessibility access.",
            "critical",
            18,
            "AccessibilityService automation API",
            listOf(
                "android/accessibilityservice/accessibilityservice",
                "dispatchgesture",
                "performglobalaction",
                "accessibilitynodeinfo"
            )
        ),
        StaticSignalSignature(
            "screen_capture",
            "Screen capture APIs",
            "The APK references Android screen capture APIs. This can expose visible app content if the user grants capture access.",
            "high",
            12,
            "MediaProjection screen capture API",
            listOf(
                "mediaprojectionmanager",
                "mediaprojection",
                "createscreencaptureintent",
                "virtualdisplay"
            )
        ),
        StaticSignalSignature(
            "clipboard_access",
            "Clipboard access APIs",
            "The APK references clipboard APIs, which may expose copied codes, addresses, or other sensitive text.",
            "medium",
            6,
            "ClipboardManager API",
            listOf(
                "clipboardmanager",
                "getprimaryclip",
                "setprimaryclip"
            )
        ),
        StaticSignalSignature(
            "device_identifier_collection",
            "Device identifier collection",
            "The APK references APIs commonly used to collect persistent device or subscriber identifiers.",
            "high",
            10,
            "Device or subscriber identifier API",
            listOf(
                "getdeviceid",
                "getimei",
                "getsubscriberid",
                "android_id",
                "settings\$secure"
            )
        ),
        StaticSignalSignature(
            "package_installation",
            "Package installation APIs",
            "The APK references installer APIs that can request or manage app installation flows.",
            "high",
            10,
            "PackageInstaller or install intent",
            listOf(
                "packageinstaller",
                "request_install_packages",
                "action_install_package"
            )
        ),
        StaticSignalSignature(
            "sms_interception",
            "SMS interception APIs",
            "The APK references SMS handling APIs that can read, send, receive, or suppress message broadcasts.",
            "critical",
            16,
            "SMS receiver or SMS manager API",
            listOf(
                "sms_received",
                "smsmanager",
                "abortbroadcast",
                "receivesms"
            )
        ),
        StaticSignalSignature(
            "notification_listener",
            "Notification listener APIs",
            "The APK references notification listener APIs that can read notifications when enabled by the user.",
            "high",
            10,
            "NotificationListenerService API",
            listOf(
                "notificationlistenerservice",
                "bind_notification_listener_service"
            )
        ),
        StaticSignalSignature(
            "vpn_service",
            "VPN service APIs",
            "The APK references VPN service APIs. VPN apps can observe network routing metadata when enabled.",
            "high",
            10,
            "VpnService API",
            listOf(
                "vpnservice",
                "bind_vpn_service"
            )
        )
    )

    fun getInstalledAppsWithPermissions(deepScan: Boolean = false): String {
        return try {
            val packages: List<PackageInfo> =
                packageManager.getInstalledPackages(packageQueryFlags)
            val appsArray = JSONArray()

            for (pkg in packages) {
                if (Thread.currentThread().isInterrupted) break
                val appInfo = pkg.applicationInfo ?: continue
                appsArray.put(buildAppJson(pkg, appInfo, isArchive = false, deepScan = deepScan))
            }

            JSONObject().put("apps", appsArray).toString()
        } catch (_: Exception) {
            ""
        }
    }

    fun scanApk(uriOrPath: String): String {
        return try {
            val apkFile = resolveApkFile(uriOrPath) ?: return ""
            val pkg = packageManager.getPackageArchiveInfo(apkFile.absolutePath, packageQueryFlags)
                ?: return ""
            val appInfo = pkg.applicationInfo ?: ApplicationInfo()
            appInfo.sourceDir = apkFile.absolutePath
            appInfo.publicSourceDir = apkFile.absolutePath

            val json = buildAppJson(pkg, appInfo, isArchive = true, deepScan = true)
            json.put("installSource", "APK File")
            json.put("apkSizeBytes", apkFile.length().coerceAtMost(Int.MAX_VALUE.toLong()).toInt())

            JSONObject().put("apps", JSONArray().put(json)).toString()
        } catch (_: Exception) {
            ""
        }
    }

    fun getAppsFingerprint(): String {
        return try {
            val packages = packageManager.getInstalledPackages(0)
            val sb = StringBuilder()
            for (pkg in packages.sortedBy { it.packageName }) {
                if (Thread.currentThread().isInterrupted) break
                sb.append(pkg.packageName)
                sb.append(':')
                sb.append(pkg.lastUpdateTime)
                sb.append(';')
            }
            val digest = MessageDigest.getInstance("SHA-256")
            val hash = digest.digest(sb.toString().toByteArray())
            hash.joinToString("") { "%02x".format(it) }
        } catch (_: Exception) {
            ""
        }
    }

    private fun emptyApkInspection(trackers: List<TrackerFinding> = emptyList()): ApkInspection {
        return ApkInspection(
            trackers = trackers,
            staticFindings = emptyList(),
            usesKnownPacker = false,
            hasNativeLibraries = false,
            apkSha256 = "",
            apkFileCount = 0,
            dexFileCount = 0,
            nativeLibraryCount = 0,
            assetFileCount = 0,
            nativeArchitectures = emptyList(),
            staticAnalysisLimitReached = false
        )
    }

    private fun inspectPackageMetadata(
        pkg: PackageInfo,
        appInfo: ApplicationInfo,
        permissions: Set<String>
    ): ApkInspection {
        val found = linkedMapOf<String, TrackerFinding>()
        matchTrackerText(pkg.packageName, found, pkg.packageName, "Package metadata", 58)
        appInfo.className?.let {
            matchTrackerText(it, found, it, "Application class", 72)
        }
        appInfo.processName?.let {
            matchTrackerText(it, found, it, "Application process", 58)
        }
        appInfo.metaData?.let {
            matchBundleText(it, found, "Application metadata")
        }
        permissions.forEach {
            matchTrackerText(it, found, it, "Requested permission", 60)
        }
        pkg.activities?.forEach {
            matchComponentText(it, found, "Activity")
        }
        pkg.services?.forEach {
            matchComponentText(it, found, "Service")
        }
        pkg.receivers?.forEach {
            matchComponentText(it, found, "Receiver")
        }
        pkg.providers?.forEach {
            matchComponentText(it, found, "Provider")
        }
        return emptyApkInspection(trackers = found.values.toList())
    }

    @Suppress("DEPRECATION")
    private fun signerSha256Digests(pkg: PackageInfo): List<String> {
        return try {
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val signingInfo = pkg.signingInfo ?: return emptyList()
                val signers = if (signingInfo.hasMultipleSigners()) {
                    signingInfo.apkContentsSigners
                } else {
                    signingInfo.signingCertificateHistory
                }
                signers?.toList() ?: emptyList()
            } else {
                pkg.signatures?.toList() ?: emptyList()
            }

            signatures
                .map { sha256Bytes(it.toByteArray()) }
                .filter { it.isNotEmpty() }
                .distinct()
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun sha256File(file: File): String {
        return try {
            val digest = MessageDigest.getInstance("SHA-256")
            val buffer = ByteArray(64 * 1024)
            file.inputStream().use { input ->
                while (!Thread.currentThread().isInterrupted) {
                    val read = input.read(buffer)
                    if (read <= 0) break
                    digest.update(buffer, 0, read)
                }
            }
            hexDigest(digest.digest())
        } catch (_: Exception) {
            ""
        }
    }

    private fun sha256Bytes(bytes: ByteArray): String {
        return try {
            hexDigest(MessageDigest.getInstance("SHA-256").digest(bytes))
        } catch (_: Exception) {
            ""
        }
    }

    private fun hexDigest(bytes: ByteArray): String =
        bytes.joinToString("") { "%02x".format(it) }

    fun exportPdfReport(reportJson: String): String {
        var document: PdfDocument? = null
        return try {
            val report = JSONObject(reportJson)
            document = PdfDocument()
            val pageInfo = PdfDocument.PageInfo.Builder(595, 842, 1).create()
            val page = document.startPage(pageInfo)
            val canvas = page.canvas
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)

            paint.color = android.graphics.Color.rgb(17, 24, 39)
            paint.textSize = 22f
            paint.typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            canvas.drawText("Permission Scanner Privacy Report", 40f, 56f, paint)

            paint.textSize = 11f
            paint.typeface = Typeface.DEFAULT
            paint.color = android.graphics.Color.rgb(75, 85, 99)
            val generatedAt = report.optString("generatedAt", "")
            canvas.drawText("Generated: $generatedAt", 40f, 78f, paint)

            var y = 118f
            val lines = buildPdfLines(report)
            for (line in lines.take(42)) {
                paint.textSize = if (line.startsWith("#")) 14f else 10.5f
                paint.typeface = if (line.startsWith("#")) {
                    Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                } else {
                    Typeface.DEFAULT
                }
                paint.color = if (line.startsWith("#")) {
                    android.graphics.Color.rgb(21, 128, 61)
                } else {
                    android.graphics.Color.rgb(31, 41, 55)
                }
                canvas.drawText(line.removePrefix("# "), 40f, y, paint)
                y += if (line.startsWith("#")) 22f else 16f
            }

            document.finishPage(page)
            val bytes = ByteArrayOutputStream().use { output ->
                document.writeTo(output)
                output.toByteArray()
            }
            saveToDownloads(
                fileName = "permission_scanner_report_${reportTimestamp()}.pdf",
                mimeType = "application/pdf",
                bytes = bytes
            )
        } catch (_: Exception) {
            ""
        } finally {
            document?.close()
        }
    }

    fun exportJsonReport(reportJson: String): String {
        return try {
            val formattedJson = try {
                JSONObject(reportJson).toString(2)
            } catch (_: Exception) {
                reportJson
            }
            saveToDownloads(
                fileName = "permission_scanner_report_${reportTimestamp()}.json",
                mimeType = "application/json",
                bytes = formattedJson.toByteArray(Charsets.UTF_8)
            )
        } catch (_: Exception) {
            ""
        }
    }

    fun clearIconCache() {
        try {
            val iconCacheDir = File(context.cacheDir, "app_icons")
            if (iconCacheDir.exists()) iconCacheDir.deleteRecursively()
        } catch (_: Exception) {
        }
    }

    private fun saveToDownloads(fileName: String, mimeType: String, bytes: ByteArray): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = context.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: return ""
            try {
                resolver.openOutputStream(uri)?.use { output ->
                    output.write(bytes)
                    output.flush()
                } ?: run {
                    resolver.delete(uri, null, null)
                    return ""
                }

                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                "${Environment.DIRECTORY_DOWNLOADS}/$fileName"
            } catch (_: Exception) {
                resolver.delete(uri, null, null)
                ""
            }
        } else {
            try {
                val downloadsDir =
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                if (!downloadsDir.exists() && !downloadsDir.mkdirs()) return ""
                val file = File(downloadsDir, fileName)
                FileOutputStream(file).use { output ->
                    output.write(bytes)
                    output.flush()
                }
                MediaScannerConnection.scanFile(
                    context,
                    arrayOf(file.absolutePath),
                    arrayOf(mimeType),
                    null
                )
                file.absolutePath
            } catch (_: Exception) {
                ""
            }
        }
    }

    private fun reportTimestamp(): String =
        SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())

    private fun buildAppJson(
        pkg: PackageInfo,
        appInfo: ApplicationInfo,
        isArchive: Boolean,
        deepScan: Boolean
    ): JSONObject {
        val permissions = pkg.requestedPermissions?.toSet() ?: emptySet()
        val isSystem = !isArchive && isSystemApp(appInfo)
        val appName = getAppName(appInfo, pkg.packageName)
        val installerRaw = if (isArchive) null else getRawInstallerPackage(pkg.packageName)
        val hasLauncher = !isArchive && packageManager.getLaunchIntentForPackage(pkg.packageName) != null
        val metadataInspection = inspectPackageMetadata(pkg, appInfo, permissions)
        // APK inspection is intentionally bounded and interruptible. Startup uses a
        // fast metadata pass; full tracker byte scanning only runs for explicit or
        // background deep refreshes.
        val inspection = if (deepScan) {
            inspectApk(
                appInfo,
                permissions,
                allowDexScan = !isSystem,
                includeFileHash = isArchive,
                seedTrackers = metadataInspection.trackers
            )
        } else {
            metadataInspection
        }
        val fakeSystemRisk = !isSystem &&
            classifyInstallSource(appInfo, installerRaw) == "Unknown" &&
            looksLikeSystemApp(appName, pkg.packageName)
        val hasSmsAccess = hasAny(
            permissions,
            "android.permission.READ_SMS",
            "android.permission.SEND_SMS",
            "android.permission.RECEIVE_SMS",
            "android.permission.RECEIVE_MMS",
            "android.permission.RECEIVE_WAP_PUSH"
        )
        val hasCallAccess = hasAny(
            permissions,
            "android.permission.READ_CALL_LOG",
            "android.permission.WRITE_CALL_LOG",
            "android.permission.READ_PHONE_STATE",
            "android.permission.READ_PHONE_NUMBERS",
            "android.permission.ANSWER_PHONE_CALLS",
            "android.permission.CALL_PHONE"
        )
        val hasContactsAccess = hasAny(
            permissions,
            "android.permission.READ_CONTACTS",
            "android.permission.WRITE_CONTACTS",
            "android.permission.GET_ACCOUNTS"
        )
        val hasInternetAccess = permissions.contains("android.permission.INTERNET")

        return JSONObject().apply {
            put("packageName", pkg.packageName)
            put("appName", appName)
            put("isSystemApp", isSystem)
            put("installerPackageName", installerRaw ?: "")
            put("installSource", if (isArchive) "APK File" else classifyInstallSource(appInfo, installerRaw))
            put("iconPath", if (isArchive) "" else getAppIcon(appInfo, pkg.lastUpdateTime))
            put("permissions", JSONArray().apply { permissions.forEach { put(it) } })
            put("trackers", JSONArray().apply { inspection.trackers.forEach { put(it.toJson()) } })
            put("staticFindings", JSONArray().apply { inspection.staticFindings.forEach { put(it.toJson()) } })
            put("signerSha256Digests", JSONArray().apply { signerSha256Digests(pkg).forEach { put(it) } })
            put("nativeArchitectures", JSONArray().apply { inspection.nativeArchitectures.forEach { put(it) } })
            put("serviceCount", pkg.services?.size ?: 0)
            put("receiverCount", pkg.receivers?.size ?: 0)
            put("activityCount", pkg.activities?.size ?: 0)
            put("providerCount", pkg.providers?.size ?: 0)
            put("targetSdkVersion", appInfo.targetSdkVersion)
            put("minSdkVersion", if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) appInfo.minSdkVersion else 0)
            put("compileSdkVersion", if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) appInfo.compileSdkVersion else 0)
            put("compileSdkCodename", if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) appInfo.compileSdkVersionCodename ?: "" else "")
            put("apkSizeBytes", File(appInfo.sourceDir ?: "").length().coerceAtMost(Int.MAX_VALUE.toLong()).toInt())
            put("apkFileCount", inspection.apkFileCount)
            put("dexFileCount", inspection.dexFileCount)
            put("nativeLibraryCount", inspection.nativeLibraryCount)
            put("assetFileCount", inspection.assetFileCount)
            put("apkSha256", inspection.apkSha256)
            put("firstInstallTime", if (isArchive) 0L else pkg.firstInstallTime)
            put("lastUpdateTime", if (isArchive) 0L else pkg.lastUpdateTime)
            put("hasLauncher", hasLauncher)
            put("declaresAccessibilityService", declaresAccessibilityService(pkg))
            put("declaresDeviceAdmin", declaresDeviceAdmin(pkg))
            put("requestsOverlayPermission", permissions.contains("android.permission.SYSTEM_ALERT_WINDOW"))
            put("runsAtBoot", hasAny(
                permissions,
                "android.permission.RECEIVE_BOOT_COMPLETED",
                "android.permission.QUICKBOOT_POWERON",
                "com.htc.permission.APP_DEFAULT"
            ))
            put("keepsDeviceAwake", permissions.contains("android.permission.WAKE_LOCK"))
            put("usesForegroundService", permissions.any { it.startsWith("android.permission.FOREGROUND_SERVICE") })
            put("usesExactAlarm", hasAny(
                permissions,
                "android.permission.SCHEDULE_EXACT_ALARM",
                "android.permission.USE_EXACT_ALARM"
            ))
            put(
                "requestsBatteryOptimizationBypass",
                permissions.contains("android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS")
            )
            put("hasSmsAccess", hasSmsAccess)
            put("hasCallAccess", hasCallAccess)
            put("hasContactsAccess", hasContactsAccess)
            put("hasInternetAccess", hasInternetAccess)
            put("contactsInternetCombo", hasContactsAccess && hasInternetAccess)
            put("smsCallInternetCombo", (hasSmsAccess || hasCallAccess) && hasInternetAccess)
            put("hiddenLauncher", !hasLauncher && !isSystem)
            put("fakeSystemRisk", fakeSystemRisk)
            put("isDebuggable", (appInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0)
            put("usesKnownPacker", inspection.usesKnownPacker)
            put("hasNativeLibraries", inspection.hasNativeLibraries)
            put("staticAnalysisLimitReached", inspection.staticAnalysisLimitReached)
        }
    }

    private fun resolveApkFile(uriOrPath: String): File? {
        return try {
            val uri = Uri.parse(uriOrPath)
            if (uri.scheme == "content") {
                val apkDir = File(context.cacheDir, "apk_scans")
                if (!apkDir.exists()) apkDir.mkdirs()
                val outFile = File(apkDir, "selected_${System.currentTimeMillis()}.apk")
                context.contentResolver.openInputStream(uri)?.use { input ->
                    FileOutputStream(outFile).use { output ->
                        copyLimited(input, output, 512L * 1024L * 1024L)
                    }
                }
                outFile
            } else if (uri.scheme == "file") {
                File(uri.path ?: return null)
            } else {
                File(uriOrPath)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun inspectApk(
        appInfo: ApplicationInfo,
        permissions: Set<String>,
        allowDexScan: Boolean,
        includeFileHash: Boolean,
        seedTrackers: List<TrackerFinding> = emptyList()
    ): ApkInspection {
        val found = linkedMapOf<String, TrackerFinding>()
        seedTrackers.forEach { found[it.id] = it }
        val staticFindings = linkedMapOf<String, StaticFinding>()
        var usesKnownPacker = false
        var hasNativeLibraries = false
        var apkSha256 = ""
        var apkFileCount = 0
        var dexFileCount = 0
        var nativeLibraryCount = 0
        var assetFileCount = 0
        var staticAnalysisLimitReached = false
        val nativeArchitectures = linkedSetOf<String>()
        val paths = mutableListOf<String>()
        appInfo.sourceDir?.let { paths.add(it) }
        appInfo.splitSourceDirs?.forEach { paths.add(it) }

        for (path in paths.distinct()) {
            if (Thread.currentThread().isInterrupted) break
            val file = File(path)
            if (!file.exists()) continue
            if (includeFileHash && apkSha256.isEmpty()) {
                apkSha256 = sha256File(file)
            }
            val signals = inspectZipForSignals(file, found, staticFindings, allowDexScan)
            usesKnownPacker = usesKnownPacker || signals.usesKnownPacker
            hasNativeLibraries = hasNativeLibraries || signals.hasNativeLibraries
            apkFileCount += signals.apkFileCount
            dexFileCount += signals.dexFileCount
            nativeLibraryCount += signals.nativeLibraryCount
            assetFileCount += signals.assetFileCount
            nativeArchitectures.addAll(signals.nativeArchitectures)
            staticAnalysisLimitReached = staticAnalysisLimitReached || signals.staticAnalysisLimitReached
        }

        val hasAdId = permissions.contains("com.google.android.gms.permission.AD_ID")
        val hasKnownAdIdConsumer = found.values.any { isAdvertisingIdentifierConsumer(it) }
        if (hasAdId && !hasKnownAdIdConsumer) {
            found["unknown_ad_id"] = TrackerFinding(
                "unknown_ad_id",
                "Unknown advertising SDK",
                "Advertising",
                "The app requests the Google advertising identifier, but the scanner did not match a known ad SDK.",
                7,
                "Permission com.google.android.gms.permission.AD_ID is requested.",
                60
            )
        }

        return ApkInspection(
            trackers = found.values.toList(),
            staticFindings = staticFindings.values.toList(),
            usesKnownPacker = usesKnownPacker,
            hasNativeLibraries = hasNativeLibraries,
            apkSha256 = apkSha256,
            apkFileCount = apkFileCount,
            dexFileCount = dexFileCount,
            nativeLibraryCount = nativeLibraryCount,
            assetFileCount = assetFileCount,
            nativeArchitectures = nativeArchitectures.toList().sorted(),
            staticAnalysisLimitReached = staticAnalysisLimitReached
        )
    }

    private fun inspectZipForSignals(
        file: File,
        found: MutableMap<String, TrackerFinding>,
        staticFindings: MutableMap<String, StaticFinding>,
        allowDexScan: Boolean
    ): ApkFileSignals {
        var usesKnownPacker = false
        var hasNativeLibraries = false
        var apkFileCount = 0
        var dexFileCount = 0
        var nativeLibraryCount = 0
        var assetFileCount = 0
        var staticAnalysisLimitReached = false
        val nativeArchitectures = linkedSetOf<String>()
        val packerPatterns = listOf("jiagu", "secneo", "bangcle", "ijiami", "libprotect", "libshell", "360jiagu")

        return try {
            ZipFile(file).use { zip ->
                val entries = zip.entries()
                var scannedBytes = 0
                var scannedEntries = 0
                val maxEntries = if (allowDexScan) 8_000 else 1_500
                val maxTotalBytes = if (allowDexScan) 8 * 1024 * 1024 else 0
                val maxEntryBytes = if (allowDexScan) 1024 * 1024 else 0

                while (
                    entries.hasMoreElements() &&
                    !Thread.currentThread().isInterrupted
                ) {
                    if (scannedEntries >= maxEntries) {
                        staticAnalysisLimitReached = true
                        break
                    }
                    val entry = entries.nextElement()
                    scannedEntries++
                    val entryName = entry.name.lowercase(Locale.US)
                    matchTrackerText(entryName, found, entry.name, "APK path", 78)
                    matchStaticText(entryName, staticFindings, entry.name)
                    if (!entry.isDirectory) apkFileCount++
                    if (entryName.startsWith("assets/")) assetFileCount++
                    if (entryName.endsWith(".dex")) dexFileCount++
                    if (entryName.startsWith("lib/") && entryName.endsWith(".so")) {
                        hasNativeLibraries = true
                        nativeLibraryCount++
                        entryName.split('/').getOrNull(1)?.let { abi ->
                            if (abi.isNotBlank()) nativeArchitectures.add(abi)
                        }
                    }
                    if (packerPatterns.any { pattern -> entryName.contains(pattern) }) {
                        usesKnownPacker = true
                    }

                    val shouldRead = allowDexScan &&
                        scannedBytes < maxTotalBytes &&
                        (entryName.endsWith(".dex") ||
                            entryName.endsWith(".xml") ||
                            entryName.endsWith(".json") ||
                            entryName.endsWith(".properties") ||
                            entryName.endsWith(".txt") ||
                            entryName.endsWith(".mf") ||
                            entryName.endsWith(".arsc") ||
                            entryName == "resources.arsc")
                    if (!shouldRead || entry.isDirectory) continue

                    val remainingBytes = maxTotalBytes - scannedBytes
                    val bytes = zip.getInputStream(entry).use {
                        readLimited(it, minOf(maxEntryBytes, remainingBytes))
                    }
                    scannedBytes += bytes.size
                    if (scannedBytes >= maxTotalBytes) {
                        staticAnalysisLimitReached = true
                    }
                    val text = searchableText(bytes)
                    matchTrackerText(text, found, entry.name, "File content", 92)
                    matchStaticText(text, staticFindings, entry.name)
                }
            }
            ApkFileSignals(
                usesKnownPacker = usesKnownPacker,
                hasNativeLibraries = hasNativeLibraries,
                apkFileCount = apkFileCount,
                dexFileCount = dexFileCount,
                nativeLibraryCount = nativeLibraryCount,
                assetFileCount = assetFileCount,
                nativeArchitectures = nativeArchitectures.toList().sorted(),
                staticAnalysisLimitReached = staticAnalysisLimitReached
            )
        } catch (_: Exception) {
            ApkFileSignals(
                usesKnownPacker = usesKnownPacker,
                hasNativeLibraries = hasNativeLibraries,
                apkFileCount = apkFileCount,
                dexFileCount = dexFileCount,
                nativeLibraryCount = nativeLibraryCount,
                assetFileCount = assetFileCount,
                nativeArchitectures = nativeArchitectures.toList().sorted(),
                staticAnalysisLimitReached = staticAnalysisLimitReached
            )
        }
    }

    private fun matchTrackerText(
        text: String,
        found: MutableMap<String, TrackerFinding>,
        sourceName: String,
        sourceType: String,
        confidence: Int
    ) {
        val lowerText = text.lowercase(Locale.US)
        val slashText = lowerText.replace('.', '/')
        for (signature in trackerSignatures) {
            val matchedPattern = signature.patterns.firstOrNull { pattern ->
                matchesSearchPattern(lowerText, slashText, pattern)
            } ?: continue
            val existing = found[signature.id]
            if (existing != null && existing.confidence >= confidence) continue
            val evidence = "$sourceType matched ${matchedPattern.take(64)} in ${sourceName.takeLast(80)}"
            found[signature.id] = TrackerFinding(
                signature.id,
                signature.name,
                signature.category,
                signature.purpose,
                signature.riskWeight,
                evidence,
                confidence
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun matchBundleText(
        bundle: Bundle,
        found: MutableMap<String, TrackerFinding>,
        sourceType: String
    ) {
        for (key in bundle.keySet()) {
            val value = try {
                bundle.get(key)?.toString() ?: ""
            } catch (_: Exception) {
                ""
            }
            val text = if (value.isEmpty()) key else "$key $value"
            matchTrackerText(text, found, key, sourceType, 84)
        }
    }

    private fun matchComponentText(
        component: ComponentInfo,
        found: MutableMap<String, TrackerFinding>,
        sourceType: String
    ) {
        matchTrackerText(component.name, found, component.name, sourceType, 82)
        component.processName?.let {
            matchTrackerText(it, found, component.name, "$sourceType process", 64)
        }
        component.metaData?.let {
            matchBundleText(it, found, "$sourceType metadata")
        }
    }

    private fun matchesSearchPattern(lowerText: String, slashText: String, pattern: String): Boolean {
        val lowerPattern = pattern.lowercase(Locale.US)
        if (lowerText.contains(lowerPattern)) return true
        val slashPattern = lowerPattern.replace('.', '/')
        if (slashText.contains(slashPattern)) return true
        val dotPattern = lowerPattern.replace('/', '.')
        return lowerText.contains(dotPattern)
    }

    private fun isAdvertisingIdentifierConsumer(finding: TrackerFinding): Boolean {
        val category = finding.category.lowercase(Locale.US)
        return finding.id in advertisingIdentifierConsumerIds ||
            category.contains("advertising") ||
            category.contains("ads") ||
            category.contains("attribution")
    }

    private fun matchStaticText(
        text: String,
        found: MutableMap<String, StaticFinding>,
        sourceName: String
    ) {
        for (signature in staticSignalSignatures) {
            if (found.containsKey(signature.id)) continue
            if (signature.patterns.any { text.contains(it.lowercase(Locale.US)) }) {
                found[signature.id] = StaticFinding(
                    signature.id,
                    signature.title,
                    signature.description,
                    signature.severity,
                    signature.weight,
                    "${signature.evidence} in ${sourceName.takeLast(80)}"
                )
            }
        }
    }

    private fun readLimited(input: InputStream, maxBytes: Int): ByteArray {
        val buffer = ByteArray(16 * 1024)
        val out = ByteArrayOutputStream()
        var total = 0
        while (total < maxBytes && !Thread.currentThread().isInterrupted) {
            val read = input.read(buffer, 0, minOf(buffer.size, maxBytes - total))
            if (read <= 0) break
            out.write(buffer, 0, read)
            total += read
        }
        return out.toByteArray()
    }

    private fun searchableText(bytes: ByteArray): String {
        val latinText = String(bytes, Charsets.ISO_8859_1)
        val sampleSize = minOf(bytes.size, 4096)
        if (sampleSize == 0) return ""
        val zeroBytes = bytes.take(sampleSize).count { it.toInt() == 0 }
        val text = if (zeroBytes > sampleSize / 8) {
            buildString {
                append(latinText)
                append('\n')
                append(String(bytes, Charsets.UTF_16LE))
                append('\n')
                append(String(bytes, Charsets.UTF_16BE))
            }
        } else {
            latinText
        }
        return text.lowercase(Locale.US)
    }

    private fun copyLimited(input: InputStream, output: FileOutputStream, maxBytes: Long) {
        val buffer = ByteArray(64 * 1024)
        var total = 0L
        while (total < maxBytes && !Thread.currentThread().isInterrupted) {
            val read = input.read(buffer, 0, minOf(buffer.size.toLong(), maxBytes - total).toInt())
            if (read <= 0) break
            output.write(buffer, 0, read)
            total += read
        }
    }

    private fun declaresAccessibilityService(pkg: PackageInfo): Boolean {
        return pkg.services?.any { service ->
            service.permission == "android.permission.BIND_ACCESSIBILITY_SERVICE" ||
                service.name.lowercase(Locale.US).contains("accessibility")
        } ?: false
    }

    private fun declaresDeviceAdmin(pkg: PackageInfo): Boolean {
        return pkg.receivers?.any { receiver ->
            receiver.permission == "android.permission.BIND_DEVICE_ADMIN" ||
                receiver.name.lowercase(Locale.US).contains("deviceadmin")
        } ?: false
    }

    private fun classifyInstallSource(appInfo: ApplicationInfo, installerPackage: String?): String {
        if (isSystemApp(appInfo)) return "System"
        if (installerPackage.isNullOrEmpty()) return "Unknown"
        return trustedInstallers[installerPackage] ?: "Unknown"
    }

    private fun getRawInstallerPackage(packageName: String): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val sourceInfo = packageManager.getInstallSourceInfo(packageName)
                sourceInfo.installingPackageName ?: sourceInfo.initiatingPackageName
            } else {
                @Suppress("DEPRECATION")
                packageManager.getInstallerPackageName(packageName)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun getAppName(app: ApplicationInfo, fallback: String): String {
        return try {
            packageManager.getApplicationLabel(app).toString()
        } catch (_: Exception) {
            fallback
        }
    }

    private fun isSystemApp(app: ApplicationInfo): Boolean {
        return (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
            (app.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
    }

    private fun looksLikeSystemApp(appName: String, packageName: String): Boolean {
        val text = "$appName $packageName".lowercase(Locale.US)
        val words = listOf("system", "update", "security", "settings", "service", "android", "google play")
        return words.any { text.contains(it) }
    }

    private fun hasAny(permissions: Set<String>, vararg names: String): Boolean {
        return names.any { permissions.contains(it) }
    }

    private fun getAppIcon(app: ApplicationInfo, lastUpdateTime: Long): String {
        return try {
            val iconCacheDir = File(context.cacheDir, "app_icons")
            if (!iconCacheDir.exists()) iconCacheDir.mkdirs()
            val iconFile = File(iconCacheDir, "${app.packageName}.png")
            if (iconFile.exists() && (lastUpdateTime <= 0L || iconFile.lastModified() >= lastUpdateTime)) {
                return iconFile.absolutePath
            }

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
            FileOutputStream(iconFile).use { stream ->
                scaled.compress(Bitmap.CompressFormat.PNG, 85, stream)
            }
            iconFile.setLastModified(System.currentTimeMillis())
            if (scaled !== bitmap) {
                scaled.recycle()
            }
            iconFile.absolutePath
        } catch (_: Exception) {
            ""
        }
    }

    private fun buildPdfLines(report: JSONObject): List<String> {
        val lines = mutableListOf<String>()
        lines.add("# Device Overview")
        lines.add("Device score: ${report.optInt("deviceScore", 100)}")
        lines.add("Apps scanned: ${report.optInt("totalApps", 0)}")
        lines.add("Trackers found: ${report.optInt("totalTrackers", 0)}")
        lines.add("Permission changes: ${report.optInt("permissionChanges", 0)}")
        lines.add("")
        lines.add("# Highest Risk Apps")
        val apps = report.optJSONArray("topRiskApps") ?: JSONArray()
        for (i in 0 until minOf(apps.length(), 10)) {
            val app = apps.optJSONObject(i) ?: continue
            lines.add(
                "${i + 1}. ${app.optString("appName")} - score ${app.optInt("score")} - ${app.optString("risk")}"
            )
            lines.add("   ${app.optInt("permissions")} permissions, ${app.optInt("trackers")} trackers")
        }
        lines.add("")
        lines.add("# Recommendations")
        val recommendations = report.optJSONArray("recommendations") ?: JSONArray()
        for (i in 0 until minOf(recommendations.length(), 10)) {
            lines.add("- ${recommendations.optString(i)}")
        }
        return lines
    }
}

private data class ApkInspection(
    val trackers: List<TrackerFinding>,
    val staticFindings: List<StaticFinding>,
    val usesKnownPacker: Boolean,
    val hasNativeLibraries: Boolean,
    val apkSha256: String,
    val apkFileCount: Int,
    val dexFileCount: Int,
    val nativeLibraryCount: Int,
    val assetFileCount: Int,
    val nativeArchitectures: List<String>,
    val staticAnalysisLimitReached: Boolean
)

private data class ApkFileSignals(
    val usesKnownPacker: Boolean,
    val hasNativeLibraries: Boolean,
    val apkFileCount: Int,
    val dexFileCount: Int,
    val nativeLibraryCount: Int,
    val assetFileCount: Int,
    val nativeArchitectures: List<String>,
    val staticAnalysisLimitReached: Boolean
)

private data class TrackerSignature(
    val id: String,
    val name: String,
    val category: String,
    val purpose: String,
    val riskWeight: Int,
    val patterns: List<String>
)

private data class StaticSignalSignature(
    val id: String,
    val title: String,
    val description: String,
    val severity: String,
    val weight: Int,
    val evidence: String,
    val patterns: List<String>
)

private data class TrackerFinding(
    val id: String,
    val name: String,
    val category: String,
    val purpose: String,
    val riskWeight: Int,
    val evidence: String,
    val confidence: Int
) {
    fun toJson(): JSONObject {
        return JSONObject()
            .put("id", id)
            .put("name", name)
            .put("category", category)
            .put("purpose", purpose)
            .put("riskWeight", riskWeight)
            .put("evidence", evidence)
            .put("confidence", confidence)
    }
}

private data class StaticFinding(
    val id: String,
    val title: String,
    val description: String,
    val severity: String,
    val weight: Int,
    val evidence: String
) {
    fun toJson(): JSONObject {
        return JSONObject()
            .put("id", id)
            .put("title", title)
            .put("description", description)
            .put("severity", severity)
            .put("weight", weight)
            .put("evidence", evidence)
    }
}
