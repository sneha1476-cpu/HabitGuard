class InterventionService {
  /// Generates personalized digital-wellbeing interventions
  /// based on the user's current behavior.
  ///
  /// This is NOT a medical diagnosis system.
  /// Recommendations are intended for digital wellbeing only.

  static List<Map<String, dynamic>> generateInterventions({
    required String riskLevel,
    required int totalScreenTime,
    required int lateNightUsage,
    required int numberOfSessions,
    required int socialMediaTime,
    required int entertainmentTime,
    required int gamingTime,
    required bool isAnomaly,
    required double screenTimeChangePercentage,
  }) {
    final List<Map<String, dynamic>> interventions = [];

    // ---------------------------------------------------------
    // 1. Late-night usage
    // ---------------------------------------------------------
    if (lateNightUsage >= 30) {
      interventions.add({
        'type': 'late_night',
        'priority': 'high',
        'title': 'Reduce late-night phone usage',
        'message':
            'Your late-night phone usage is relatively high. '
            'Consider reducing screen exposure before bedtime.',
        'action': 'Try keeping your phone away from your bed at night.',
      });
    }

    // ---------------------------------------------------------
    // 2. Frequent app sessions
    // ---------------------------------------------------------
    if (numberOfSessions >= 40) {
      interventions.add({
        'type': 'frequent_sessions',
        'priority': 'medium',
        'title': 'Reduce frequent phone checking',
        'message':
            'You are opening apps frequently today. '
            'Try grouping non-essential phone checks together.',
        'action': 'Check non-essential apps at planned times.',
      });
    }

    // ---------------------------------------------------------
    // 3. High social media usage
    // ---------------------------------------------------------
    if (socialMediaTime >= 120) {
      interventions.add({
        'type': 'social_media',
        'priority': 'medium',
        'title': 'Take a social media break',
        'message':
            'Social media represents a significant part of your usage today.',
        'action':
            'Consider taking a short break from social media and doing an offline activity.',
      });
    }

    // ---------------------------------------------------------
    // 4. High entertainment usage
    // ---------------------------------------------------------
    if (entertainmentTime >= 120) {
      interventions.add({
        'type': 'entertainment',
        'priority': 'medium',
        'title': 'Balance entertainment time',
        'message':
            'Entertainment apps are taking a significant amount of your screen time.',
        'action':
            'Try setting a planned entertainment window instead of continuous usage.',
      });
    }

    // ---------------------------------------------------------
    // 5. High gaming usage
    // ---------------------------------------------------------
    if (gamingTime >= 120) {
      interventions.add({
        'type': 'gaming',
        'priority': 'medium',
        'title': 'Plan your gaming time',
        'message':
            'Gaming represents a large portion of your current usage.',
        'action':
            'Consider setting a planned gaming window and taking regular breaks.',
      });
    }

    // ---------------------------------------------------------
    // 6. Increasing screen-time trend
    // ---------------------------------------------------------
    if (screenTimeChangePercentage >= 25) {
      interventions.add({
        'type': 'increasing_trend',
        'priority': 'high',
        'title': 'Screen time is increasing',
        'message':
            'Your recent screen-time trend is increasing compared with previous usage.',
        'action':
            'Consider scheduling short digital breaks during the day.',
      });
    }

    // ---------------------------------------------------------
    // 7. Behavioral anomaly
    // ---------------------------------------------------------
    if (isAnomaly) {
      interventions.add({
        'type': 'anomaly',
        'priority': 'high',
        'title': 'Unusual usage detected',
        'message':
            "Today's screen-time pattern is noticeably different from your recent usage.",
        'action':
            "Review which apps contributed most to today's increase.",
      });
    }

    // ---------------------------------------------------------
    // 8. High / Critical overall risk
    // ---------------------------------------------------------
    if (riskLevel == 'HIGH' || riskLevel == 'CRITICAL') {
      interventions.add({
        'type': 'overall_risk',
        'priority': 'high',
        'title': 'Consider a digital break',
        'message':
            'Several usage patterns indicate that taking a digital break may be useful.',
        'action':
            'Try taking a short phone-free break and return to essential apps afterward.',
      });
    }

    // ---------------------------------------------------------
    // 9. Moderate risk
    // ---------------------------------------------------------
    if (riskLevel == 'MODERATE' && interventions.isEmpty) {
      interventions.add({
        'type': 'moderate_risk',
        'priority': 'low',
        'title': 'Maintain balanced usage',
        'message':
            'Your current usage pattern shows some areas that could be improved.',
        'action':
            'Continue monitoring your screen time and take regular digital breaks.',
      });
    }

    // ---------------------------------------------------------
    // 10. LOW risk + no specific concern
    // ---------------------------------------------------------
    if (riskLevel == 'LOW' && interventions.isEmpty) {
      interventions.add({
        'type': 'positive',
        'priority': 'low',
        'title': 'Keep your usage balanced',
        'message':
            'Your current usage pattern appears relatively balanced.',
        'action':
            'Continue maintaining healthy digital-wellbeing habits.',
      });
    }

    return interventions;
  }
}