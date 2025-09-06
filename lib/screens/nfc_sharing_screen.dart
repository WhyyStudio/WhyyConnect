import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/nfc_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class NFCSharingScreen extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final bool isSharing; // true for sharing, false for receiving

  const NFCSharingScreen({
    super.key,
    required this.cardData,
    required this.isSharing,
  });

  @override
  State<NFCSharingScreen> createState() => _NFCSharingScreenState();
}

class _NFCSharingScreenState extends State<NFCSharingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _successController;
  late AnimationController _deviceController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _successAnimation;
  late Animation<Offset> _deviceAnimation;
  
  bool _isNFCActive = false;
  bool _isSuccess = false;
  bool _isError = false;
  String _statusMessage = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startNFCProcess();
  }

  void _initializeAnimations() {
    // Pulse animation for NFC detection
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Wave animation for device connection
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Success animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Device animation
    _deviceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _deviceAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _deviceController,
      curve: Curves.easeOutBack,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    _deviceController.forward();
  }

  Future<void> _startNFCProcess() async {
    try {
      // Check NFC availability
      if (!await NFCService.isNFCAvailable()) {
        setState(() {
          _isError = true;
          _errorMessage = 'NFC is not available on this device';
        });
        return;
      }

      setState(() {
        _isNFCActive = true;
        _statusMessage = widget.isSharing 
            ? 'Hold your device near another device to share'
            : 'Hold your device near a device to receive';
      });

      if (widget.isSharing) {
        await _shareCard();
      } else {
        await _receiveCard();
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _shareCard() async {
    try {
      await NFCService.shareCardViaNFC(widget.cardData);
      _showSuccess();
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to share card: $e';
      });
    }
  }

  Future<void> _receiveCard() async {
    try {
      final receivedCard = await NFCService.receiveCardViaNFC();
      if (receivedCard != null) {
        _showSuccess();
        // Here you would typically save the received card
        print('Received card: $receivedCard');
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'No card data received';
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to receive card: $e';
      });
    }
  }

  void _showSuccess() {
    setState(() {
      _isSuccess = true;
      _statusMessage = widget.isSharing 
          ? 'Card shared successfully!'
          : 'Card received successfully!';
    });
    _successController.forward();
    
    // Navigate back after success
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, _isSuccess);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _successController.dispose();
    _deviceController.dispose();
    NFCService.stopNFCSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Main content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // NFC Animation
                    _buildNFCAnimation(),
                    
                    const SizedBox(height: 40),
                    
                    // Status message
                    _buildStatusMessage(),
                    
                    const SizedBox(height: 60),
                    
                    // Device animation
                    _buildDeviceAnimation(),
                  ],
                ),
              ),
            ),
            
            // Bottom section
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            widget.isSharing ? 'Share Card' : 'Receive Card',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNFCAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isSuccess ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _isSuccess 
                  ? const LinearGradient(
                      colors: [Color(0xFF34C759), Color(0xFF30D158)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                    ),
              boxShadow: [
                BoxShadow(
                  color: (_isSuccess ? const Color(0xFF34C759) : const Color(0xFF007AFF))
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _isSuccess ? Icons.check : Icons.nfc,
              color: Colors.white,
              size: 60,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage() {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isSuccess ? _successAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: _isError 
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.1)
                  : _isSuccess
                      ? const Color(0xFF34C759).withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isError 
                    ? const Color(0xFFFF3B30)
                    : _isSuccess
                        ? const Color(0xFF34C759)
                        : Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              _isError ? _errorMessage : _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isError 
                    ? const Color(0xFFFF3B30)
                    : _isSuccess
                        ? const Color(0xFF34C759)
                        : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceAnimation() {
    return SlideTransition(
      position: _deviceAnimation,
      child: AnimatedBuilder(
        animation: _waveAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Wave effect
              if (_isNFCActive && !_isSuccess && !_isError)
                Container(
                  width: 200 + (_waveAnimation.value * 50),
                  height: 200 + (_waveAnimation.value * 50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3 - (_waveAnimation.value * 0.3)),
                      width: 2,
                    ),
                  ),
                ),
              
              // Device icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.phone_iphone,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (!_isSuccess && !_isError) ...[
            Text(
              'Make sure both devices have NFC enabled',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Keep devices close together',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (_isError) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isError = false;
                  _errorMessage = '';
                });
                _startNFCProcess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
