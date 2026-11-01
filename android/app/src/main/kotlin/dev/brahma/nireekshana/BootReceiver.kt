package dev.brahma.nireekshana

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Brings the status bar speed (SpeedService.kt) back after a restart and
 * after the app is updated, when it was on. Android allows a specialUse
 * foreground service to start from these broadcasts.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON" -> SpeedService.start(context)
        }
    }
}
