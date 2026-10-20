import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/services/anomaly_service.dart';

void main() {
  group('AnomalyService.calculateDeviationPercentage', () {
    test('returns 50% when usage rises from 100 to 150 minutes', () {
      expect(
        AnomalyService.calculateDeviationPercentage(150, 100),
        50.0,
      );
    });

    test('returns -20% when usage falls from 100 to 80 minutes', () {
      expect(
        AnomalyService.calculateDeviationPercentage(80, 100),
        -20.0,
      );
    });

    test('returns zero when average usage is zero', () {
      expect(
        AnomalyService.calculateDeviationPercentage(150, 0),
        0.0,
      );
    });

    test('returns zero when average usage is negative', () {
      expect(
        AnomalyService.calculateDeviationPercentage(150, -10),
        0.0,
      );
    });
  });

  group('AnomalyService.formatMinutes', () {
    test('formats minutes without a full hour', () {
      expect(AnomalyService.formatMinutes(45), '45m');
    });

    test('formats hours and remaining minutes', () {
      expect(AnomalyService.formatMinutes(90), '1h 30m');
    });

    test('formats exact hours', () {
      expect(AnomalyService.formatMinutes(120), '2h');
    });
  });
}
