import 'package:flutter/material.dart';

import '../services/sms_service.dart';

class SmsTestScreen extends StatefulWidget {
  const SmsTestScreen({super.key});

  @override
  State<SmsTestScreen> createState() => _SmsTestScreenState();
}

class _SmsTestScreenState extends State<SmsTestScreen> {
  final TextEditingController phoneController =
      TextEditingController();

  bool isSending = false;

  Future<void> sendTestSms() async {
    final String phoneNumber =
        phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter guardian phone number'),
        ),
      );
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      await SmsService.sendSms(
        phoneNumber: phoneNumber,
        message:
            'HabitGuard Test Alert: This is a test guardian SMS.',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMS sent successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian SMS Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Guardian Phone Number',
                hintText: '+919876543210',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isSending ? null : sendTestSms,
                child: isSending
                    ? const CircularProgressIndicator()
                    : const Text('Send Test SMS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}