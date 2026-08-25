package com.marakadhey.app

import android.app.Activity
import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

class AlarmActivity : Activity() {
    private var opportunityId: Int = 0
    private var opportunityTitle: String = "Opportunity Reminder"
    private var opportunityCategory: String = "Opportunity"
    private var opportunityUrl: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Wake screen and show over locked device
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        opportunityId = intent.getIntExtra("id", 0)
        opportunityTitle = intent.getStringExtra("title") ?: "Opportunity Reminder"
        opportunityCategory = intent.getStringExtra("category") ?: "Opportunity"
        val message = intent.getStringExtra("message") ?: "Your deadline is right now! Never miss out."
        opportunityUrl = intent.getStringExtra("url")

        // Root ScrollView (centered vertically)
        val scrollView = ScrollView(this).apply {
            isFillViewport = true
            setBackgroundColor(Color.parseColor("#090D16"))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        val mainContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(40, 48, 40, 48)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        // 1. Perfectly Centered Alarm Icon Badge
        val iconContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            val iconBg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#1E293B"))
                setStroke(3, Color.parseColor("#FF6B00"))
            }
            background = iconBg
            layoutParams = LinearLayout.LayoutParams(140, 140).apply {
                setMargins(0, 0, 0, 14)
            }
        }
        val iconText = TextView(this).apply {
            text = "⏰"
            textSize = 34f
            gravity = Gravity.CENTER
        }
        iconContainer.addView(iconText)
        mainContainer.addView(iconContainer)

        // 2. Alarm Status Pill
        val statusBadge = TextView(this).apply {
            text = "  🚨 DEADLINE ALARM RINGING  "
            textSize = 12f
            setTextColor(Color.parseColor("#FF6B00"))
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            val badgeBg = GradientDrawable().apply {
                setColor(Color.parseColor("#271B11"))
                setStroke(2, Color.parseColor("#FF6B00"))
                cornerRadius = 24f
            }
            background = badgeBg
            setPadding(24, 8, 24, 8)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, 20)
            }
        }
        mainContainer.addView(statusBadge)

        // 3. Central Opportunity Details Card
        val cardLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            val cardBg = GradientDrawable().apply {
                setColor(Color.parseColor("#131C2E"))
                cornerRadius = 28f
                setStroke(2, Color.parseColor("#334155"))
            }
            background = cardBg
            setPadding(32, 28, 32, 28)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, 20)
            }
        }

        // Category Tag
        val categoryTag = TextView(this).apply {
            text = "  ${opportunityCategory.uppercase()}  "
            textSize = 11f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            val tagBg = GradientDrawable().apply {
                setColor(Color.parseColor("#EA580C"))
                cornerRadius = 12f
            }
            background = tagBg
            setPadding(18, 6, 18, 6)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, 12)
            }
        }
        cardLayout.addView(categoryTag)

        // Title
        val titleText = TextView(this).apply {
            text = opportunityTitle
            textSize = 22f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 8)
        }
        cardLayout.addView(titleText)

        // Details Message
        val messageText = TextView(this).apply {
            text = message
            textSize = 13f
            setTextColor(Color.parseColor("#94A3B8"))
            gravity = Gravity.CENTER
            setLineSpacing(4f, 1.1f)
            setPadding(0, 0, 0, 4)
        }
        cardLayout.addView(messageText)
        mainContainer.addView(cardLayout)

        // 4. Primary Turn Off Button
        val dismissButton = Button(this).apply {
            text = "🔕  TURN OFF ALARM"
            textSize = 15f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            val btnBg = GradientDrawable(
                GradientDrawable.Orientation.LEFT_RIGHT,
                intArrayOf(Color.parseColor("#EF4444"), Color.parseColor("#DC2626"))
            ).apply {
                cornerRadius = 26f
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                135
            ).apply {
                setMargins(0, 0, 0, 12)
            }
            setOnClickListener {
                stopAlarmAndClearNotifications()
                finish()
            }
        }
        mainContainer.addView(dismissButton)

        // 5. Open Application Link / Open App Button (Always rendered)
        val hasUrl = !opportunityUrl.isNullOrBlank()
        val linkButton = Button(this).apply {
            text = if (hasUrl) "🌐  OPEN APPLICATION LINK" else "📱  OPEN MARAKADHEY INBOX"
            textSize = 13.5f
            setTextColor(if (hasUrl) Color.parseColor("#38BDF8") else Color.parseColor("#CBD5E1"))
            typeface = Typeface.DEFAULT_BOLD
            val btnBg = GradientDrawable().apply {
                setColor(if (hasUrl) Color.parseColor("#0C2340") else Color.parseColor("#1E293B"))
                setStroke(2, if (hasUrl) Color.parseColor("#0284C7") else Color.parseColor("#334155"))
                cornerRadius = 26f
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                130
            ).apply {
                setMargins(0, 0, 0, 20)
            }
            setOnClickListener {
                if (hasUrl) {
                    openApplicationUrl(opportunityUrl)
                } else {
                    openAppInbox()
                }
            }
        }
        mainContainer.addView(linkButton)

        // 6. Snooze Header
        val snoozeHeader = TextView(this).apply {
            text = "💤  SNOOZE OPTIONS"
            textSize = 11f
            setTextColor(Color.parseColor("#64748B"))
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 10)
        }
        mainContainer.addView(snoozeHeader)

        // Snooze Chips (Equal Flex Widths)
        val snoozeRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, 8)
            }
        }

        val snoozeTimes = listOf(
            Pair(5, "5 min"),
            Pair(10, "💤 10m"),
            Pair(15, "15 min"),
            Pair(30, "30 min")
        )

        for (item in snoozeTimes) {
            val minutes = item.first
            val label = item.second
            val isDefault = minutes == 10

            val snoozeChip = Button(this).apply {
                text = label
                textSize = 12f
                setTextColor(if (isDefault) Color.WHITE else Color.parseColor("#94A3B8"))
                typeface = Typeface.DEFAULT_BOLD
                val chipBg = GradientDrawable().apply {
                    setColor(if (isDefault) Color.parseColor("#334155") else Color.parseColor("#1E293B"))
                    cornerRadius = 18f
                    if (isDefault) {
                        setStroke(2, Color.parseColor("#64748B"))
                    }
                }
                background = chipBg
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    105,
                    1.0f
                ).apply {
                    setMargins(4, 0, 4, 0)
                }
                setOnClickListener {
                    snoozeAlarm(minutes)
                }
            }
            snoozeRow.addView(snoozeChip)
        }
        mainContainer.addView(snoozeRow)

        scrollView.addView(mainContainer)
        setContentView(scrollView)
    }

    private fun openApplicationUrl(url: String?) {
        if (url.isNullOrBlank()) {
            Toast.makeText(this, "No URL specified for this opportunity", Toast.LENGTH_SHORT).show()
            return
        }

        var cleanUrl = url.trim()
        if (!cleanUrl.startsWith("http://", ignoreCase = true) && !cleanUrl.startsWith("https://", ignoreCase = true)) {
            cleanUrl = "https://$cleanUrl"
        }

        try {
            stopAlarmAndClearNotifications()

            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(cleanUrl)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                if (keyguardManager != null && keyguardManager.isKeyguardLocked) {
                    keyguardManager.requestDismissKeyguard(this, object : KeyguardManager.KeyguardDismissCallback() {
                        override fun onDismissSucceeded() {
                            try {
                                startActivity(browserIntent)
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                            finish()
                        }
                        override fun onDismissCancelled() {
                            try {
                                startActivity(browserIntent)
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                            finish()
                        }
                        override fun onDismissError() {
                            try {
                                startActivity(browserIntent)
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                            finish()
                        }
                    })
                    return
                }
            }

            startActivity(browserIntent)
            finish()
        } catch (e: Exception) {
            e.printStackTrace()
            Toast.makeText(this, "Unable to launch browser: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    private fun openAppInbox() {
        stopAlarmAndClearNotifications()
        try {
            val appIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(appIntent)
            finish()
        } catch (e: Exception) {
            e.printStackTrace()
            finish()
        }
    }

    private fun stopAlarmAndClearNotifications() {
        AlarmSoundPlayer.stop()
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(opportunityId)
            notificationManager.cancelAll()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun snoozeAlarm(minutes: Int) {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, AlarmReceiver::class.java).apply {
                putExtra("id", opportunityId)
                putExtra("title", opportunityTitle)
                putExtra("category", opportunityCategory)
                putExtra("message", "Snoozed deadline alert! Never miss opportunities.")
                putExtra("url", opportunityUrl)
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                opportunityId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val showIntent = Intent(this, MainActivity::class.java)
            val showPendingIntent = PendingIntent.getActivity(
                this,
                opportunityId,
                showIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val snoozeEpoch = System.currentTimeMillis() + (minutes * 60 * 1000L)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val clockInfo = AlarmManager.AlarmClockInfo(snoozeEpoch, showPendingIntent)
                alarmManager.setAlarmClock(clockInfo, pendingIntent)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, snoozeEpoch, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, snoozeEpoch, pendingIntent)
            }

            Toast.makeText(this, "Alarm snoozed for $minutes minutes ⏰💤", Toast.LENGTH_SHORT).show()
            stopAlarmAndClearNotifications()
            finish()
        } catch (e: Exception) {
            e.printStackTrace()
            stopAlarmAndClearNotifications()
            finish()
        }
    }

    override fun onDestroy() {
        AlarmSoundPlayer.stop()
        super.onDestroy()
    }
}
