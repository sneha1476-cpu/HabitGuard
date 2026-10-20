import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Save or update the logged-in user's profile.
  Future<void> saveUserProfile(User user) async {
    final DocumentReference userRef =
        _firestore.collection('users').doc(user.uid);

    await userRef.set({
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Save guardian information.
  Future<void> saveGuardian({
    required String guardianName,
    required String guardianPhone,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not logged in.');

    final guardianRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('guardian')
        .doc('primary');

    final existingGuardian = await guardianRef.get();
    final existingData = existingGuardian.data();

    final bool alertsEnabled = !existingGuardian.exists
        ? true
        : (existingData?['enabled'] is bool
            ? existingData!['enabled'] as bool
            : true);

    await guardianRef.set({
      'name': guardianName,
      'phone': guardianPhone,
      'enabled': alertsEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Save FCM notification token.
  Future<void> saveFcmToken(String token) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not logged in.');

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get user profile.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(
      String uid) async {
    return _firestore.collection('users').doc(uid).get();
  }

  // Get guardian information.
  Future<DocumentSnapshot<Map<String, dynamic>>> getGuardian() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not logged in.');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('guardian')
        .doc('primary')
        .get();
  }

  // Update last guardian SMS alert time.
  Future<void> updateGuardianAlertTime(DateTime time) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not logged in.');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('guardian')
        .doc('primary')
        .update({
      'lastAlertAt': Timestamp.fromDate(time),
    });
  }

    // Update guardian alert policy fields without replacing guardian details.
  Future<void> updateGuardianAlertFields(
      Map<String, dynamic> fields) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not logged in.');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('guardian')
        .doc('primary')
        .update(fields);
  }
// Enable or disable automatic guardian SMS alerts.
  Future<void> setGuardianAlertsEnabled(bool enabled) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not logged in.');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('guardian')
        .doc('primary')
        .update({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}



