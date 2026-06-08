package com.toch.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createActivityChatNotificationChannel()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun createActivityChatNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val channel = NotificationChannel(
            "activity_chat",
            "Chatberichten",
            NotificationManager.IMPORTANCE_HIGH,
        )
        channel.description = "Nieuwe chatberichten van activiteiten"
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
