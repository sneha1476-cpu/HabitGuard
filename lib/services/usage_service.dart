import 'package:flutter/services.dart';

class UsageService {
  static const MethodChannel _channel =
      MethodChannel('com.habitguard/usage');

  /// Opens Android Usage Access settings.
  static Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } on PlatformException catch (e) {
      throw Exception(
        'Could not open Usage Access settings: ${e.message}',
      );
    }
  }

  /// Checks whether HabitGuard has Usage Access permission.
  static Future<bool> hasUsageAccess() async {
    try {
      final bool result =
          await _channel.invokeMethod('hasUsageAccess');

      return result;
    } on PlatformException catch (e) {
      throw Exception(
        'Could not check Usage Access permission: ${e.message}',
      );
    }
  }

  /// Gets real application usage data from Android.
  static Future<List<Map<String, dynamic>>> getUsageStats() async {
    try {
      final List<dynamic> result =
          await _channel.invokeMethod('getUsageStats');

      return result
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    } on PlatformException catch (e) {
      throw Exception(
        'Could not get usage statistics: ${e.message}',
      );
    }
  }

  /// Gets additional usage metrics required for ML.
  static Future<Map<String, dynamic>> getUsageMetrics() async {
    try {
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('getUsageMetrics');

      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception(
        'Could not get usage metrics: ${e.message}',
      );
    }
  }
}