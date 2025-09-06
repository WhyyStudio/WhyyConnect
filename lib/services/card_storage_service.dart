import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CardStorageService {
  static const String _physicalCardsKey = 'physical_cards';
  static const String _virtualCardsKey = 'virtual_cards';

  // Save a physical scanned card (from camera)
  static Future<void> savePhysicalCard(Map<String, dynamic> cardData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingCards = prefs.getStringList(_physicalCardsKey) ?? [];
      
      cardData['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      cardData['cardType'] = 'physical';
      cardData['createdAt'] = DateTime.now().toIso8601String();
      cardData['updatedAt'] = DateTime.now().toIso8601String();
      
      existingCards.add(jsonEncode(cardData));
      await prefs.setStringList(_physicalCardsKey, existingCards);
    } catch (e) {
      print('Error saving physical card: $e');
      throw Exception('Failed to save physical card data');
    }
  }

  // Save a virtual card (from QR code)
  static Future<void> saveVirtualCard(Map<String, dynamic> cardData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingCards = prefs.getStringList(_virtualCardsKey) ?? [];
      
      cardData['id'] = cardData['qrCardId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      cardData['cardType'] = 'virtual';
      cardData['createdAt'] = DateTime.now().toIso8601String();
      cardData['updatedAt'] = DateTime.now().toIso8601String();
      
      // Check if card already exists (by qrCardId)
      final existingIndex = existingCards.indexWhere((cardJson) {
        final card = jsonDecode(cardJson);
        return card['qrCardId'] == cardData['qrCardId'];
      });
      
      if (existingIndex != -1) {
        // Update existing card
        existingCards[existingIndex] = jsonEncode(cardData);
      } else {
        // Add new card
        existingCards.add(jsonEncode(cardData));
      }
      
      await prefs.setStringList(_virtualCardsKey, existingCards);
    } catch (e) {
      print('Error saving virtual card: $e');
      throw Exception('Failed to save virtual card data');
    }
  }

  // Get all physical cards
  static Future<List<Map<String, dynamic>>> getAllPhysicalCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = prefs.getStringList(_physicalCardsKey) ?? [];
      
      return cardsJson.map((cardJson) {
        return Map<String, dynamic>.from(jsonDecode(cardJson));
      }).toList();
    } catch (e) {
      print('Error loading physical cards: $e');
      return [];
    }
  }

  // Get all virtual cards
  static Future<List<Map<String, dynamic>>> getAllVirtualCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cardsJson = prefs.getStringList(_virtualCardsKey) ?? [];
      
      return cardsJson.map((cardJson) {
        return Map<String, dynamic>.from(jsonDecode(cardJson));
      }).toList();
    } catch (e) {
      print('Error loading virtual cards: $e');
      return [];
    }
  }

  // Get all cards (both physical and virtual)
  static Future<List<Map<String, dynamic>>> getAllCards() async {
    try {
      final physicalCards = await getAllPhysicalCards();
      final virtualCards = await getAllVirtualCards();
      
      return [...physicalCards, ...virtualCards];
    } catch (e) {
      print('Error loading all cards: $e');
      return [];
    }
  }

  // Get a specific card by ID
  static Future<Map<String, dynamic>?> getCard(String cardId) async {
    try {
      final physicalCards = await getAllPhysicalCards();
      final virtualCards = await getAllVirtualCards();
      
      final allCards = [...physicalCards, ...virtualCards];
      return allCards.firstWhere(
        (card) => card['id'] == cardId,
        orElse: () => {},
      );
    } catch (e) {
      print('Error getting card: $e');
      return null;
    }
  }

  // Delete a card
  static Future<void> deleteCard(String cardId, String cardType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = cardType == 'physical' ? _physicalCardsKey : _virtualCardsKey;
      final existingCards = prefs.getStringList(key) ?? [];
      
      final updatedCards = existingCards.where((cardJson) {
        final card = jsonDecode(cardJson);
        return card['id'] != cardId;
      }).toList();
      
      await prefs.setStringList(key, updatedCards);
    } catch (e) {
      print('Error deleting card: $e');
      throw Exception('Failed to delete card');
    }
  }

  // Update a virtual card (for synchronization)
  static Future<void> updateVirtualCard(String qrCardId, Map<String, dynamic> updatedData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingCards = prefs.getStringList(_virtualCardsKey) ?? [];
      
      final updatedCards = existingCards.map((cardJson) {
        final card = Map<String, dynamic>.from(jsonDecode(cardJson));
        if (card['qrCardId'] == qrCardId) {
          card.addAll(updatedData);
          card['updatedAt'] = DateTime.now().toIso8601String();
        }
        return jsonEncode(card);
      }).toList();
      
      await prefs.setStringList(_virtualCardsKey, updatedCards);
    } catch (e) {
      print('Error updating virtual card: $e');
      throw Exception('Failed to update virtual card');
    }
  }

  // Get cards count by type
  static Future<Map<String, int>> getCardsCount() async {
    try {
      final physicalCards = await getAllPhysicalCards();
      final virtualCards = await getAllVirtualCards();
      
      return {
        'physical': physicalCards.length,
        'virtual': virtualCards.length,
        'total': physicalCards.length + virtualCards.length,
      };
    } catch (e) {
      print('Error getting cards count: $e');
      return {'physical': 0, 'virtual': 0, 'total': 0};
    }
  }

  // Search cards by text
  static Future<List<Map<String, dynamic>>> searchCards(String query) async {
    try {
      final allCards = await getAllCards();
      final lowercaseQuery = query.toLowerCase();
      
      return allCards.where((card) {
        final extractedData = card['extractedData'] ?? {};
        final name = (extractedData['name'] ?? '').toLowerCase();
        final company = (extractedData['company'] ?? '').toLowerCase();
        final email = (extractedData['email'] ?? '').toLowerCase();
        final phone = (extractedData['phone'] ?? '').toLowerCase();
        final position = (extractedData['position'] ?? '').toLowerCase();
        
        return name.contains(lowercaseQuery) ||
               company.contains(lowercaseQuery) ||
               email.contains(lowercaseQuery) ||
               phone.contains(lowercaseQuery) ||
               position.contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Error searching cards: $e');
      return [];
    }
  }

  // Clear all cards
  static Future<void> clearAllCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_physicalCardsKey);
      await prefs.remove(_virtualCardsKey);
    } catch (e) {
      print('Error clearing cards: $e');
      throw Exception('Failed to clear cards');
    }
  }

  // Check if virtual card exists by QR card ID
  static Future<bool> virtualCardExists(String qrCardId) async {
    try {
      final virtualCards = await getAllVirtualCards();
      return virtualCards.any((card) => card['qrCardId'] == qrCardId);
    } catch (e) {
      print('Error checking virtual card existence: $e');
      return false;
    }
  }
}
