package com.marakadhey.app

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmStopReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", 0)
        AlarmSoundPlayer.stop()
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (id != 0) {
                notificationManager.cancel(id)
            }
            notificationManager.cancelAll()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
