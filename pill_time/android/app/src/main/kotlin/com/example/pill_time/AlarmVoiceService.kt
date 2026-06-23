package com.example.pill_time

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.tts.TextToSpeech
import java.util.Locale

class AlarmVoiceService : Service(), TextToSpeech.OnInitListener {
    private val handler = Handler(Looper.getMainLooper())
    private var tts: TextToSpeech? = null
    private var speechText = ""
    private var isReady = false

    private val speakLoop = object : Runnable {
        override fun run() {
            if (isReady && speechText.isNotBlank()) {
                maximizeSpeechVolume()
                val params = Bundle().apply {
                    putString(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_ALARM.toString())
                }
                tts?.speak(speechText, TextToSpeech.QUEUE_FLUSH, params, "pill_time_alarm")
            }
            handler.postDelayed(this, REPEAT_DELAY_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        tts = TextToSpeech(this, this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Alarme tocando"
        speechText = intent?.getStringExtra(EXTRA_SPEECH)
            ?: "Está na hora de tomar seus remédios."

        createChannel()
        startForeground(NOTIFICATION_ID, buildNotification(title))

        handler.removeCallbacks(speakLoop)
        handler.post(speakLoop)

        return START_STICKY
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale("pt", "BR")
            tts?.setSpeechRate(0.5f)
            tts?.setPitch(1.0f)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                tts?.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build()
                )
            }
            isReady = true
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(speakLoop)
        tts?.stop()
        tts?.shutdown()
        tts = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(title: String): android.app.Notification {
        val alarmIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            alarmIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notificationBuilder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(this, CHANNEL_ID)
        } else {
            android.app.Notification.Builder(this)
        }

        return notificationBuilder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText("Desbloqueie ou toque para parar a fala.")
            .setPriority(android.app.Notification.PRIORITY_MAX)
            .setCategory(android.app.Notification.CATEGORY_ALARM)
            .setVisibility(android.app.Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setFullScreenIntent(pendingIntent, true)
            .build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Pill Reminder Voice",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Fala repetida enquanto o alarme de remédio está ativo"
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private fun maximizeSpeechVolume() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val streams = intArrayOf(AudioManager.STREAM_ALARM, AudioManager.STREAM_MUSIC)

        for (stream in streams) {
            val maxVolume = audioManager.getStreamMaxVolume(stream)
            audioManager.setStreamVolume(stream, maxVolume, 0)
        }
    }

    companion object {
        private const val CHANNEL_ID = "pill_alarm_voice_channel"
        private const val NOTIFICATION_ID = 8301
        private const val REPEAT_DELAY_MS = 10000L
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_SPEECH = "speech"

        fun start(context: Context, title: String, speech: String) {
            val intent = Intent(context, AlarmVoiceService::class.java).apply {
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_SPEECH, speech)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, AlarmVoiceService::class.java))
        }
    }
}
