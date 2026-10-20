import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firestore_service.dart';
import 'sms_service.dart';

class GuardianAlertService {
  static const Duration highRiskDelay = Duration(hours: 1);
  static const Duration criticalCooldown = Duration(hours: 6);

  // Prevent overlapping dashboard refreshes from submitting duplicate SMS
  // requests within this running app process.
  static bool _processing = false;

  final FirestoreService _firestoreService = FirestoreService();

  Future<bool> shouldSendAlert({required String riskLevel}) async {
    final risk = riskLevel.toUpperCase();
    if (!{'MODERATE', 'HIGH', 'CRITICAL'}.contains(risk)) return false;

    try {
      final snapshot = await _firestoreService.getGuardian();
      final data = snapshot.data();
      return snapshot.exists &&
          data != null &&
          data['enabled'] == true &&
          (data['phone'] ?? '').toString().trim().isNotEmpty;
    } catch (e) {
      debugPrint('shouldSendAlert ERROR: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> createAlert({
    required String riskLevel,
    required int totalScreenTime,
    required double riskConfidence,
  }) async {
    final snapshot = await _firestoreService.getGuardian();
    final data = snapshot.data() ?? {};

    return {
      'guardianName': (data['name'] ?? 'Guardian').toString(),
      'guardianPhone': (data['phone'] ?? '').toString(),
      'riskLevel': riskLevel,
      'totalScreenTime': totalScreenTime,
      'riskConfidence': riskConfidence,
      'message':
          'HabitGuard Alert: Risk level is $riskLevel. '
          'Today screen time is $totalScreenTime minutes. '
          'Risk confidence is ${(riskConfidence * 100).toStringAsFixed(1)}%. '
          'Please check in with the user if needed.',
    };
  }

  /// Process every fresh ML prediction. This method never schedules a
  /// background task: HIGH is sent only when a later prediction, at least
  /// one hour after first detection, is still HIGH.
  Future<bool> processRiskLevel({
    required String riskLevel,
    required int totalScreenTime,
    required double riskConfidence,
  }) async {
    final risk = riskLevel.toUpperCase();
    if (!{'LOW', 'MODERATE', 'HIGH', 'CRITICAL'}.contains(risk)) return false;
    if (_processing) {
      debugPrint('Guardian alert skipped: another alert check is running');
      return false;
    }

    _processing = true;
    try {
      final snapshot = await _firestoreService.getGuardian();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        debugPrint('Guardian alert skipped: guardian document missing');
        return false;
      }
      if (data['enabled'] != true) {
        debugPrint('Guardian alert skipped: alerts disabled');
        return false;
      }

      final phone = (data['phone'] ?? '').toString().trim();
      if (phone.isEmpty) {
        debugPrint('Guardian alert skipped: phone number missing');
        return false;
      }

      final now = DateTime.now();

      if (risk == 'LOW' || risk == 'MODERATE' || risk == 'CRITICAL') {
        // A non-HIGH prediction ends the current continuous HIGH episode.
        await _firestoreService.updateGuardianAlertFields({
          'highRiskFirstDetectedAt': FieldValue.delete(),
          'highAlertSent': false,
          'highAlertSentAt': FieldValue.delete(),
        });
      }

      if (risk == 'LOW') {
        debugPrint('Guardian alert: LOW risk; no SMS required');
        return false;
      }

      if (risk == 'MODERATE') {
        if (data['moderateAlertSent'] == true) {
          debugPrint('Guardian alert skipped: one-time MODERATE alert already sent');
          return false;
        }

        final sent = await _submitSms(
          phone: phone,
          risk: risk,
          totalScreenTime: totalScreenTime,
          riskConfidence: riskConfidence,
        );
        if (sent) {
          await _firestoreService.updateGuardianAlertFields({
            'moderateAlertSent': true,
            'moderateAlertSentAt': Timestamp.fromDate(now),
            'lastAlertAt': Timestamp.fromDate(now),
          });
        }
        return sent;
      }

      if (risk == 'HIGH') {
        final firstDetected = data['highRiskFirstDetectedAt'];
        if (firstDetected is! Timestamp) {
          await _firestoreService.updateGuardianAlertFields({
            'highRiskFirstDetectedAt': Timestamp.fromDate(now),
            'highAlertSent': false,
          });
          debugPrint('Guardian HIGH detected; one-hour waiting period started');
          return false;
        }

        if (data['highAlertSent'] == true) {
          debugPrint('Guardian HIGH alert already sent for this HIGH episode');
          return false;
        }

        final elapsed = now.difference(firstDetected.toDate());
        if (elapsed < highRiskDelay) {
          debugPrint('Guardian HIGH alert waiting: ${elapsed.inMinutes} of 60 minutes elapsed');
          return false;
        }

        final sent = await _submitSms(
          phone: phone,
          risk: risk,
          totalScreenTime: totalScreenTime,
          riskConfidence: riskConfidence,
        );
        if (sent) {
          await _firestoreService.updateGuardianAlertFields({
            'highAlertSent': true,
            'highAlertSentAt': Timestamp.fromDate(now),
            'lastAlertAt': Timestamp.fromDate(now),
          });
        }
        return sent;
      }

      // CRITICAL remains immediate, with its own six-hour cooldown.
      final lastCritical = data['lastCriticalAlertAt'];
      if (lastCritical is Timestamp &&
          now.difference(lastCritical.toDate()) < criticalCooldown) {
        debugPrint('Guardian CRITICAL alert skipped: six-hour cooldown active');
        return false;
      }

      final sent = await _submitSms(
        phone: phone,
        risk: risk,
        totalScreenTime: totalScreenTime,
        riskConfidence: riskConfidence,
      );
      if (sent) {
        await _firestoreService.updateGuardianAlertFields({
          'lastCriticalAlertAt': Timestamp.fromDate(now),
          'lastAlertAt': Timestamp.fromDate(now),
        });
      }
      return sent;
    } catch (e, stackTrace) {
      debugPrint('Guardian alert ERROR: $e');
      debugPrint('$stackTrace');
      return false;
    } finally {
      _processing = false;
    }
  }

  // Keep the old public method name compatible with any existing call sites.
  Future<bool> sendGuardianSms({
    required String riskLevel,
    required int totalScreenTime,
    required double riskConfidence,
  }) {
    return processRiskLevel(
      riskLevel: riskLevel,
      totalScreenTime: totalScreenTime,
      riskConfidence: riskConfidence,
    );
  }

  Future<bool> _submitSms({
    required String phone,
    required String risk,
    required int totalScreenTime,
    required double riskConfidence,
  }) async {
    final message =
        'HabitGuard Alert: Risk level is $risk. '
        'Today screen time is $totalScreenTime minutes. '
        'Risk confidence is ${(riskConfidence * 100).toStringAsFixed(1)}%. '
        'Please check in with the user if needed.';

    final submitted = await SmsService.sendSms(
      phoneNumber: phone,
      message: message,
    );
    if (!submitted) {
      debugPrint('Guardian SMS was not accepted by Android SMS service');
      return false;
    }

    debugPrint('Guardian SMS submitted to Android SMS service');
    return true;
  }

  Future<void> markAlertSent() async {
    await _firestoreService.updateGuardianAlertTime(DateTime.now());
  }
}
