/*
Place this Kotlin logic inside your Flutter Android MainActivity.

It exposes:
- openUsageAccessSettings
- getUsageStats

The exact generated Flutter Android package/application class depends on
the package name selected when `flutter create` is run.

This file is provided as the integration reference for Phase 1.
*/
package com.habitguard

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class UsageMethodChannel : FlutterActivity() {
    private val channelName = "com.habitguard/usage"

    fun configure(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openUsageAccessSettings" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(null)
                }

                "getUsageStats" -> {
                    val usageStatsManager =
                        getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

                    val end = System.currentTimeMillis()
                    val start = end - 24L * 60L * 60L * 1000L

                    val stats = usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        start,
                        end
                    )

                    val output = stats
                        .filter { it.totalTimeInForeground > 0 }
                        .map {
                            mapOf(
                                "packageName" to it.packageName,
                                "appName" to it.packageName,
                                "usageMinutes" to
                                    (it.totalTimeInForeground / 60000L)
                            )
                        }

                    result.success(output)
                }

                else -> result.notImplemented()
            }
        }
    }
}
