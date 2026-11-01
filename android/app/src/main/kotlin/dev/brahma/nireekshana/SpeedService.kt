package dev.brahma.nireekshana

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.IconCompat
import java.util.Locale

/**
 * The live speed in the status bar: a foreground service whose ongoing
 * notification shows the download speed as the status bar icon and both
 * speeds in the shade, updated every second while the screen is on.
 *
 * Kept alive by being a foreground service (START_STICKY, restarted after the
 * task is swiped away, at boot and after an update) and by the battery
 * optimization exemption the Settings card asks for. Its type is specialUse:
 * dataSync is capped at 6 hours a day on Android 15 and may not start at boot.
 * Reads TrafficStats, which needs no permission. Settings → Status bar speed
 * (lib/app/settings_page.dart) turns it on and off through MainActivity.kt.
 */
class SpeedService : Service() {
    private val main = Handler(Looper.getMainLooper())
    private var lastRx = -1L
    private var lastTx = -1L
    private var lastAt = 0L
    private var ticking = false

    private val tick = object : Runnable {
        override fun run() {
            update()
            main.postDelayed(this, INTERVAL_MS)
        }
    }

    // Nobody sees the status bar with the screen off: no ticks, no battery.
    private val screen = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> stopTicking()
                Intent.ACTION_SCREEN_ON -> startTicking()
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannel(this)
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screen, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screen, filter)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!isEnabled(this)) {
            stopSelf()
            return START_NOT_STICKY
        }
        // Must come within seconds of startForegroundService, every time.
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(NOTIFICATION_ID, build(0.0, 0.0), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(NOTIFICATION_ID, build(0.0, 0.0))
            }
        } catch (e: Exception) {
            // Started from the background without an exemption (Android 12+).
            stopSelf()
            return START_NOT_STICKY
        }
        // ACTION_REPOST: the notification was swiped away (Android 14+ allows
        // that); the next tick brings it back.
        lastRx = -1L
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (power.isInteractive) startTicking() else update()
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // Some phones stop the whole app when it is swiped from recents.
        // Only an app left out of battery optimization may start a
        // foreground service from the background (Android 12+).
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (isEnabled(this) && power.isIgnoringBatteryOptimizations(packageName)) scheduleRestart(this)
    }

    override fun onDestroy() {
        stopTicking()
        try {
            unregisterReceiver(screen)
        } catch (e: Exception) {
        }
        super.onDestroy()
    }

    private fun startTicking() {
        if (ticking) return
        ticking = true
        lastRx = -1L
        main.post(tick)
    }

    private fun stopTicking() {
        ticking = false
        main.removeCallbacks(tick)
    }

    private fun update() {
        val rx = TrafficStats.getTotalRxBytes()
        val tx = TrafficStats.getTotalTxBytes()
        val now = SystemClock.elapsedRealtime()
        var down = 0.0
        var up = 0.0
        if (lastRx >= 0 && rx >= lastRx && tx >= lastTx && now > lastAt) {
            val seconds = (now - lastAt) / 1000.0
            down = (rx - lastRx) / seconds
            up = (tx - lastTx) / seconds
        }
        lastRx = rx
        lastTx = tx
        lastAt = now
        try {
            NotificationManagerCompat.from(this).notify(NOTIFICATION_ID, build(down, up))
        } catch (e: SecurityException) {
            // Notifications turned off: the service still runs, unseen.
        }
    }

    private fun build(down: Double, up: Double): Notification {
        val open = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val repost = PendingIntent.getService(
            this, 1,
            Intent(this, SpeedService::class.java).setAction(ACTION_REPOST),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(icon(down))
            .setContentTitle("↓ ${speed(down)}   ↑ ${speed(up)}")
            .setContentText(network())
            .setContentIntent(open)
            .setDeleteIntent(repost)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setShowWhen(false)
            .setLocalOnly(true)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    /** "Wi-Fi", "Mobile data", … for the second line. */
    private fun network(): String {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val caps = cm.getNetworkCapabilities(cm.activeNetwork) ?: return "Offline"
        return when {
            caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "VPN"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "Wi-Fi"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "Mobile data"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
            else -> "Connected"
        }
    }

    /**
     * The status bar icon: the download speed as two lines of text, number
     * over unit. White on transparent; the system tints it.
     */
    private fun icon(down: Double): IconCompat {
        val size = (24 * resources.displayMetrics.density).toInt().coerceAtLeast(24)
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val (number, unit) = speedParts(down)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
        // Number on the top 60%, as large as fits the width.
        paint.textSize = size * 0.62f
        val maxWidth = size * 0.98f
        val width = paint.measureText(number)
        if (width > maxWidth) paint.textSize *= maxWidth / width
        canvas.drawText(number, size / 2f, size * 0.56f, paint)
        paint.textSize = size * 0.40f
        paint.typeface = Typeface.DEFAULT
        val unitWidth = paint.measureText(unit)
        if (unitWidth > maxWidth) paint.textSize *= maxWidth / unitWidth
        canvas.drawText(unit, size / 2f, size * 0.96f, paint)
        return IconCompat.createWithBitmap(bitmap)
    }

    companion object {
        const val CHANNEL_ID = "live_speed"
        const val NOTIFICATION_ID = 7001
        const val ACTION_REPOST = "dev.brahma.nireekshana.REPOST"
        private const val INTERVAL_MS = 1000L
        private const val PREFS = "status_bar_speed"
        private const val KEY_ENABLED = "enabled"

        fun isEnabled(context: Context): Boolean =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_ENABLED, false)

        /** Turns the status bar speed on or off, and remembers it for boot. */
        fun setEnabled(context: Context, on: Boolean) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean(KEY_ENABLED, on).apply()
            if (on) start(context) else context.stopService(Intent(context, SpeedService::class.java))
        }

        /** Starts the service when it is turned on; false when Android refused. */
        fun start(context: Context): Boolean {
            if (!isEnabled(context)) return false
            return try {
                ContextCompat.startForegroundService(context, Intent(context, SpeedService::class.java))
                true
            } catch (e: Exception) {
                false
            }
        }

        fun createChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val channel = NotificationChannel(CHANNEL_ID, "Live speed", NotificationManager.IMPORTANCE_LOW).apply {
                description = "Download and upload speed in the status bar"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        private fun scheduleRestart(context: Context) {
            val intent = Intent(context, SpeedService::class.java)
            val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            val pending = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getForegroundService(context, 2, intent, flags)
            } else {
                PendingIntent.getService(context, 2, intent, flags)
            }
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            try {
                alarms.set(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + 1500, pending)
            } catch (e: Exception) {
            }
        }

        /** Bits per second, as lib/domain/bytes.dart's speed(): "4.2 Mbps". */
        fun speed(bytesPerSecond: Double): String {
            val (number, unit) = speedParts(bytesPerSecond)
            return "$number $unit"
        }

        /** ("4.2", "Mbps"), ("42", "Mbps"): one decimal below 10, so it fits the icon. */
        fun speedParts(bytesPerSecond: Double): Pair<String, String> {
            var v = bytesPerSecond * 8.0
            val units = arrayOf("bps", "kbps", "Mbps", "Gbps")
            var i = 0
            while (v >= 1000 && i < units.size - 1) {
                v /= 1000
                i++
            }
            // Under 1 kbps reads as idle: "0 kbps" rather than jumping units.
            if (i == 0) return Pair(if (v < 1) "0" else "<1", "kbps")
            val digits = if (v >= 10) 0 else 1
            var text = String.format(Locale.US, "%.${digits}f", v)
            if (text.contains('.')) text = text.trimEnd('0').trimEnd('.')
            return Pair(text, units[i])
        }
    }
}
