class WellnessService {
  static int calculateScore({
    required int totalScreenTime,
    required int lateNightUsage,
    required int numberOfSessions,
    required int numberOfApps,
    required String riskLevel,
  }) {
    double score = 100;

    // 1. Screen Time
    if (totalScreenTime > 480) {
      score -= 30;
    } else if (totalScreenTime > 360) {
      score -= 20;
    } else if (totalScreenTime > 240) {
      score -= 10;
    } else if (totalScreenTime <= 120) {
      score += 0;
    }

    // 2. Late Night Usage
    if (lateNightUsage > 120) {
      score -= 20;
    } else if (lateNightUsage > 60) {
      score -= 12;
    } else if (lateNightUsage > 30) {
      score -= 6;
    }

    // 3. App Sessions
    if (numberOfSessions > 300) {
      score -= 15;
    } else if (numberOfSessions > 200) {
      score -= 10;
    } else if (numberOfSessions > 100) {
      score -= 5;
    }

    // 4. Number of Apps
    if (numberOfApps > 20) {
      score -= 10;
    } else if (numberOfApps > 15) {
      score -= 6;
    }

    // 5. ML Risk Level
    switch (riskLevel.toUpperCase()) {
      case 'CRITICAL':
        score -= 25;
        break;

      case 'HIGH':
        score -= 18;
        break;

      case 'MODERATE':
        score -= 10;
        break;

      case 'LOW':
        score -= 0;
        break;
    }

    // Keep score between 0 and 100
    score = score.clamp(0, 100);

    return score.round();
  }

  static String getLabel(int score) {
    if (score >= 80) {
      return 'Excellent';
    } else if (score >= 60) {
      return 'Good';
    } else if (score >= 40) {
      return 'Needs Attention';
    } else {
      return 'High Risk';
    }
  }

  static String getMessage(int score) {
    if (score >= 80) {
      return 'Your current digital usage pattern looks healthy.';
    } else if (score >= 60) {
      return 'Your digital wellbeing is generally good, with some areas to improve.';
    } else if (score >= 40) {
      return 'Some usage habits may need your attention.';
    } else {
      return 'Your current usage pattern indicates several areas that need attention.';
    }
  }
}