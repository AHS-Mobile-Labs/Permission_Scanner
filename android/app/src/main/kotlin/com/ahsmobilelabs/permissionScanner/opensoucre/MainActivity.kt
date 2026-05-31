package com.ahsmobilelabs.permissionScanner.opensoucre

import android.app.Activity
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.StrictMode
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference

class MainActivity : FlutterActivity() {
    private val CHANNEL = "permission_scanner"
    private val APK_PICK_REQUEST = 4812
    private val mainHandler = Handler(Looper.getMainLooper())
    private val workerThreadId = AtomicInteger(0)
    private val scannerExecutor = Executors.newFixedThreadPool(2) { runnable ->
        Thread(runnable, "permission-scanner-${workerThreadId.incrementAndGet()}").apply {
            priority = Thread.NORM_PRIORITY - 1
        }
    }
    private val timeoutExecutor = Executors.newSingleThreadScheduledExecutor { runnable ->
        Thread(runnable, "permission-scanner-timeouts").apply {
            priority = Thread.NORM_PRIORITY - 1
        }
    }
    private var pendingApkPickResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        installDebugStrictMode()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val deepScan = call.argument<Boolean>("deepScan") ?: false
                    runScannerTask(result, "PERMISSION_ERROR", 60_000L) {
                        PermissionScanner(applicationContext)
                            .getInstalledAppsWithPermissions(deepScan = deepScan)
                    }
                }
                "getAppsFingerprint" -> {
                    runScannerTask(result, "FINGERPRINT_ERROR", 12_000L) {
                        PermissionScanner(applicationContext).getAppsFingerprint()
                    }
                }
                "pickApkFile" -> {
                    try {
                        if (pendingApkPickResult != null) {
                            result.error("PICK_IN_PROGRESS", "APK picker is already open", null)
                            return@setMethodCallHandler
                        }
                        pendingApkPickResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "*/*"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf(
                                "application/vnd.android.package-archive",
                                "application/octet-stream"
                            ))
                        }
                        startActivityForResult(intent, APK_PICK_REQUEST)
                    } catch (e: Exception) {
                        pendingApkPickResult = null
                        result.error("APK_PICK_ERROR", e.message, null)
                    }
                }
                "scanApk" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    runScannerTask(result, "APK_SCAN_ERROR", 60_000L) {
                        PermissionScanner(applicationContext).scanApk(uri)
                    }
                }
                "exportPdfReport" -> {
                    val reportJson = call.argument<String>("reportJson") ?: "{}"
                    runScannerTask(result, "PDF_EXPORT_ERROR", 20_000L) {
                        PermissionScanner(applicationContext).exportPdfReport(reportJson)
                    }
                }
                "exportJsonReport" -> {
                    val reportJson = call.argument<String>("reportJson") ?: "{}"
                    runScannerTask(result, "JSON_EXPORT_ERROR", 20_000L) {
                        PermissionScanner(applicationContext).exportJsonReport(reportJson)
                    }
                }
                "shareText" -> {
                    try {
                        val title = call.argument<String>("title") ?: "Permission Scanner"
                        val text = call.argument<String>("text") ?: ""
                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_SUBJECT, title)
                            putExtra(Intent.EXTRA_TEXT, text)
                        }
                        startActivity(Intent.createChooser(shareIntent, title))
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", e.message, null)
                    }
                }
                "clearIconCache" -> {
                    runScannerTask(result, "CACHE_CLEAR_ERROR", 10_000L) {
                        PermissionScanner(applicationContext).clearIconCache()
                        null
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == APK_PICK_REQUEST) {
            val result = pendingApkPickResult
            pendingApkPickResult = null
            if (resultCode == Activity.RESULT_OK) {
                val uri: Uri? = data?.data
                result?.success(uri?.toString() ?: "")
            } else {
                result?.success("")
            }
        }
    }

    override fun onDestroy() {
        pendingApkPickResult?.error("ACTIVITY_DESTROYED", "APK picker was closed", null)
        pendingApkPickResult = null
        super.onDestroy()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        scannerExecutor.shutdownNow()
        timeoutExecutor.shutdownNow()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun <T> runScannerTask(
        result: MethodChannel.Result,
        errorCode: String,
        timeoutMs: Long,
        task: () -> T
    ) {
        val delivered = AtomicBoolean(false)
        val futureRef = AtomicReference<Future<*>?>()
        val timeoutRef = AtomicReference<ScheduledFuture<*>?>()

        try {
            val timeoutFuture = timeoutExecutor.schedule({
                futureRef.get()?.cancel(true)
                if (delivered.compareAndSet(false, true)) {
                    mainHandler.post {
                        result.error(errorCode, "Operation timed out after ${timeoutMs / 1000}s", null)
                    }
                }
            }, timeoutMs, TimeUnit.MILLISECONDS)
            timeoutRef.set(timeoutFuture)

            val future = scannerExecutor.submit {
                try {
                    val value = task()
                    if (delivered.compareAndSet(false, true)) {
                        timeoutRef.get()?.cancel(false)
                        mainHandler.post { result.success(value) }
                    }
                } catch (interrupted: InterruptedException) {
                    Thread.currentThread().interrupt()
                    if (delivered.compareAndSet(false, true)) {
                        timeoutRef.get()?.cancel(false)
                        mainHandler.post {
                            result.error(errorCode, "Operation interrupted", null)
                        }
                    }
                } catch (throwable: Throwable) {
                    Log.e("PermissionScanner", "Background scanner task failed", throwable)
                    if (delivered.compareAndSet(false, true)) {
                        timeoutRef.get()?.cancel(false)
                        mainHandler.post {
                            result.error(errorCode, throwable.message, null)
                        }
                    }
                }
            }
            futureRef.set(future)
        } catch (throwable: Throwable) {
            Log.e("PermissionScanner", "Unable to schedule scanner task", throwable)
            if (delivered.compareAndSet(false, true)) {
                result.error(errorCode, throwable.message, null)
            }
        }
    }

    private fun installDebugStrictMode() {
        val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!isDebuggable) return

        StrictMode.setThreadPolicy(
            StrictMode.ThreadPolicy.Builder()
                .detectDiskReads()
                .detectDiskWrites()
                .detectNetwork()
                .penaltyLog()
                .build()
        )
        StrictMode.setVmPolicy(
            StrictMode.VmPolicy.Builder()
                .detectActivityLeaks()
                .detectLeakedClosableObjects()
                .penaltyLog()
                .build()
        )
    }
}
