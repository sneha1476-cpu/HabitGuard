package com.example.habitguard

import android.Manifest
import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.habitguard/usage"

    private val SMS_PERMISSION_REQUEST_CODE = 1001

    private var latestTotalSessions = 0
    private var latestLateNightUsage = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "openUsageAccessSettings" -> {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "SETTINGS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "hasUsageAccess" -> {
                    result.success(hasUsageAccess())
                }

                "getUsageStats" -> {
                    try {
                        result.success(getUsageStats())
                    } catch (e: Exception) {
                        result.error(
                            "USAGE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "getUsageMetrics" -> {
                    try {
                        getUsageStats()

                        result.success(
                            mapOf(
                                "number_of_sessions" to
                                        latestTotalSessions,
                                "late_night_usage" to
                                        latestLateNightUsage
                            )
                        )

                    } catch (e: Exception) {
                        result.error(
                            "METRICS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // Check SMS permission
                "hasSmsPermission" -> {

                    val granted =
                        ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.SEND_SMS
                        ) == PackageManager.PERMISSION_GRANTED

                    result.success(granted)
                }

                // Request SMS permission
                "requestSmsPermission" -> {

                    if (
                        ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.SEND_SMS
                        ) == PackageManager.PERMISSION_GRANTED
                    ) {

                        result.success(true)

                    } else {

                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.SEND_SMS),
                            SMS_PERMISSION_REQUEST_CODE
                        )

                        result.success(false)
                    }
                }

                // Send SMS
                "sendSms" -> {

                    try {

                        val phoneNumber =
                            call.argument<String>("phoneNumber")

                        val message =
                            call.argument<String>("message")

                        if (phoneNumber.isNullOrBlank()) {
                            result.error(
                                "SMS_ERROR",
                                "Guardian phone number is missing.",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        if (message.isNullOrBlank()) {
                            result.error(
                                "SMS_ERROR",
                                "SMS message is empty.",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        // Check runtime permission
                        if (
                            ContextCompat.checkSelfPermission(
                                this,
                                Manifest.permission.SEND_SMS
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {

                            result.error(
                                "SMS_PERMISSION_ERROR",
                                "SEND_SMS permission is not granted.",
                                null
                            )

                            return@setMethodCallHandler
                        }

                        val smsManager =
                            SmsManager.getDefault()

                        smsManager.sendTextMessage(
                            phoneNumber,
                            null,
                            message,
                            null,
                            null
                        )

                        android.util.Log.d(
                            "HabitGuardSMS",
                            "SMS submission handed to Android SMS service"
                        )

                        result.success(true)

                    } catch (e: SecurityException) {

                        result.error(
                            "SMS_PERMISSION_ERROR",
                            "SEND_SMS permission is not granted.",
                            null
                        )

                    } catch (e: Exception) {

                        result.error(
                            "SMS_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasUsageAccess(): Boolean {

        val appOpsManager =
            getSystemService(Context.APP_OPS_SERVICE)
                    as AppOpsManager

        val mode =
            appOpsManager.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )

        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getUsageStats(): List<Map<String, Any>> {
        logAggregatedUsageDiagnostic()

        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE)
                    as UsageStatsManager

        val calendar = Calendar.getInstance()

        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)

        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val events =
            usageStatsManager.queryEvents(
                startTime,
                endTime
            )

        val event = UsageEvents.Event()

        val usageMap =
            mutableMapOf<String, Long>()

        val sessionMap =
            mutableMapOf<String, Int>()

        var totalSessions = 0

        var lateNightUsageMillis = 0L

        var currentPackage: String? = null
        var currentStartTime = 0L
        var lastSegmentEndTime = 0L
        var currentSessionHadUsage = false

        // Short activity transitions within the same app remain one session.
        val sessionGapThreshold = 5_000L

        fun finishCurrentSession() {
            val pkg = currentPackage
            if (pkg != null && currentSessionHadUsage) {
                sessionMap[pkg] = (sessionMap[pkg] ?: 0) + 1
                totalSessions++
            }
            currentSessionHadUsage = false
            lastSegmentEndTime = 0L
        }

        fun closeCurrentSegment(segmentEnd: Long) {
            val pkg = currentPackage ?: return
            if (currentStartTime <= 0L || segmentEnd <= currentStartTime) {
                currentStartTime = 0L
                return
            }

            addUsage(
                usageMap,
                pkg,
                segmentEnd - currentStartTime
            )

            lateNightUsageMillis += calculateLateNightOverlap(
                currentStartTime,
                segmentEnd
            )

            lastSegmentEndTime = segmentEnd
            currentStartTime = 0L
            currentSessionHadUsage = true
        }

        while (events.hasNextEvent()) {
            events.getNextEvent(event)

            val timestamp = event.timeStamp
            val packageName = event.packageName

            if (
                packageName == "com.graymatrix.did" ||
                packageName == "com.instagram.android" ||
                packageName == "in.startv.hotstar"
            ) {
                android.util.Log.i(
                    "HabitGuardRawEvents",
                    "time=$timestamp, type=${event.eventType}, package=$packageName"
                )
            }

            if (
                event.eventType == UsageEvents.Event.ACTIVITY_RESUMED ||
                event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND
            ) {
                if (currentPackage != null && currentPackage != packageName) {
                    closeCurrentSegment(timestamp)
                    finishCurrentSession()

                    currentPackage = packageName
                    currentStartTime = timestamp
                    currentSessionHadUsage = true
                } else {
                    if (currentPackage == null) {
                        currentPackage = packageName
                        currentStartTime = timestamp
                        currentSessionHadUsage = true
                    } else if (currentStartTime == 0L) {
                        // A long pause followed by reopening starts a new session.
                        if (
                            lastSegmentEndTime > 0L &&
                            timestamp - lastSegmentEndTime > sessionGapThreshold
                        ) {
                            finishCurrentSession()
                        }

                        currentStartTime = timestamp
                        currentSessionHadUsage = true
                    }
                    // Duplicate resume events for the same active app do not reset its start.
                }
            } else if (
                event.eventType == UsageEvents.Event.ACTIVITY_PAUSED ||
                event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND
            ) {
                if (currentPackage == packageName && currentStartTime > 0L) {
                    // Close this activity segment, but defer counting the app session.
                    // A quick resume of the same app will remain part of that session.
                    closeCurrentSegment(timestamp)
                }
            }
        }

        if (currentPackage != null) {
            if (currentStartTime > 0L) {
                closeCurrentSegment(endTime)
            }
            finishCurrentSession()
        }
        android.util.Log.i("HabitGuardUsageDiag", "EVENT_MAP_BEGIN")
        for ((pkg, millis) in usageMap.toList().sortedByDescending { it.second }) {
            android.util.Log.i(
                "HabitGuardUsageDiag",
                "EVENT_APP=$pkg, millis=$millis, minutes=${millis / 60000L}"
            )
        }
        android.util.Log.i(
            "HabitGuardUsageDiag",
            "EVENT_MAP_TOTAL_MINUTES=${usageMap.values.sum() / 60000L}"
        )

        val lateNightMinutes =
            (
                    lateNightUsageMillis /
                            (1000L * 60L)
                    ).toInt()

        latestTotalSessions = totalSessions
        latestLateNightUsage = lateNightMinutes

        val resultList =
            mutableListOf<Map<String, Any>>()

        val pm = packageManager

        for ((pkgName, totalTime) in usageMap) {

            if (pkgName == packageName) {
                continue
            }

            if (totalTime <= 0L) {
                continue
            }

            val usageMinutes =
                totalTime /
                        (1000L * 60L)

            if (usageMinutes <= 0L) {
                continue
            }

            if (isHomeApplication(pkgName)) {
                continue
            }

            val appName =
                try {
                    val appInfo = pm.getApplicationInfo(pkgName, 0)
                    pm.getApplicationLabel(appInfo).toString()
                        .takeIf { it.isNotBlank() && it != pkgName }
                        ?: pkgName
                } catch (e: Exception) {
                    android.util.Log.w(
                        "HabitGuardAppLabel",
                        "Label lookup failed for $pkgName: ${e.message}"
                    )
                    pkgName
                }

            val appSessions =
                sessionMap[pkgName] ?: 0

            resultList.add(
                mapOf(
                    "packageName" to pkgName,
                    "appName" to appName,
                    "usageMinutes" to usageMinutes.toInt(),
                    "sessions" to appSessions
                )
            )
        }

        val sortedResult = resultList.sortedByDescending {
            it["usageMinutes"] as Int
        }

        android.util.Log.i("HabitGuardUsageDiag", "FINAL_RESULT_LIST_BEGIN count=${sortedResult.size}")

        sortedResult.forEach { app ->
            android.util.Log.i(
                "HabitGuardUsageDiag",
                "FINAL_APP package=${app["packageName"]} name=${app["appName"]} minutes=${app["usageMinutes"]}"
            )
        }

        android.util.Log.i("HabitGuardUsageDiag", "FINAL_RESULT_LIST_END")

        return sortedResult
    }

    private fun addUsage(
        usageMap: MutableMap<String, Long>,
        packageName: String,
        duration: Long
    ) {

        usageMap[packageName] =
            (usageMap[packageName] ?: 0L) +
                    duration
    }

    private fun calculateLateNightOverlap(
        sessionStart: Long,
        sessionEnd: Long
    ): Long {
        if (sessionEnd <= sessionStart) {
            return 0L
        }

        var totalOverlap = 0L
        val dayCalendar = Calendar.getInstance()
        dayCalendar.timeInMillis = sessionStart

        dayCalendar.set(Calendar.HOUR_OF_DAY, 0)
        dayCalendar.set(Calendar.MINUTE, 0)
        dayCalendar.set(Calendar.SECOND, 0)
        dayCalendar.set(Calendar.MILLISECOND, 0)

        // Start one day earlier so sessions between midnight and 05:00
        // include the late-night window that began at 22:00 the previous day.
        dayCalendar.add(Calendar.DAY_OF_YEAR, -1)

        while (dayCalendar.timeInMillis <= sessionEnd) {
            val lateNightStart = dayCalendar.timeInMillis +
                (22L * 60L * 60L * 1000L)

            val lateNightEnd = dayCalendar.timeInMillis +
                (24L * 60L * 60L * 1000L) +
                (5L * 60L * 60L * 1000L)

            val overlapStart = maxOf(sessionStart, lateNightStart)
            val overlapEnd = minOf(sessionEnd, lateNightEnd)

            if (overlapEnd > overlapStart) {
                totalOverlap += overlapEnd - overlapStart
            }

            dayCalendar.add(Calendar.DAY_OF_YEAR, 1)
        }

        return totalOverlap
    }
    private fun isHomeApplication(
        pkgName: String
    ): Boolean {

        return try {

            val homeIntent =
                Intent(Intent.ACTION_MAIN).apply {
                    addCategory(
                        Intent.CATEGORY_HOME
                    )
                }

            val homeApps =
                packageManager.queryIntentActivities(
                    homeIntent,
                    0
                )

            homeApps.any {
                it.activityInfo.packageName ==
                        pkgName
            }

        } catch (e: Exception) {

            false
        }
    }

    // Diagnostic only: compares Android aggregated foreground time by app.
    // Does not change the existing usage calculation or ML prediction.
    private fun logAggregatedUsageDiagnostic() {
        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)

        val start = calendar.timeInMillis
        val end = System.currentTimeMillis()
        val stats = manager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            start,
            end
        )

        android.util.Log.i("HabitGuardUsageDiag", "Aggregated usage entries=${stats.size}")

        stats
            .filter { it.totalTimeInForeground > 0L && it.packageName != packageName }
            .sortedByDescending { it.totalTimeInForeground }
            .forEach { item ->
                val minutes = item.totalTimeInForeground / 60000L
                android.util.Log.i(
                    "HabitGuardUsageDiag",
                    "APP=${item.packageName}, aggregatedMinutes=$minutes"
                )
            }
    }
}




