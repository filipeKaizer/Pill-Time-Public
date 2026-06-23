package com.example.pill_time

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object AlarmMethodChannel {
    private const val CHANNEL = "pill_time/alarm"

    fun register(activity: Activity, flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val id = call.argument<Int>("id")
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis")
                    val title = call.argument<String>("title") ?: "Hora do remédio"
                    val body = call.argument<String>("body") ?: "Tome seus medicamentos agora"
                    val speech = call.argument<String>("speech") ?: body

                    if (id == null || triggerAtMillis == null) {
                        result.error("invalid_args", "id and triggerAtMillis are required", null)
                        return@setMethodCallHandler
                    }

                    NativeAlarmScheduler.schedule(activity, id, triggerAtMillis, title, body, speech)
                    result.success(null)
                }

                "cancelAlarm" -> {
                    val id = call.argument<Int>("id")
                    if (id == null) {
                        result.error("invalid_args", "id is required", null)
                        return@setMethodCallHandler
                    }
                    NativeAlarmScheduler.cancel(activity, id)
                    result.success(null)
                }

                "cancelAllAlarms" -> {
                    NativeAlarmScheduler.cancelAll(activity)
                    result.success(null)
                }

                "stopAlarmVoice" -> {
                    AlarmVoiceService.stop(activity)
                    result.success(null)
                }

                "finishAlarmScreen" -> {
                    AlarmVoiceService.stop(activity)
                    val notificationManager =
                        activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    notificationManager.cancelAll()

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        activity.finishAndRemoveTask()
                    } else {
                        activity.finish()
                    }
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
