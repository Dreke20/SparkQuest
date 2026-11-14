package com.sparkquest.sparkquest

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONArray
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.concurrent.thread

/**
 * Periodic Android JobService that polls Supabase REST for new matches, messages,
 * and incoming calls when the Flutter UI is backgrounded or closed, posting alerts
 * directly to the OS notification tray without requiring Firebase google-services.json.
 */
class NotificationSyncJobService : JobService() {
    companion object {
        const val PREFS_NAME = "sparkquest_bg_notify_prefs"
        const val JOB_ID = 41091

        private const val KEY_BASE_URL = "base_url"
        private const val KEY_ANON_KEY = "anon_key"
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_USER_ID = "user_id"
        private const val KEY_NOTIFY_SPARKS = "notify_sparks"
        private const val KEY_NOTIFY_MESSAGES = "notify_messages"
        private const val KEY_NOTIFY_CALLS = "notify_calls"
        private const val KEY_LAST_SYNC_ISO = "last_sync_iso"

        fun saveSessionAndSchedule(
            context: Context,
            baseUrl: String,
            anonKey: String,
            accessToken: String?,
            userId: String,
            notifySparks: Boolean,
            notifyMessages: Boolean,
            notifyCalls: Boolean
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existingSync = prefs.getString(KEY_LAST_SYNC_ISO, null)
            prefs.edit()
                .putString(KEY_BASE_URL, baseUrl)
                .putString(KEY_ANON_KEY, anonKey)
                .putString(KEY_ACCESS_TOKEN, accessToken ?: anonKey)
                .putString(KEY_USER_ID, userId)
                .putBoolean(KEY_NOTIFY_SPARKS, notifySparks)
                .putBoolean(KEY_NOTIFY_MESSAGES, notifyMessages)
                .putBoolean(KEY_NOTIFY_CALLS, notifyCalls)
                .apply {
                    if (existingSync == null) {
                        putString(KEY_LAST_SYNC_ISO, currentUtcIso())
                    }
                }
                .apply()

            schedulePeriodicSync(context)
        }

        fun clearSessionAndCancel(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().clear().apply()
            val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as? JobScheduler
            scheduler?.cancel(JOB_ID)
        }

        private fun schedulePeriodicSync(context: Context) {
            val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as? JobScheduler ?: return
            val component = ComponentName(context, NotificationSyncJobService::class.java)
            val info = JobInfo.Builder(JOB_ID, component)
                .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
                .setPeriodic(15 * 60 * 1000L)
                .setPersisted(false)
                .build()
            scheduler.schedule(info)
        }

        private fun currentUtcIso(): String {
            val sdf = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
            sdf.timeZone = TimeZone.getTimeZone("UTC")
            return sdf.format(Date())
        }
    }

    override fun onStartJob(params: JobParameters?): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val baseUrl = prefs.getString(KEY_BASE_URL, null)
        val anonKey = prefs.getString(KEY_ANON_KEY, null)
        val userId = prefs.getString(KEY_USER_ID, null)
        if (baseUrl.isNullOrEmpty() || anonKey.isNullOrEmpty() || userId.isNullOrEmpty()) {
            return false
        }

        val token = prefs.getString(KEY_ACCESS_TOKEN, anonKey) ?: anonKey
        val sinceIso = prefs.getString(KEY_LAST_SYNC_ISO, currentUtcIso()) ?: currentUtcIso()
        val notifySparks = prefs.getBoolean(KEY_NOTIFY_SPARKS, true)
        val notifyMessages = prefs.getBoolean(KEY_NOTIFY_MESSAGES, true)
        val notifyCalls = prefs.getBoolean(KEY_NOTIFY_CALLS, true)

        thread {
            val nextSyncIso = currentUtcIso()
            try {
                val encodedSince = URLEncoder.encode(sinceIso, "UTF-8")

                if (notifyMessages) {
                    val msgs = fetchJsonArray(
                        "$baseUrl/rest/v1/messages?created_at=gt.$encodedSince&order=created_at.desc&limit=5",
                        anonKey,
                        token
                    )
                    for (i in 0 until msgs.length()) {
                        val row = msgs.optJSONObject(i) ?: continue
                        val senderId = row.optString("sender_id", "")
                        if (senderId.isNotEmpty() && senderId != userId) {
                            val content = row.optString("content", "Sent you a message")
                            postTrayNotification(
                                id = 8100 + i,
                                title = "New SparkQuest Message",
                                body = content,
                                channelId = "sparkquest_messages"
                            )
                            break
                        }
                    }
                }

                if (notifySparks) {
                    val matches = fetchJsonArray(
                        "$baseUrl/rest/v1/matches?created_at=gt.$encodedSince&order=created_at.desc&limit=5",
                        anonKey,
                        token
                    )
                    for (i in 0 until matches.length()) {
                        val row = matches.optJSONObject(i) ?: continue
                        val u1 = row.optString("user_id_1", "")
                        val u2 = row.optString("user_id_2", "")
                        if (u1 == userId || u2 == userId) {
                            val name = row.optString("user_name", "An Adventurer")
                            postTrayNotification(
                                id = 8200 + i,
                                title = "New Mutual Spark!",
                                body = "$name sparked with you on SparkQuest.",
                                channelId = "sparkquest_sparks"
                            )
                            break
                        }
                    }
                }

                if (notifyCalls) {
                    val calls = fetchJsonArray(
                        "$baseUrl/rest/v1/call_signals?status=eq.ringing&created_at=gt.$encodedSince&order=created_at.desc&limit=3",
                        anonKey,
                        token
                    )
                    for (i in 0 until calls.length()) {
                        val row = calls.optJSONObject(i) ?: continue
                        val calleeId = row.optString("callee_id", "")
                        val callerId = row.optString("caller_id", "")
                        if ((calleeId == userId || calleeId == "all") && callerId != userId) {
                            val callerName = row.optString("caller_name", "Spark Match")
                            postTrayNotification(
                                id = 8300 + i,
                                title = "Incoming Spark Call",
                                body = "$callerName tried calling you on SparkQuest.",
                                channelId = "sparkquest_calls"
                            )
                            break
                        }
                    }
                }

                prefs.edit().putString(KEY_LAST_SYNC_ISO, nextSyncIso).apply()
            } catch (_: Exception) {
            } finally {
                jobFinished(params, false)
            }
        }
        return true
    }

    override fun onStopJob(params: JobParameters?): Boolean = false

    private fun fetchJsonArray(endpoint: String, anonKey: String, bearerToken: String): JSONArray {
        val conn = (URL(endpoint).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 5000
            readTimeout = 5000
            setRequestProperty("apikey", anonKey)
            setRequestProperty("Authorization", "Bearer $bearerToken")
        }
        return try {
            if (conn.responseCode in 200..299) {
                val text = conn.inputStream.bufferedReader().use { it.readText() }
                JSONArray(text)
            } else {
                JSONArray()
            }
        } finally {
            conn.disconnect()
        }
    }

    private fun postTrayNotification(id: Int, title: String, body: String, channelId: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "SparkQuest Alerts",
                NotificationManager.IMPORTANCE_HIGH
            )
            manager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pi = PendingIntent.getActivity(this, id, intent, piFlags)

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
            .setContentIntent(pi)

        manager.notify(id, builder.build())
    }
}
