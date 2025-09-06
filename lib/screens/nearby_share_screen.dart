import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/nearby_share_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/custom_button.dart';

class NearbyShareScreen extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final bool isSharing;

  const NearbyShareScreen({
    super.key,
    required this.cardData,
    this.isSharing = true,
  });

  @override
  State<NearbyShareScreen> createState() => _NearbyShareScreenState();
}

class _NearbyShareScreenState extends State<NearbyShareScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _pinController;
  
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;
  late Animation<double> _pinAnimation;

  String? _generatedPIN;
  bool _isGenerating = false;
  bool _isReceiving = false;
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pinController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));

    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _pinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pinController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
    
    if (widget.isSharing) {
      _generateSharingPIN();
    }
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _headerController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _contentController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _pinController.forward();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _pinController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _generateSharingPIN() async {
    setState(() => _isGenerating = true);

    try {
      final pin = await NearbyShareService.generateSharingPIN(widget.cardData);
      setState(() {
        _generatedPIN = pin;
        _isGenerating = false;
      });
      
      // Start countdown timer
      _startCountdown();
    } catch (e) {
      setState(() => _isGenerating = false);
      _showErrorSnackBar('Failed to generate PIN: $e');
    }
  }

  void _startCountdown() {
    // Auto-cancel sharing after 1 hour
    Future.delayed(const Duration(hours: 1), () {
      if (mounted && _generatedPIN != null) {
        _cancelSharing();
      }
    });
  }

  Future<void> _cancelSharing() async {
    if (_generatedPIN != null) {
      try {
        await NearbyShareService.cancelSharing(_generatedPIN!);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        _showErrorSnackBar('Failed to cancel sharing: $e');
      }
    }
  }

  Future<void> _receiveCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isReceiving = true);

    try {
      final receivedCard = await NearbyShareService.receiveCardByPIN(_pinController.text.trim());
      
      if (mounted) {
        _showSuccessSnackBar('Card received successfully!');
        Navigator.of(context).pop(receivedCard);
      }
    } catch (e) {
      setState(() => _isReceiving = false);
      _showErrorSnackBar('Failed to receive card: $e');
    }
  }

  void _copyPIN() {
    if (_generatedPIN != null) {
      Clipboard.setData(ClipboardData(text: _generatedPIN!));
      _showSuccessSnackBar('PIN copied to clipboard');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isSharing ? 'Share Card' : 'Receive Card',
          style: AppTextStyles.title2,
        ),
        actions: widget.isSharing && _generatedPIN != null
            ? [
                IconButton(
                  onPressed: _cancelSharing,
                  icon: const Icon(Icons.close, color: AppColors.error),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _headerAnimation,
              builder: (context, child) {
                final clampedValue = _headerAnimation.value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - clampedValue)),
                  child: Opacity(
                    opacity: clampedValue,
                    child: _buildHeader(),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                final clampedValue = _contentAnimation.value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 40 * (1 - clampedValue)),
                  child: Opacity(
                    opacity: clampedValue,
                    child: widget.isSharing ? _buildSharingContent() : _buildReceivingContent(),
                  ),
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            widget.isSharing ? Icons.share : Icons.download,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.isSharing ? 'Share Your Card' : 'Receive a Card',
          style: AppTextStyles.largeTitle,
        ),
        const SizedBox(height: 8),
        Text(
          widget.isSharing 
              ? 'Generate a PIN to share your business card with others'
              : 'Enter the PIN provided by the person sharing their card',
          style: AppTextStyles.bodySecondary,
        ),
      ],
    );
  }

  Widget _buildSharingContent() {
    return Column(
      children: [
        _buildCardPreview(),
        const SizedBox(height: 32),
        if (_isGenerating)
          _buildGeneratingState()
        else if (_generatedPIN != null)
          _buildPINDisplay()
        else
          _buildGenerateButton(),
        const SizedBox(height: 24),
        _buildSharingInstructions(),
      ],
    );
  }

  Widget _buildReceivingContent() {
    return Column(
      children: [
        _buildPINEntryForm(),
        const SizedBox(height: 24),
        _buildReceivingInstructions(),
      ],
    );
  }

  Widget _buildCardPreview() {
    final cardName = widget.cardData['name'] ?? 'Unknown';
    final cardCompany = widget.cardData['businessName'] ?? 
                       widget.cardData['companyName'] ?? 
                       widget.cardData['company'] ?? '';
    final cardColor = widget.cardData['cardColor'] ?? 'gold';

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: _getCardColorGradient(cardColor),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.nfc,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'WHYY CONNECT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cardCompany.isNotEmpty ? cardCompany : 'Business Card',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Generating PIN...',
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we create a secure sharing PIN',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPINDisplay() {
    return AnimatedBuilder(
      animation: _pinAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pinAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Sharing PIN',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _generatedPIN!,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Copy PIN',
                        onPressed: _copyPIN,
                        backgroundColor: AppColors.primary,
                        textColor: AppColors.textPrimary,
                        prefixIcon: Icons.copy,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        onPressed: _cancelSharing,
                        backgroundColor: AppColors.error,
                        textColor: Colors.white,
                        prefixIcon: Icons.close,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenerateButton() {
    return CustomButton(
      text: 'Generate Sharing PIN',
      onPressed: _generateSharingPIN,
      backgroundColor: AppColors.primary,
      textColor: AppColors.textPrimary,
      prefixIcon: Icons.share,
    );
  }

  Widget _buildPINEntryForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Sharing PIN',
            style: AppTextStyles.title3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: TextStyle(
                fontSize: 24,
                color: AppColors.textTertiary,
                letterSpacing: 4,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a PIN';
              }
              if (value.trim().length != 6) {
                return 'PIN must be 6 digits';
              }
              if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                return 'PIN must contain only numbers';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: _isReceiving ? 'Receiving...' : 'Receive Card',
            onPressed: _isReceiving ? null : _receiveCard,
            isLoading: _isReceiving,
            backgroundColor: AppColors.success,
            textColor: Colors.white,
            prefixIcon: Icons.download,
          ),
        ],
      ),
    );
  }

  Widget _buildSharingInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How to share:',
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Share the PIN with the person you want to give your card to'),
          _buildInstructionStep('2', 'They can enter this PIN in the "Receive Card" section'),
          _buildInstructionStep('3', 'The PIN expires in 1 hour for security'),
          _buildInstructionStep('4', 'You can cancel sharing anytime by tapping the X button'),
        ],
      ),
    );
  }

  Widget _buildReceivingInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How to receive:',
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep('1', 'Ask the person sharing their card for the 6-digit PIN'),
          _buildInstructionStep('2', 'Enter the PIN in the field above'),
          _buildInstructionStep('3', 'Tap "Receive Card" to add it to your wallet'),
          _buildInstructionStep('4', 'The card will be saved with all contact information'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getCardColorGradient(String color) {
    switch (color.toLowerCase()) {
      case 'gold':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00)],
        );
      case 'emerald':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00D4AA), Color(0xFF00B894), Color(0xFF00A085)],
        );
      case 'diamond':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF74B9FF), Color(0xFF0984E3), Color(0xFF6C5CE7)],
        );
      case 'platinum':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDFE6E9), Color(0xFFB2BEC3), Color(0xFF636E72)],
        );
      case 'black':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D3436), Color(0xFF636E72), Color(0xFF2D3436)],
        );
      case 'ruby':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDC143C), Color(0xFFB22222), Color(0xFF8B0000)],
        );
      case 'silver':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB2BEC3), Color(0xFFDFE6E9), Color(0xFFB2BEC3)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCC61D), Color(0xFFFFB200), Color(0xFFFF9500)],
        );
    }
  }
}
