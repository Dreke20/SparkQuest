package com.sparkquest.sparkquest

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "com.sparkquest.sparkquest/notifications"
        private const val REQ_POST_NOTIFICATIONS = 4109
        private const val CHANNEL_SPARKS = "sparkquest_sparks"
        private const val CHANNEL_MESSAGES = "sparkquest_messages"
        private const val CHANNEL_CALLS = "sparkquest_calls"
        private const val CHANNEL_SAFETY = "sparkquest_safety"
        private const val WEAR_SHIELD_NOTIF_ID = 4199
        private const val EXTRA_WEAR_SOS = "wear_sos_triggered"
    }

    private var notificationChannel: MethodChannel? = null
    private var pendingWearSos: Boolean = false
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ensureNotificationChannels()
        pendingWearSos = intent?.getBooleanExtra(EXTRA_WEAR_SOS, false) == true

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        notificationChannel = channel
        channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> handleRequestPermission(result)
                    "hasPermission" -> result.success(hasNotificationPermission())
                    "armWearOsShield" -> {
                        val venue = call.argument<String>("venue") ?: "Active Date"
                        armWearOsShieldNotification(venue)
                        result.success(true)
                    }
                    "disarmWearOsShield" -> {
                        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                        manager.cancel(WEAR_SHIELD_NOTIF_ID)
                        result.success(true)
                    }
                    "consumePendingWearSos" -> {
                        val wasPending = pendingWearSos
                        pendingWearSos = false
                        result.success(wasPending)
                    }
                    "showNotification" -> {
                        val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                        val title = call.argument<String>("title") ?: "SparkQuest"
                        val body = call.argument<String>("body") ?: ""
                        val channelId = call.argument<String>("channelId") ?: CHANNEL_MESSAGES
                        showLocalNotification(id, title, body, channelId)
                        result.success(true)
                    }
                    "syncBackgroundSession" -> {
                        val baseUrl = call.argument<String>("baseUrl") ?: ""
                        val anonKey = call.argument<String>("anonKey") ?: ""
                        val accessToken = call.argument<String>("accessToken")
                        val userId = call.argument<String>("userId") ?: ""
                        val notifySparks = call.argument<Boolean>("notifySparks") ?: true
                        val notifyMessages = call.argument<Boolean>("notifyMessages") ?: true
                        val notifyCalls = call.argument<Boolean>("notifyCalls") ?: true
                        if (baseUrl.isNotEmpty() && anonKey.isNotEmpty() && userId.isNotEmpty()) {
                            NotificationSyncJobService.saveSessionAndSchedule(
                                applicationContext,
                                baseUrl,
                                anonKey,
                                accessToken,
                                userId,
                                notifySparks,
                                notifyMessages,
                                notifyCalls
                            )
                        }
                        result.success(true)
                    }
                    "clearBackgroundSession" -> {
                        NotificationSyncJobService.clearSessionAndCancel(applicationContext)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun handleRequestPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (hasNotificationPermission()) {
                result.success(true)
            } else {
                pendingPermissionResult = result
                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQ_POST_NOTIFICATIONS)
            }
        } else {
            result.success(true)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_POST_NOTIFICATIONS) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun ensureNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channels = listOf(
            NotificationChannel(
                CHANNEL_SPARKS,
                "Sparks & Matches",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts when you unlock a new mutual Spark or guild match"
            },
            NotificationChannel(
                CHANNEL_MESSAGES,
                "Guild & Date Chats",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming chat messages and Sparky Wingman updates"
            },
            NotificationChannel(
                CHANNEL_CALLS,
                "Spark Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming encrypted WebRTC video and voice date calls"
            },
            NotificationChannel(
                CHANNEL_SAFETY,
                "Date Shield & WearOS SOS",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "WearOS Watch companion panic trigger and Date Shield check-ins"
            }
        )
        channels.forEach { manager.createNotificationChannel(it) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_WEAR_SOS, false)) {
            pendingWearSos = false
            notificationChannel?.invokeMethod("onWearSosTriggered", mapOf("source" to "wear_os_action"))
        }
    }

    private fun armWearOsShieldNotification(venue: String) {
        if (!hasNotificationPermission()) return
        ensureNotificationChannels()

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val sosIntent = Intent(this, MainActivity::class.java).apply {
            this.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_WEAR_SOS, true)
        }
        val sosPending = PendingIntent.getActivity(this, 4201, sosIntent, flags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(this, CHANNEL_SAFETY)
        } else {
            @Suppress("DEPRECATION")
            android.app.Notification.Builder(this)
        }

        val sosAction = android.app.Notification.Action.Builder(
            android.graphics.drawable.Icon.createWithResource(this, applicationInfo.icon),
            "SOS Panic",
            sosPending
        ).build()

        val wearableExtender = android.app.Notification.WearableExtender()
            .addAction(sosAction)

        builder
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle("Date Shield & WearOS Armed")
            .setContentText("Checking in at $venue • Swipe on watch for 1-Tap SOS")
            .setOngoing(true)
            .addAction(sosAction)
            .extend(wearableExtender)

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(WEAR_SHIELD_NOTIF_ID, builder.build())
    }

    private fun showLocalNotification(id: Int, title: String, body: String, requestedChannel: String) {
        if (!hasNotificationPermission()) return
        ensureNotificationChannels()

        val channelId = when (requestedChannel) {
            CHANNEL_SPARKS, CHANNEL_MESSAGES, CHANNEL_CALLS -> requestedChannel
            else -> CHANNEL_MESSAGES
        }

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, id, launchIntent, pendingIntentFlags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            android.app.Notification.Builder(this)
        }

        builder
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(android.app.Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(id, builder.build())
    }
}
