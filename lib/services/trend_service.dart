import 'history_service.dart';

class TrendService {
  /// Gets usage history for the last 7 days.
  static Future<List<Map<String, dynamic>>> getUsageTrend() async {
    return await HistoryService.getLast7DaysUsage();
  }

  /// Calculates average screen time.
  static double calculateAverageScreenTime(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) {
      return 0.0;
    }

    double total = 0.0;

    for (final day in history) {
      final minutes =
          (day['total_minutes'] as num?)?.toDouble() ?? 0.0;

      total += minutes;
    }

    return total / history.length;
  }

  /// Finds the highest screen time.
  static double calculateMaximumScreenTime(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) {
      return 0.0;
    }

    double maximum = 0.0;

    for (final day in history) {
      final minutes =
          (day['total_minutes'] as num?)?.toDouble() ?? 0.0;

      if (minutes > maximum) {
        maximum = minutes;
      }
    }

    return maximum;
  }

  /// Finds the lowest screen time.
  static double calculateMinimumScreenTime(
    List<Map<String, dynamic>> history,
  ) {
    if (history.isEmpty) {
      return 0.0;
    }

    double minimum =
        (history.first['total_minutes'] as num?)?.toDouble() ?? 0.0;

    for (final day in history) {
      final minutes =
          (day['total_minutes'] as num?)?.toDouble() ?? 0.0;

      if (minutes < minimum) {
        minimum = minutes;
      }
    }

    return minimum;
  }

  /// Calculates change from the first recorded day
  /// to the latest recorded day.
  static double calculateScreenTimeChange(
    List<Map<String, dynamic>> history,
  ) {
    if (history.length < 2) {
      return 0.0;
    }

    final first =
        (history.first['total_minutes'] as num?)?.toDouble() ?? 0.0;

    final last =
        (history.last['total_minutes'] as num?)?.toDouble() ?? 0.0;

    return last - first;
  }

  /// Gets risk level for each day.
  static List<String> getRiskTrend(
    List<Map<String, dynamic>> history,
  ) {
    final List<String> riskTrend = [];

    for (final day in history) {
      final risk =
          day['risk_level']?.toString().toUpperCase() ?? 'UNKNOWN';

      riskTrend.add(risk);
    }

    return riskTrend;
  }

  /// Converts minutes into readable format.
  static String formatMinutes(double minutes) {
    final int totalMinutes = minutes.round();

    final int hours = totalMinutes ~/ 60;
    final int remainingMinutes = totalMinutes % 60;

    if (hours == 0) {
      return '${remainingMinutes}m';
    }

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}m';
  }
}