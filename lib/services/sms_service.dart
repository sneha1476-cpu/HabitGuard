import 'package:flutter/services.dart';

class SmsService {
  static const MethodChannel _channel =
      MethodChannel('com.habitguard/usage');

  static Future<bool> hasSmsPermission() async {
    final bool? result =
        await _channel.invokeMethod<bool>(
      'hasSmsPermission',
    );

    return result ?? false;
  }

  static Future<bool> requestSmsPermission() async {
    final bool? result =
        await _channel.invokeMethod<bool>(
      'requestSmsPermission',
    );

    return result ?? false;
  }

  static Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      bool permission =
          await hasSmsPermission();

      if (!permission) {
        await requestSmsPermission();

        // Android permission dialog needs user interaction.
        // After granting, user should press Send again.
        permission =
            await hasSmsPermission();

        if (!permission) {
          throw Exception(
            'SMS permission is not granted.',
          );
        }
      }

      final bool? result =
          await _channel.invokeMethod<bool>(
        'sendSms',
        {
          'phoneNumber': phoneNumber,
          'message': message,
        },
      );

      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception(
        'SMS failed: ${e.message}',
      );
    } catch (e) {
      throw Exception(
        'SMS failed: $e',
      );
    }
  }
}