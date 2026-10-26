package dev.brahma.nireekshana

import android.app.AppOpsManager
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.TrafficStats
import android.os.Build
import android.os.Process
import android.os.SystemClock
import java.util.Calendar
import java.util.Locale

/**
 * What lib/domain/probe.dart and sources.dart ask Android about the
 * network: live counters (TrafficStats, no permission needed) and daily
 * totals from NetworkStatsManager, which needs usage access.
 */
class NetStats(private val context: Context) {
    private val stats = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

    /** Bytes since boot, for the whole device and for mobile data. */
    fun counters(): Map<String, Any> {
        // Counters restart with the device: the boot, to the minute, tells
        // Dart whether two readings can be subtracted.
        val boot = (System.currentTimeMillis() - SystemClock.elapsedRealtime()) / 60000
        return mapOf(
            "totalRx" to TrafficStats.getTotalRxBytes().coerceAtLeast(0),
            "totalTx" to TrafficStats.getTotalTxBytes().coerceAtLeast(0),
            "mobileRx" to TrafficStats.getMobileRxBytes().coerceAtLeast(0),
            "mobileTx" to TrafficStats.getMobileTxBytes().coerceAtLeast(0),
            "boot" to boot.toString(),
        )
    }

    fun hasUsageAccess(): Boolean {
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * The device's usage per day for the last [days] days (today included),
     * one entry per day and kind of network that moved anything.
     */
    fun deviceUsage(days: Int): List<Map<String, Any>> {
        val out = mutableListOf<Map<String, Any>>()
        for ((day, start, end) in dayRanges(days)) {
            for ((type, kind) in KINDS) {
                val bucket = try {
                    stats.querySummaryForDevice(type, null, start, end)
                } catch (e: Exception) {
                    null
                } ?: continue
                if (bucket.rxBytes == 0L && bucket.txBytes == 0L) continue
                out.add(mapOf("day" to day, "kind" to kind, "rx" to bucket.rxBytes, "tx" to bucket.txBytes))
            }
        }
        return out
    }

    companion object {
        /**
         * The last [days] local days, oldest first, as (yyyy-MM-dd, start,
         * end) in epoch milliseconds. Calendar rather than java.time, which
         * Android 7 lacks.
         */
        fun dayRanges(days: Int): List<Triple<String, Long, Long>> {
            val day = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                add(Calendar.DAY_OF_MONTH, -(days - 1))
            }
            val out = mutableListOf<Triple<String, Long, Long>>()
            repeat(days) {
                // Locale.ROOT: always Western digits, whatever the phone's language.
                val label = String.format(
                    Locale.ROOT, "%04d-%02d-%02d",
                    day.get(Calendar.YEAR), day.get(Calendar.MONTH) + 1, day.get(Calendar.DAY_OF_MONTH),
                )
                val start = day.timeInMillis
                day.add(Calendar.DAY_OF_MONTH, 1)
                out.add(Triple(label, start, day.timeInMillis))
            }
            return out
        }

        /** Network types counted, and the usage kind each is stored as. */
        @Suppress("DEPRECATION")
        val KINDS = listOf(
            ConnectivityManager.TYPE_WIFI to "wifi",
            ConnectivityManager.TYPE_MOBILE to "mobile",
            ConnectivityManager.TYPE_ETHERNET to "ethernet",
        )
    }
}
