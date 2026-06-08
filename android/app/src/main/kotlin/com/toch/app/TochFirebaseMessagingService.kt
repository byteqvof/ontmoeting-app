package com.toch.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

class TochFirebaseMessagingService : FlutterFirebaseMessagingService() {
    override fun onNewToken(token: String) {
        super.onNewToken(token)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        val data = remoteMessage.data
        if (data["type"] != "activity_chat") {
            return
        }

        showActivityChatNotification(remoteMessage)
    }

    private fun showActivityChatNotification(remoteMessage: RemoteMessage) {
        if (!canPostNotifications()) {
            return
        }

        val data = remoteMessage.data
        val activityId = data["activity_id"]?.trim().orEmpty()
        val messageId = data["message_id"]?.trim().orEmpty()
        if (activityId.isEmpty() || messageId.isEmpty()) {
            return
        }

        createActivityChatNotificationChannel()

        val title = data.firstNonBlank("chat_title", "title")
            ?: remoteMessage.notification?.title?.takeIf { it.isNotBlank() }
            ?: "Nieuwe chat"
        val body = data.firstNonBlank("chat_body", "body")
            ?: remoteMessage.notification?.body?.takeIf { it.isNotBlank() }
            ?: "Nieuw bericht"
        val groupKey = data["group_key"]?.takeIf { it.isNotBlank() }
            ?: "activity_chat:$activityId"
        val contentIntent = chatPendingIntent(activityId, messageId)

        val messageNotification = notificationBuilder(title, body, contentIntent)
            .setSmallIcon(applicationInfo.icon)
            .setAutoCancel(true)
            .setGroup(groupKey)
            .build()

        val summaryNotification = notificationBuilder(title, "Nieuwe chatberichten", contentIntent)
            .setSmallIcon(applicationInfo.icon)
            .setAutoCancel(true)
            .setGroup(groupKey)
            .setGroupSummary(true)
            .setStyle(NotificationCompat.InboxStyle().addLine(body).setSummaryText(title))
            .build()

        NotificationManagerCompat.from(this).apply {
            notify(messageId.stableNotificationId(), messageNotification)
            notify(groupKey.stableNotificationId(), summaryNotification)
        }
        Log.d(TAG, "Posted grouped chat notification for $activityId / $messageId")
    }

    private fun notificationBuilder(
        title: String,
        body: String,
        contentIntent: PendingIntent,
    ): NotificationCompat.Builder {
        return NotificationCompat.Builder(this, ACTIVITY_CHAT_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(contentIntent)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setGroupAlertBehavior(NotificationCompat.GROUP_ALERT_SUMMARY)
            .setWhen(System.currentTimeMillis())
            .setShowWhen(true)
    }

    private fun chatPendingIntent(activityId: String, messageId: String): PendingIntent {
        val uri = Uri.parse(
            "meetingsapp://activity-chat/${Uri.encode(activityId)}" +
                "?activity_id=${Uri.encode(activityId)}" +
                "&message_id=${Uri.encode(messageId)}",
        )
        val intent = Intent(Intent.ACTION_VIEW, uri, this, MainActivity::class.java)
            .addFlags(
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_NEW_TASK,
            )
            .putExtra("type", "activity_chat")
            .putExtra("activity_id", activityId)
            .putExtra("message_id", messageId)

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(this, activityId.hashCode(), intent, flags)
    }

    private fun canPostNotifications(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun createActivityChatNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val channel = NotificationChannel(
            ACTIVITY_CHAT_CHANNEL_ID,
            "Chatberichten",
            NotificationManager.IMPORTANCE_HIGH,
        )
        channel.description = "Nieuwe chatberichten van activiteiten"
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    companion object {
        private const val ACTIVITY_CHAT_CHANNEL_ID = "activity_chat"
        private const val TAG = "TochFcmService"
    }
}

private fun String.stableNotificationId(): Int {
    return hashCode() and 0x7fffffff
}

private fun Map<String, String>.firstNonBlank(vararg keys: String): String? {
    for (key in keys) {
        val value = this[key]?.takeIf { it.isNotBlank() }
        if (value != null) {
            return value
        }
    }
    return null
}
