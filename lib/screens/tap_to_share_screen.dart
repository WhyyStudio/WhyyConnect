import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/simple_sharing_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class TapToShareScreen extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final bool isSharing; // true for sharing, false for receiving

  const TapToShareScreen({
    super.key,
    required this.cardData,
    required this.isSharing,
  });

  @override
  State<TapToShareScreen> createState() => _TapToShareScreenState();
}

class _TapToShareScreenState extends State<TapToShareScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _deviceController;
  late AnimationController _successController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _deviceAnimation;
  late Animation<double> _successAnimation;
  
  List<Map<String, dynamic>> _nearbyDevices = [];
  bool _isDiscovering = false;
  bool _isSharing = false;
  bool _isSuccess = false;
  bool _isError = false;
  String _errorMessage = '';
  String _currentDeviceId = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSharingProcess();
  }

  void _initializeAnimations() {
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Device animation
    _deviceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Success animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _deviceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _deviceController,
      curve: Curves.easeOutBack,
    ));

    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  Future<void> _startSharingProcess() async {
    try {
      if (widget.isSharing) {
        await _startDeviceDiscovery();
      } else {
        await _startReceivingMode();
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _startDeviceDiscovery() async {
    setState(() {
      _isDiscovering = true;
    });

    await SimpleSharingService.startDiscovery((device) {
      if (mounted) {
        setState(() {
          _nearbyDevices.add(device);
        });
        _deviceController.forward();
      }
    });
  }

  Future<void> _startReceivingMode() async {
    setState(() {
      _isDiscovering = true;
    });

    // Check for received cards periodically
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final receivedCard = await SimpleSharingService.checkForReceivedCards();
      if (receivedCard != null) {
        timer.cancel();
        _showSuccess(receivedCard);
      }
    });
  }

  Future<void> _shareWithDevice(Map<String, dynamic> device) async {
    try {
      setState(() {
        _isSharing = true;
        _currentDeviceId = device['id'];
      });

      final success = await SimpleSharingService.shareCardWithDevice(
        device['id'],
        widget.cardData,
      );

      if (success) {
        _showSuccess(null);
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'Failed to share with device';
          _isSharing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
        _isSharing = false;
      });
    }
  }

  void _showSuccess(Map<String, dynamic>? receivedCard) {
    setState(() {
      _isSuccess = true;
      _isDiscovering = false;
      _isSharing = false;
    });
    
    _successController.forward();
    
    // Navigate back with success
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, receivedCard);
      }
    });
  }

  @override
  void dispose() {
    SimpleSharingService.stopDiscovery();
    _pulseController.dispose();
    _deviceController.dispose();
    _successController.dispose();
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
                    // Sharing animation
                    _buildSharingAnimation(),
                    
                    const SizedBox(height: 40),
                    
                    // Content based on state
                    if (_isError)
                      _buildErrorState()
                    else if (_isSuccess)
                      _buildSuccessState()
                    else if (widget.isSharing)
                      _buildSharingState()
                    else
                      _buildReceivingState(),
                  ],
                ),
              ),
            ),
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
            widget.isSharing ? 'Tap to Share' : 'Tap to Receive',
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

  Widget _buildSharingAnimation() {
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
              _isSuccess ? Icons.check : Icons.devices,
              color: Colors.white,
              size: 60,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF3B30),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error,
            color: Color(0xFFFF3B30),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFF3B30),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isError = false;
                _errorMessage = '';
              });
              _startSharingProcess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _successAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF34C759),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF34C759),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isSharing 
                      ? 'Card shared successfully!'
                      : 'Card received successfully!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF34C759),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSharingState() {
    return AnimatedBuilder(
      animation: _deviceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _deviceAnimation.value,
          child: Column(
            children: [
              // Status message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isDiscovering 
                          ? 'Searching for nearby devices...'
                          : 'Found ${_nearbyDevices.length} device(s)',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Nearby devices list
              if (_nearbyDevices.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _nearbyDevices.length,
                    itemBuilder: (context, index) {
                      final device = _nearbyDevices[index];
                      return _buildDeviceItem(device);
                    },
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap on a device to share your card',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceItem(Map<String, dynamic> device) {
    final isSharingWithThis = _isSharing && _currentDeviceId == device['id'];
    
    return GestureDetector(
      onTap: isSharingWithThis ? null : () => _shareWithDevice(device),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSharingWithThis 
              ? const Color(0xFF007AFF).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSharingWithThis 
                ? const Color(0xFF007AFF)
                : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSharingWithThis ? Icons.sync : Icons.phone_android,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isSharingWithThis 
                        ? 'Sharing...'
                        : 'Tap to share',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSharingWithThis)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivingState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.phone_android,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Waiting for card...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure the other device is sharing',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep this screen open to receive cards',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
