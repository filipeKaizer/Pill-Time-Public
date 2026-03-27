package com.example.pill_time

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager

class AlarmActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )

        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.putExtra("openAlarm", true)
        startActivity(intent)

        finish()
    }
}