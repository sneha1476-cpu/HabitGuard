import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/services/intervention_service.dart';

void main() {
  group('InterventionService', () {
    List<Map<String, dynamic>> generate({
      String riskLevel = 'LOW',
      int totalScreenTime = 60,
      int lateNightUsage = 0,
      int numberOfSessions = 10,
      int socialMediaTime = 0,
      int entertainmentTime = 0,
      int gamingTime = 0,
      bool isAnomaly = false,
      double screenTimeChangePercentage = 0,
    }) {
      return InterventionService.generateInterventions(
        riskLevel: riskLevel,
        totalScreenTime: totalScreenTime,
        lateNightUsage: lateNightUsage,
        numberOfSessions: numberOfSessions,
        socialMediaTime: socialMediaTime,
        entertainmentTime: entertainmentTime,
        gamingTime: gamingTime,
        isAnomaly: isAnomaly,
        screenTimeChangePercentage: screenTimeChangePercentage,
      );
    }

    test('LOW risk with no concerns gives positive guidance', () {
      final results = generate();

      expect(results, isNotEmpty);
      expect(results.any((item) => item['type'] == 'positive'), isTrue);
    });

    test('HIGH risk gives an overall risk intervention', () {
      final results = generate(riskLevel: 'HIGH');

      expect(
        results.any((item) => item['type'] == 'overall_risk'),
        isTrue,
      );
    });

    test('Anomaly adds an unusual usage intervention', () {
      final results = generate(isAnomaly: true);

      expect(
        results.any((item) => item['type'] == 'anomaly'),
        isTrue,
      );
    });

    test('Screen-time increase of 25 percent triggers a trend intervention', () {
      final results = generate(screenTimeChangePercentage: 25);

      expect(
        results.any((item) => item['type'] == 'increasing_trend'),
        isTrue,
      );
    });

    test('Late-night usage of 30 minutes triggers guidance', () {
      final results = generate(lateNightUsage: 30);

      expect(
        results.any((item) => item['type'] == 'late_night'),
        isTrue,
      );
    });
  });
}
