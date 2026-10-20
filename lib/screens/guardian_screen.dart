import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../services/sms_service.dart';

class GuardianScreen extends StatefulWidget {
const GuardianScreen({super.key});

@override
State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

final TextEditingController _nameController =
TextEditingController();

final TextEditingController _phoneController =
TextEditingController();

final FirestoreService _firestoreService = FirestoreService();

bool _isLoadingGuardian = true;
bool _isSaving = false;
bool _isSendingTestSms = false;
bool _guardianAlertsEnabled = true;
bool _isUpdatingAlertSetting = false;

@override
void initState() {
super.initState();
_loadGuardian();
}

@override
void dispose() {
_nameController.dispose();
_phoneController.dispose();
super.dispose();
}

void _showMessage(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(message)),
);

}

Future<void> _loadGuardian() async {
try {
final guardian = await _firestoreService.getGuardian();

  if (!mounted) return;

  if (guardian.exists) {
    final data = guardian.data();

    _nameController.text = data?['name']?.toString() ?? '';
    _phoneController.text = data?['phone']?.toString() ?? '';
    _guardianAlertsEnabled = data?['enabled'] == true;
  }
} catch (e) {
  _showMessage(
    'Could not load guardian details. Please check your login and internet connection.',
  );
} finally {
  if (mounted) {
    setState(() {
      _isLoadingGuardian = false;
    });
  }
}

}

Future<void> _setGuardianAlerts(bool enabled) async {
  if (_isUpdatingAlertSetting) return;

  setState(() {
    _isUpdatingAlertSetting = true;
  });

  try {
    await _firestoreService.setGuardianAlertsEnabled(enabled);

    if (!mounted) return;

    setState(() {
      _guardianAlertsEnabled = enabled;
    });

    _showMessage(
      enabled
          ? 'Automatic guardian alerts enabled.'
          : 'Automatic guardian alerts disabled.',
    );
  } catch (e) {
    _showMessage('Could not update alert setting. Please try again.');
  } finally {
    if (mounted) {
      setState(() {
        _isUpdatingAlertSetting = false;
      });
    }
  }
}
String? _validateName(String? value) {
if (value == null || value.trim().isEmpty) {
return 'Please enter the guardian name.';
}

if (value.trim().length < 2) {
  return 'Name must contain at least 2 characters.';
}

return null;

}

String? _validatePhone(String? value) {
final phone = value?.trim() ?? '';

// Accept a 10-digit Indian mobile number, or a country-code
// number containing 10 to 13 digits.
final digits = phone.replaceAll(RegExp(r'[\s+\-()]'), '');

if (!RegExp(r'^\d{10,13}$').hasMatch(digits)) {
  return 'Enter a valid phone number (10–13 digits).';
}

return null;

}

Future<void> _saveGuardian() async {
if (!_formKey.currentState!.validate()) return;

FocusScope.of(context).unfocus();

setState(() {
  _isSaving = true;
});

try {
  await _firestoreService.saveGuardian(
    guardianName: _nameController.text.trim(),
    guardianPhone: _phoneController.text.trim(),
  );

  _showMessage('Guardian details saved successfully.');
} catch (e) {
  _showMessage(
    'Could not save guardian details. Check that you are logged in and Firebase is configured.',
  );
} finally {
  if (mounted) {
    setState(() {
      _isSaving = false;
    });
  }
}

}

Future<void> _sendTestSms() async {
if (!_formKey.currentState!.validate()) return;

FocusScope.of(context).unfocus();

final phoneNumber = _phoneController.text.trim();

final confirmed = await showDialog<bool>(
  context: context,
  builder: (dialogContext) {
    return AlertDialog(
      title: const Text('Send test SMS?'),
      content: Text(
        'A real SMS will be sent to $phoneNumber. '
        'Your mobile operator may charge for this message. '
        'Continue only if the guardian has agreed to receive it.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(false);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(true);
          },
          child: const Text('Send SMS'),
        ),
      ],
    );
  },
);

if (confirmed != true || !mounted) return;

setState(() {
  _isSendingTestSms = true;
});

try {
  final sent = await SmsService.sendSms(
    phoneNumber: phoneNumber,
    message:
        'HabitGuard test message: You have been added as a '
        'guardian contact by the app user.',
  );

  if (sent) {
    _showMessage('Test SMS was sent successfully.');
  } else {
    _showMessage(
      'SMS was not confirmed as sent. Check your device and SMS permission.',
    );
  }
} catch (e) {
  _showMessage(
    'Could not send SMS. Check SMS permission and device support.',
  );
} finally {
  if (mounted) {
    setState(() {
      _isSendingTestSms = false;
    });
  }
}

}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Guardian Settings'),
centerTitle: true,
),
body: _isLoadingGuardian
? const Center(
child: CircularProgressIndicator(),
)
: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.all(20),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const SizedBox(height: 8),
const Icon(
Icons.shield_outlined,
size: 72,
),
const SizedBox(height: 16),
Text(
'Trusted Guardian',
textAlign: TextAlign.center,
style: Theme.of(context)
.textTheme
.headlineSmall,
),
const SizedBox(height: 12),
Text(
'Add a trusted person who agrees to receive '
'digital wellbeing alerts if your risk reaches '
'HIGH or CRITICAL.',
textAlign: TextAlign.center,
style: Theme.of(context)
.textTheme
.bodyMedium,
),
const SizedBox(height: 28),
TextFormField(
controller: _nameController,
textCapitalization: TextCapitalization.words,
textInputAction: TextInputAction.next,
decoration: const InputDecoration(
labelText: 'Guardian name',
hintText: 'Enter full name',
prefixIcon: Icon(Icons.person_outline),
border: OutlineInputBorder(),
),
validator: _validateName,
),
const SizedBox(height: 18),
TextFormField(
controller: _phoneController,
keyboardType: TextInputType.phone,
textInputAction: TextInputAction.done,
decoration: const InputDecoration(
labelText: 'Guardian phone number',
hintText: '10-digit mobile number',
prefixIcon: Icon(Icons.phone_outlined),
border: OutlineInputBorder(),
),
validator: _validatePhone,
),
const SizedBox(height: 24),
FilledButton.icon(
onPressed: _isSaving ? null : _saveGuardian,
icon: _isSaving
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
: const Icon(Icons.save_outlined),
label: Text(
_isSaving
? 'Saving...'
: 'Save Guardian Details',
),
),
const SizedBox(height: 14),
Card(
  child: SwitchListTile(
    secondary: const Icon(Icons.notifications_active_outlined),
    title: const Text('Automatic Guardian Alerts'),
    subtitle: Text(
      _guardianAlertsEnabled
          ? 'HIGH/CRITICAL risk alerts are enabled'
          : 'Automatic risk alerts are disabled',
    ),
    value: _guardianAlertsEnabled,
    onChanged: _isUpdatingAlertSetting
        ? null
        : _setGuardianAlerts,
  ),
),
const SizedBox(height: 14),
OutlinedButton.icon(
onPressed:
_isSendingTestSms ? null : _sendTestSms,
icon: _isSendingTestSms
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
: const Icon(Icons.sms_outlined),
label: Text(
_isSendingTestSms
? 'Sending SMS...'
: 'Send Test SMS',
),
),
const SizedBox(height: 20),
const Card(
child: Padding(
padding: EdgeInsets.all(14),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(Icons.info_outline),
SizedBox(width: 12),
Expanded(
child: Text(
'Save the guardian details first. '
'The test button sends a real SMS after '
'confirmation. Automatic alerts depend '
'on the existing HabitGuard alert service, '
'device permissions, and app configuration.',
),
),
],
),
),
),
],
),
),
),
),
);
}
}





