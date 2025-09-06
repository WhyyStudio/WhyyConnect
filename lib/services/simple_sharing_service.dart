import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleSharingService {
  static const String _sharingTag = 'SimpleSharingService';
  static const String _nearbyDevicesKey = 'nearby_devices';
  static const String _pendingSharesKey = 'pending_shares';
  
  static Timer? _discoveryTimer;
  static bool _isDiscovering = false;
  static List<Map<String, dynamic>> _nearbyDevices = [];
  static Function(Map<String, dynamic>)? _onDeviceFound;
  static Function(Map<String, dynamic>)? _onShareReceived;

  // Start discovering nearby devices
  static Future<void> startDiscovery(Function(Map<String, dynamic>) onDeviceFound) async {
    if (_isDiscovering) return;
    
    _isDiscovering = true;
    _onDeviceFound = onDeviceFound;
    
    // Simulate device discovery every 2 seconds
    _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _simulateDeviceDiscovery();
    });
    
    print('$_sharingTag: Started device discovery');
  }

  // Stop discovering devices
  static void stopDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _isDiscovering = false;
    _nearbyDevices.clear();
    print('$_sharingTag: Stopped device discovery');
  }

  // Simulate finding nearby devices
  static void _simulateDeviceDiscovery() {
    if (!_isDiscovering) return;
    
    // Simulate finding a device
    final device = {
      'id': 'device_${DateTime.now().millisecondsSinceEpoch}',
      'name': 'Nearby Device',
      'isAvailable': true,
      'lastSeen': DateTime.now().toIso8601String(),
    };
    
    _nearbyDevices.add(device);
    _onDeviceFound?.call(device);
    
    print('$_sharingTag: Found nearby device: ${device['id']}');
  }

  // Share card with a specific device
  static Future<bool> shareCardWithDevice(String deviceId, Map<String, dynamic> cardData) async {
    try {
      // Simulate sharing delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Save the shared card data locally
      final prefs = await SharedPreferences.getInstance();
      final pendingSharesJson = prefs.getStringList(_pendingSharesKey) ?? [];
      
      final shareData = {
        'deviceId': deviceId,
        'cardData': cardData,
        'sharedAt': DateTime.now().toIso8601String(),
        'isReceived': false,
      };
      
      pendingSharesJson.add(jsonEncode(shareData));
      await prefs.setStringList(_pendingSharesKey, pendingSharesJson);
      
      print('$_sharingTag: Card shared with device: $deviceId');
      return true;
    } catch (e) {
      print('$_sharingTag: Error sharing card: $e');
      return false;
    }
  }

  // Check for received cards
  static Future<Map<String, dynamic>?> checkForReceivedCards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingSharesJson = prefs.getStringList(_pendingSharesKey) ?? [];
      
      for (int i = 0; i < pendingSharesJson.length; i++) {
        final shareData = jsonDecode(pendingSharesJson[i]);
        
        // Simulate receiving a card (in real app, this would be from network)
        if (!shareData['isReceived']) {
          // Mark as received
          shareData['isReceived'] = true;
          pendingSharesJson[i] = jsonEncode(shareData);
          await prefs.setStringList(_pendingSharesKey, pendingSharesJson);
          
          print('$_sharingTag: Received card from device: ${shareData['deviceId']}');
          return shareData['cardData'];
        }
      }
      
      return null;
    } catch (e) {
      print('$_sharingTag: Error checking for received cards: $e');
      return null;
    }
  }

  // Get nearby devices
  static List<Map<String, dynamic>> getNearbyDevices() {
    return List.from(_nearbyDevices);
  }

  // Clear old shares
  static Future<void> clearOldShares() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingSharesJson = prefs.getStringList(_pendingSharesKey) ?? [];
      
      final now = DateTime.now();
      final validShares = pendingSharesJson.where((shareJson) {
        final shareData = jsonDecode(shareJson);
        final sharedAt = DateTime.parse(shareData['sharedAt']);
        return now.difference(sharedAt).inMinutes < 5; // Keep for 5 minutes
      }).toList();
      
      await prefs.setStringList(_pendingSharesKey, validShares);
      print('$_sharingTag: Cleared old shares');
    } catch (e) {
      print('$_sharingTag: Error clearing old shares: $e');
    }
  }
}
