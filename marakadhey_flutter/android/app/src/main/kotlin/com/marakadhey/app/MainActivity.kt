package com.marakadhey.app

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val SHARE_CHANNEL = "com.marakadhey.app/share"
    private val ALARM_CHANNEL = "com.marakadhey.app/alarms"
    private var sharedData: HashMap<String, String>? = null
    private var shareMethodChannel: MethodChannel? = null
    private var alarmMethodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
        sharedData?.let { data ->
            shareMethodChannel?.invokeMethod("onSharedDataReceived", data)
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            val map = HashMap<String, String>()

            var text = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (text.isNullOrBlank()) {
                text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
            }
            if (text.isNullOrBlank() && intent.clipData != null && intent.clipData!!.itemCount > 0) {
                val clipItem = intent.clipData!!.getItemAt(0)
                text = clipItem.text?.toString() ?: clipItem.uri?.toString()
            }

            var subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
            if (subject.isNullOrBlank()) {
                subject = intent.getCharSequenceExtra(Intent.EXTRA_SUBJECT)?.toString()
            }
            if (subject.isNullOrBlank()) {
                subject = intent.getStringExtra(Intent.EXTRA_TITLE)
            }

            if (!text.isNullOrBlank()) {
                map["text"] = text
            }
            if (!subject.isNullOrBlank()) {
                map["subject"] = subject
            }

            if (map.isNotEmpty()) {
                sharedData = map
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Share Target Channel
        shareMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
        shareMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedData" -> result.success(sharedData)
                "clearInitialSharedData" -> {
                    sharedData = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Direct Native AlarmManager Channel
        alarmMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
        alarmMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleNativeAlarm" -> {
                    val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                    val title = call.argument<String>("title") ?: "Opportunity Reminder"
                    val message = call.argument<String>("message") ?: "Your deadline is right now!"
                    val category = call.argument<String>("category") ?: "Opportunity"
                    val url = call.argument<String>("url")

                    val rawEpoch = call.argument<Any>("epochMs")
                    val epochMs: Long = when (rawEpoch) {
                        is Long -> rawEpoch
                        is Int -> rawEpoch.toLong()
                        is Number -> rawEpoch.toLong()
                        is String -> rawEpoch.toLongOrNull() ?: (System.currentTimeMillis() + 60000)
                        else -> System.currentTimeMillis() + 60000
                    }

                    scheduleExactAlarm(id, title, message, epochMs, category, url)
                    result.success(true)
                }
                "cancelNativeAlarm" -> {
                    val id = call.argument<Int>("id") ?: 0
                    cancelAlarm(id)
                    result.success(true)
                }
                "testNativeAlarm" -> {
                    val seconds = call.argument<Int>("seconds") ?: 5
                    val title = call.argument<String>("title") ?: "Marakadhey Test Alarm"
                    val message = call.argument<String>("message") ?: "Hardware alarm triggered! Never miss opportunities."
                    val targetMs = System.currentTimeMillis() + (seconds * 1000L)

                    scheduleExactAlarm(99999, title, message, targetMs, "Test", null)
                    result.success(true)
                }
                "stopAlarm" -> {
                    AlarmSoundPlayer.stop()
                    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    notificationManager.cancelAll()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleExactAlarm(id: Int, title: String, message: String, epochMs: Long, category: String, url: String?) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("title", title)
            putExtra("message", message)
            putExtra("category", category)
            putExtra("url", url)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val showIntent = Intent(this, MainActivity::class.java)
        val showPendingIntent = PendingIntent.getActivity(
            this,
            id,
            showIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // setAlarmClock gives 0 to 1 second sharp real-time latency with zero Doze throttling
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val clockInfo = AlarmManager.AlarmClockInfo(epochMs, showPendingIntent)
            alarmManager.setAlarmClock(clockInfo, pendingIntent)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epochMs, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, epochMs, pendingIntent)
        }
    }

    private fun cancelAlarm(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
}
