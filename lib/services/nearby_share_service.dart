import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class NearbyShareService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _sharingCollection = 'card_sharing';
  static const String _receivedCardsCollection = 'received_cards';

  // Generate a unique PIN for card sharing
  static Future<String> generateSharingPIN(Map<String, dynamic> cardData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate a 6-digit PIN
      final pin = _generatePIN();
      
      // Create sharing document with card data
      final sharingData = {
        'pin': pin,
        'cardData': cardData,
        'sharedBy': user.uid,
        'sharedByName': user.displayName ?? 'Unknown',
        'sharedByEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': FieldValue.serverTimestamp(), // Will be set to 1 hour from now
        'isActive': true,
        'receivedBy': <String>[], // Track who received this card
      };

      // Set expiration time (1 hour from now)
      final expirationTime = DateTime.now().add(const Duration(hours: 1));
      sharingData['expiresAt'] = Timestamp.fromDate(expirationTime);

      // Save to Firestore
      await _firestore
          .collection(_sharingCollection)
          .doc(pin)
          .set(sharingData);

      // Clean up expired sharing documents
      _cleanupExpiredShares();

      return pin;
    } catch (e) {
      throw Exception('Failed to generate sharing PIN: $e');
    }
  }

  // Receive a card using PIN
  static Future<Map<String, dynamic>?> receiveCardByPIN(String pin) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get sharing document
      final doc = await _firestore
          .collection(_sharingCollection)
          .doc(pin)
          .get();

      if (!doc.exists) {
        throw Exception('Invalid PIN or card no longer available');
      }

      final sharingData = doc.data()!;
      
      // Check if PIN is still active
      if (!sharingData['isActive']) {
        throw Exception('This sharing session has expired');
      }

      // Check expiration
      final expiresAt = (sharingData['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('This sharing session has expired');
      }

      // Check if user already received this card
      final receivedBy = List<String>.from(sharingData['receivedBy'] ?? []);
      if (receivedBy.contains(user.uid)) {
        throw Exception('You have already received this card');
      }

      // Get card data
      final cardData = Map<String, dynamic>.from(sharingData['cardData']);
      
      // Add sharing metadata
      cardData['sharedBy'] = sharingData['sharedBy'];
      cardData['sharedByName'] = sharingData['sharedByName'];
      cardData['sharedByEmail'] = sharingData['sharedByEmail'];
      cardData['receivedAt'] = FieldValue.serverTimestamp();
      cardData['sharingPIN'] = pin;
      cardData['cardType'] = 'shared'; // Mark as shared card
      cardData['originalCardId'] = cardData['cardId']; // Keep reference to original

      // Save received card to user's collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(_receivedCardsCollection)
          .add(cardData);

      // Update sharing document to track who received it
      await _firestore
          .collection(_sharingCollection)
          .doc(pin)
          .update({
        'receivedBy': FieldValue.arrayUnion([user.uid]),
        'lastReceivedAt': FieldValue.serverTimestamp(),
      });

      return cardData;
    } catch (e) {
      throw Exception('Failed to receive card: $e');
    }
  }

  // Get all cards shared by current user
  static Future<List<Map<String, dynamic>>> getSharedCards() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final query = await _firestore
          .collection(_sharingCollection)
          .where('sharedBy', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get shared cards: $e');
    }
  }

  // Get all cards received by current user
  static Future<List<Map<String, dynamic>>> getReceivedCards() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(_receivedCardsCollection)
          .orderBy('receivedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get received cards: $e');
    }
  }

  // Cancel a sharing session
  static Future<void> cancelSharing(String pin) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection(_sharingCollection)
          .doc(pin)
          .update({
        'isActive': false,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel sharing: $e');
    }
  }

  // Update shared card when original card is edited
  static Future<void> updateSharedCard(String originalCardId, Map<String, dynamic> updatedCardData) async {
    try {
      // Find all sharing documents that contain this card
      final query = await _firestore
          .collection(_sharingCollection)
          .where('cardData.cardId', isEqualTo: originalCardId)
          .where('isActive', isEqualTo: true)
          .get();

      // Update each sharing document
      for (final doc in query.docs) {
        await doc.reference.update({
          'cardData': updatedCardData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update all received cards with the same original card ID
      final usersQuery = await _firestore
          .collectionGroup(_receivedCardsCollection)
          .where('originalCardId', isEqualTo: originalCardId)
          .get();

      for (final doc in usersQuery.docs) {
        await doc.reference.update({
          ...updatedCardData,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update shared card: $e');
    }
  }

  // Delete shared card when original card is deleted
  static Future<void> deleteSharedCard(String originalCardId) async {
    try {
      // Deactivate all sharing documents for this card
      final query = await _firestore
          .collection(_sharingCollection)
          .where('cardData.cardId', isEqualTo: originalCardId)
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({
          'isActive': false,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }

      // Try to mark received cards as deleted (this may fail due to permissions)
      try {
        final usersQuery = await _firestore
            .collectionGroup(_receivedCardsCollection)
            .where('originalCardId', isEqualTo: originalCardId)
            .get();

        for (final doc in usersQuery.docs) {
          try {
            await doc.reference.update({
              'isDeleted': true,
              'deletedAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            // Individual document update failed, continue with others
            print('Failed to update received card ${doc.id}: $e');
          }
        }
      } catch (e) {
        // Collection group query failed, but that's okay
        // The main deletion (sharing documents) succeeded
        print('Failed to update received cards: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete shared card: $e');
    }
  }

  // Generate a 6-digit PIN
  static String _generatePIN() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Clean up expired sharing documents
  static Future<void> _cleanupExpiredShares() async {
    try {
      final now = Timestamp.now();
      final query = await _firestore
          .collection(_sharingCollection)
          .where('expiresAt', isLessThan: now)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'expiredAt': FieldValue.serverTimestamp(),
        });
      }
      
      if (query.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      // Don't throw error for cleanup failures
      print('Cleanup error: $e');
    }
  }

  // Get sharing statistics
  static Future<Map<String, int>> getSharingStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final sharedQuery = await _firestore
          .collection(_sharingCollection)
          .where('sharedBy', isEqualTo: user.uid)
          .get();

      final receivedQuery = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(_receivedCardsCollection)
          .get();

      return {
        'shared': sharedQuery.docs.length,
        'received': receivedQuery.docs.length,
        'totalShares': sharedQuery.docs.fold(0, (sum, doc) {
          final receivedBy = List<String>.from(doc.data()['receivedBy'] ?? []);
          return sum + receivedBy.length;
        }),
      };
    } catch (e) {
      throw Exception('Failed to get sharing stats: $e');
    }
  }
}
