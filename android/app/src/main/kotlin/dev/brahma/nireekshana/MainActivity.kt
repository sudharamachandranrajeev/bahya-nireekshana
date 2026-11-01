package dev.brahma.nireekshana

import android.Manifest
import android.app.KeyguardManager
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Hands nireekshana:// links to Dart (lib/app/links.dart): the camera app opens
 * them when it scans a pairing QR code. Also tells Dart the device's name
 * for the pairing request, what Sentinel asks about the device, the network
 * counters and statistics (NetStats.kt), and hands an update's APK to the
 * system's installer (lib/domain/update.dart), and turns the status bar
 * speed (SpeedService.kt, lib/domain/status_bar.dart) on and off. A fragment activity, which
 * local_auth needs for the app lock's fingerprint and face prompt.
 */
class MainActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null
    private var pending: String? = null

    // Statistics queries can take a while; they run off the UI thread.
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pending = linkOf(intent)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.brahma.nireekshana/device").setMethodCallHandler { call, result ->
            if (call.method == "security") result.success(securityFacts()) else result.notImplemented()
        }
        val net = NetStats(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.brahma.nireekshana/net").setMethodCallHandler { call, result ->
            when (call.method) {
                "counters" -> result.success(net.counters())
                "hasUsageAccess" -> result.success(net.hasUsageAccess())
                "openUsageAccess" -> {
                    // Straight to this app's switch where the system allows it.
                    val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                        data = Uri.fromParts("package", packageName, null)
                    }
                    try {
                        startActivity(intent)
                    } catch (e: Exception) {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    }
                    result.success(null)
                }
                "deviceUsage" -> {
                    val days = call.argument<Int>("days") ?: 62
                    inBackground(result) { net.deviceUsage(days) }
                }
                "appUsage" -> {
                    val days = call.argument<Int>("days") ?: 31
                    inBackground(result) { net.appUsage(days) }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.brahma.nireekshana/update")
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")
                if (call.method != "installApk" || path == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    // Shared from filesDir/updates (res/xml/file_paths.xml).
                    val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", File(path))
                    startActivity(
                        Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                        }
                    )
                    result.success(true)
                } catch (error: Exception) {
                    result.error("install_failed", error.message, null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.brahma.nireekshana/statusbar")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(statusBarFacts())
                    "setEnabled" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        SpeedService.setEnabled(this, on)
                        result.success(statusBarFacts())
                    }
                    "askNotifications" -> {
                        val manager = NotificationManagerCompat.from(this)
                        if (Build.VERSION.SDK_INT >= 33 && !manager.areNotificationsEnabled() &&
                            !asked(Manifest.permission.POST_NOTIFICATIONS)
                        ) {
                            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 41)
                        } else {
                            // Asked before or turned off by hand: only the settings can change it.
                            openSettings(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        }
                        result.success(null)
                    }
                    "askBattery" -> {
                        // The system's own "Let app always run in background?" dialog.
                        try {
                            startActivity(
                                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                                    .setData(Uri.fromParts("package", packageName, null))
                            )
                        } catch (e: Exception) {
                            openSettings(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        }
                        result.success(null)
                    }
                    "openAppInfo" -> {
                        openSettings(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.brahma.nireekshana/links").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeLink" -> {
                        result.success(pending)
                        pending = null
                    }
                    "deviceName" -> result.success(deviceName())
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Back after a force stop or a refused background start.
        SpeedService.start(this)
    }

    /** Whether the status bar speed is on and what could stop it. */
    private fun statusBarFacts(): Map<String, Any> {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        return mapOf(
            "enabled" to SpeedService.isEnabled(this),
            "notifications" to NotificationManagerCompat.from(this).areNotificationsEnabled(),
            "unrestricted" to power.isIgnoringBatteryOptimizations(packageName),
        )
    }

    private val askedPrefs by lazy { getSharedPreferences("asked", Context.MODE_PRIVATE) }

    /** True when [permission] was asked for before; marks it asked. */
    private fun asked(permission: String): Boolean {
        val before = askedPrefs.getBoolean(permission, false)
        askedPrefs.edit().putBoolean(permission, true).apply()
        // Android shows the prompt twice at most; after a "no" with no
        // rationale left, only the settings can change it.
        return before && !ActivityCompat.shouldShowRequestPermissionRationale(this, permission)
    }

    /** This app's page of [action], or the app info page when that fails. */
    private fun openSettings(action: String) {
        val intent = Intent(action).apply {
            if (action == Settings.ACTION_APP_NOTIFICATION_SETTINGS) {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            } else if (action == Settings.ACTION_APPLICATION_DETAILS_SETTINGS) {
                data = Uri.fromParts("package", packageName, null)
            }
        }
        try {
            startActivity(intent)
        } catch (e: Exception) {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).setData(Uri.fromParts("package", packageName, null))
            )
        }
    }

    private fun inBackground(result: MethodChannel.Result, query: () -> Any?) {
        worker.execute {
            try {
                val value = query()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("stats_failed", e.message, null) }
            }
        }
    }

    /**
     * What Sentinel reads about the device (core's device_checks.dart): whether
     * a screen lock is set, storage is encrypted, and the newest security patch.
     */
    private fun securityFacts(): Map<String, Any?> {
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        val policy = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val status = policy.storageEncryptionStatus
        return mapOf(
            "screenLock" to keyguard.isDeviceSecure,
            "encrypted" to (status == DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE ||
                status == DevicePolicyManager.ENCRYPTION_STATUS_ACTIVE_PER_USER),
            "patched" to Build.VERSION.SECURITY_PATCH.takeIf { it.isNotEmpty() },
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        linkOf(intent)?.let { channel?.invokeMethod("link", it) }
    }

    private fun linkOf(intent: Intent?): String? =
        intent?.takeIf { it.action == Intent.ACTION_VIEW }?.data?.takeIf { it.scheme == "nireekshana" }?.toString()

    private fun deviceName(): String {
        val maker = Build.MANUFACTURER.replaceFirstChar { it.uppercase() }
        val model = Build.MODEL
        return if (model.startsWith(maker, ignoreCase = true)) model else "$maker $model"
    }
}
