import 'history_service.dart';

class AnomalyService {
  /// Detects whether today's screen time is unusually high
  /// compared with the user's recent usage history.
  static Future<Map<String, dynamic>> detectTodayAnomaly() async {
    final history = await HistoryService.getLast7DaysUsage();

    if (history.length < 3) {
      return {
        'is_anomaly': false,
        'message': 'Not enough historical data for anomaly detection.',
        'today_minutes': 0.0,
        'average_minutes': 0.0,
        'difference_minutes': 0.0,
        'threshold_minutes': 0.0,
      };
    }

    final today = history.first;
    final todayDate = DateTime.now().toIso8601String().split('T')[0];

    if (today['date'] != todayDate) {
      return {
        'is_anomaly': false,
        'message': 'Today usage history is not available yet.',
        'today_minutes': 0.0,
        'average_minutes': 0.0,
        'difference_minutes': 0.0,
        'threshold_minutes': 0.0,
      };
    }

    final double todayMinutes =
        (today['total_minutes'] as num?)?.toDouble() ?? 0.0;

    double totalPreviousMinutes = 0.0;
    int previousDays = 0;

    for (int i = 1; i < history.length; i++) {
      final double minutes =
          (history[i]['total_minutes'] as num?)?.toDouble() ?? 0.0;

      totalPreviousMinutes += minutes;
      previousDays++;
    }

    if (previousDays == 0) {
      return {
        'is_anomaly': false,
        'message': 'Not enough historical data for anomaly detection.',
        'today_minutes': todayMinutes,
        'average_minutes': 0.0,
        'difference_minutes': 0.0,
        'threshold_minutes': 0.0,
      };
    }

    final double averageMinutes =
        totalPreviousMinutes / previousDays;

    // Anomaly threshold:
    // Today's usage is considered unusual if it is
    // more than 50% above the previous average.
    final double thresholdMinutes =
        averageMinutes * 1.5;

    final bool isAnomaly =
        todayMinutes > thresholdMinutes;

    final double differenceMinutes =
        todayMinutes - averageMinutes;

    String message;

    if (isAnomaly) {
      message =
          'Today\'s screen time is significantly higher than your recent average.';
    } else {
      message =
          'Today\'s screen time is within your recent usage pattern.';
    }

    return {
      'is_anomaly': isAnomaly,
      'message': message,
      'today_minutes': todayMinutes,
      'average_minutes': averageMinutes,
      'difference_minutes': differenceMinutes,
      'threshold_minutes': thresholdMinutes,
    };
  }

  /// Calculates how much today's usage differs from
  /// the recent average in percentage.
  static double calculateDeviationPercentage(
    double todayMinutes,
    double averageMinutes,
  ) {
    if (averageMinutes <= 0) {
      return 0.0;
    }

    return ((todayMinutes - averageMinutes) /
            averageMinutes) *
        100;
  }

  /// Formats minutes into a readable duration.
  static String formatMinutes(double minutes) {
    final int totalMinutes = minutes.round();

    final int hours = totalMinutes ~/ 60;
    final int remainingMinutes =
        totalMinutes % 60;

    if (hours == 0) {
      return '${remainingMinutes}m';
    }

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}m';
  }
}