package com.example.pill_time

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_ID, 0)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "Hora do remédio"
        val body = intent.getStringExtra(EXTRA_BODY) ?: "Tome seus medicamentos agora"
        val speech = intent.getStringExtra(EXTRA_SPEECH) ?: body

        createChannel(context)

        val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_ID, id)
        }

        val alarmPendingIntent = PendingIntent.getActivity(
            context,
            id,
            alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notificationBuilder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(context, CHANNEL_ID)
        } else {
            android.app.Notification.Builder(context)
        }

        val notification = notificationBuilder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(android.app.Notification.PRIORITY_MAX)
            .setCategory(android.app.Notification.CATEGORY_ALARM)
            .setVisibility(android.app.Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(alarmPendingIntent)
            .setFullScreenIntent(alarmPendingIntent, true)
            .build()

        AlarmVoiceService.start(context, title, speech)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(id, notification)
        }
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Pill Reminder Alarm",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Alarmes de remédio em tela cheia"
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val CHANNEL_ID = "pill_alarm_channel"
        const val EXTRA_ID = "alarm_id"
        const val EXTRA_TITLE = "alarm_title"
        const val EXTRA_BODY = "alarm_body"
        const val EXTRA_SPEECH = "alarm_speech"
    }
}
