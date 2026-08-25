package com.marakadhey.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", (System.currentTimeMillis() % 100000).toInt())
        val title = intent.getStringExtra("title") ?: "Opportunity Reminder"
        val message = intent.getStringExtra("message") ?: "Your deadline is right now! Never miss out."
        val category = intent.getStringExtra("category") ?: "Opportunity"
        val url = intent.getStringExtra("url")

        // 1. Play continuous loud looping alarm via MediaPlayer
        AlarmSoundPlayer.play(context)

        // 2. Start Full-Screen Alarm Activity (Turn on screen & display turn off button)
        val alarmActivityIntent = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("id", id)
            putExtra("title", title)
            putExtra("message", message)
            putExtra("category", category)
            putExtra("url", url)
        }

        try {
            context.startActivity(alarmActivityIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 3. Build Heads-Up Full-Screen Notification with Turn Off & Snooze Actions
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "marakadhey_full_screen_alarms_v3"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Marakadhey Full Screen Alarms",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Full screen deadline alarms"
                enableVibration(true)
                setSound(null, null)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            id,
            alarmActivityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 1-Tap Stop Action
        val stopIntent = Intent(context, AlarmStopReceiver::class.java).apply {
            putExtra("id", id)
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            context,
            id + 1000,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 1-Tap Snooze 10m Action
        val snoozeIntent = Intent(context, AlarmSnoozeReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("title", title)
            putExtra("category", category)
            putExtra("url", url)
            putExtra("minutes", 10)
        }
        val snoozePendingIntent = PendingIntent.getBroadcast(
            context,
            id + 2000,
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("⏰ $title")
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message).setSummaryText("$category Deadline Alert"))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(fullScreenPendingIntent)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(R.mipmap.ic_launcher, "🔕 TURN OFF", stopPendingIntent)
            .addAction(R.mipmap.ic_launcher, "💤 SNOOZE 10M", snoozePendingIntent)
            .setAutoCancel(true)

        notificationManager.notify(id, builder.build())
    }
}
