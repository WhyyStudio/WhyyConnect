import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceSharingService {
  static const String _sharingTag = 'DeviceSharingService';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a unique sharing code
  static String _generateSharingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }

  // Share card with another device using a unique code
  static Future<String> shareCardWithCode(Map<String, dynamic> cardData) async {
    try {
      final sharingCode = _generateSharingCode();
      final currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create sharing session in Firestore
      await _firestore.collection('card_sharing').doc(sharingCode).set({
        'cardData': cardData,
        'sharedBy': currentUser.uid,
        'sharedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
      });

      print('$_sharingTag: Card shared with code: $sharingCode');
      return sharingCode;
    } catch (e) {
      print('$_sharingTag: Error sharing card: $e');
      rethrow;
    }
  }

  // Receive card using sharing code
  static Future<Map<String, dynamic>?> receiveCardWithCode(String sharingCode) async {
    try {
      final currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get sharing session from Firestore
      final sharingDoc = await _firestore.collection('card_sharing').doc(sharingCode).get();
      
      if (!sharingDoc.exists) {
        throw Exception('Invalid sharing code');
      }

      final sharingData = sharingDoc.data()!;
      
      // Check if sharing session is still active
      final sharedAt = sharingData['sharedAt'] as Timestamp;
      final expiresAt = sharedAt.toDate().add(const Duration(minutes: 5));
      
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('Sharing code has expired');
      }

      // Check if user is trying to receive their own card
      if (sharingData['sharedBy'] == currentUser.uid) {
        throw Exception('Cannot receive your own card');
      }

      // Mark sharing session as received
      await _firestore.collection('card_sharing').doc(sharingCode).update({
        'receivedBy': currentUser.uid,
        'receivedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });

      final cardData = Map<String, dynamic>.from(sharingData['cardData']);
      
      print('$_sharingTag: Card received with code: $sharingCode');
      return cardData;
    } catch (e) {
      print('$_sharingTag: Error receiving card: $e');
      rethrow;
    }
  }

  // Clean up expired sharing sessions
  static Future<void> cleanupExpiredSessions() async {
    try {
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      
      final expiredSessions = await _firestore
          .collection('card_sharing')
          .where('sharedAt', isLessThan: Timestamp.fromDate(fiveMinutesAgo))
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in expiredSessions.docs) {
        await doc.reference.delete();
      }

      print('$_sharingTag: Cleaned up ${expiredSessions.docs.length} expired sessions');
    } catch (e) {
      print('$_sharingTag: Error cleaning up sessions: $e');
    }
  }

  // Get sharing statistics
  static Future<Map<String, int>> getSharingStats() async {
    try {
      final currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        return {'shared': 0, 'received': 0};
      }

      final sharedCount = await _firestore
          .collection('card_sharing')
          .where('sharedBy', isEqualTo: currentUser.uid)
          .count()
          .get();

      final receivedCount = await _firestore
          .collection('card_sharing')
          .where('receivedBy', isEqualTo: currentUser.uid)
          .count()
          .get();

      return {
        'shared': sharedCount.count ?? 0,
        'received': receivedCount.count ?? 0,
      };
    } catch (e) {
      print('$_sharingTag: Error getting sharing stats: $e');
      return {'shared': 0, 'received': 0};
    }
  }
}
