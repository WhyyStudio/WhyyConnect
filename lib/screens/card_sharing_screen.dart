import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/device_sharing_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CardSharingScreen extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final bool isSharing; // true for sharing, false for receiving

  const CardSharingScreen({
    super.key,
    required this.cardData,
    required this.isSharing,
  });

  @override
  State<CardSharingScreen> createState() => _CardSharingScreenState();
}

class _CardSharingScreenState extends State<CardSharingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _codeController;
  late AnimationController _successController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _codeAnimation;
  late Animation<double> _successAnimation;
  
  String _sharingCode = '';
  bool _isLoading = true;
  bool _isSuccess = false;
  bool _isError = false;
  String _errorMessage = '';
  String _inputCode = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSharingProcess();
  }

  void _initializeAnimations() {
    // Pulse animation for sharing
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Code animation
    _codeController = AnimationController(
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

    _codeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _codeController,
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
        await _shareCard();
      } else {
        // For receiving, we don't need to do anything initially
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _shareCard() async {
    try {
      final sharingCode = await DeviceSharingService.shareCardWithCode(widget.cardData);
      
      setState(() {
        _sharingCode = sharingCode;
        _isLoading = false;
      });
      
      _codeController.forward();
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = 'Failed to share card: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _receiveCard() async {
    if (_inputCode.isEmpty || _inputCode.length != 6) {
      setState(() {
        _isError = true;
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _isError = false;
      });

      final receivedCard = await DeviceSharingService.receiveCardWithCode(_inputCode.toUpperCase());
      
      if (receivedCard != null) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
        _successController.forward();
        
        // Navigate back with success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, receivedCard);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copySharingCode() {
    Clipboard.setData(ClipboardData(text: _sharingCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.copy, color: Colors.white),
            SizedBox(width: 8),
            Text('Sharing code copied to clipboard'),
          ],
        ),
        backgroundColor: Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _codeController.dispose();
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
                    if (_isLoading)
                      _buildLoadingState()
                    else if (_isError)
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
              _isSuccess ? Icons.check : Icons.share,
              color: Colors.white,
              size: 60,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          widget.isSharing ? 'Generating sharing code...' : 'Processing...',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
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
    final sharingData = jsonEncode({
      'type': 'card_share',
      'code': _sharingCode,
      'cardName': widget.cardData['name'] ?? 'Unknown',
    });

    return AnimatedBuilder(
      animation: _codeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _codeAnimation.value,
          child: Column(
            children: [
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: sharingData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 24),
              
              // Sharing Code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Sharing Code',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _sharingCode,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _copySharingCode,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
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
                      'Share this code with another device to transfer your card',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Code expires in 5 minutes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
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
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter the 6-digit sharing code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Code input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _inputCode = value.toUpperCase();
                    });
                  },
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: 'ABCD12',
                    hintStyle: TextStyle(
                      color: Colors.white54,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Receive button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _inputCode.length == 6 ? _receiveCard : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Receive Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
