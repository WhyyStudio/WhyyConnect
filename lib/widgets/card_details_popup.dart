import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/card_storage_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CardDetailsPopup extends StatefulWidget {
  final Map<String, dynamic> card;

  const CardDetailsPopup({super.key, required this.card});

  @override
  State<CardDetailsPopup> createState() => _CardDetailsPopupState();
}

class _CardDetailsPopupState extends State<CardDetailsPopup>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _slideController;
  late Animation<double> _flipAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final extractedData = widget.card['extractedData'] ?? {};
    final name = extractedData['name'] ?? 'Unknown';
    final company = extractedData['company'] ?? '';
    final email = extractedData['email'] ?? '';
    final phone = extractedData['phone'] ?? '';
    final website = extractedData['website'] ?? '';
    final address = extractedData['address'] ?? '';
    final title = extractedData['title'] ?? '';
    final frontImagePath = widget.card['frontImagePath'] ?? '';
    final backImagePath = widget.card['backImagePath'] ?? '';
    final scannedDate = widget.card['createdAt'] ?? DateTime.now().toString();

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.getBorder(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.business,
                      color: AppColors.getPrimary(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.title2.copyWith(
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        if (company.isNotEmpty)
                          Text(
                            company,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _showDeleteConfirmation(),
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.getError(context),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.getError(context).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.getTextSecondary(context),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.getSurface(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Card Image Section
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Flip button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.getPrimary(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flip,
                            size: 16,
                            color: AppColors.getPrimary(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tap to flip card',
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.getPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Card Image
                    Expanded(
                      child: GestureDetector(
                        onTap: _flipCard,
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final isShowingFront = _flipAnimation.value < 0.5;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(_flipAnimation.value * 3.14159),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: isShowingFront
                                      ? _buildCardImage(frontImagePath, 'Front')
                                      : Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()..rotateY(3.14159),
                                          child: _buildCardImage(backImagePath, 'Back'),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Details Section
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.getBorder(context),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Contact Information',
                        style: AppTextStyles.title3.copyWith(
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            if (title.isNotEmpty) _buildInfoRow(Icons.work_outline, 'Title', title),
                            if (email.isNotEmpty) _buildInfoRow(Icons.email_outlined, 'Email', email),
                            if (phone.isNotEmpty) _buildInteractiveInfoRow(
                              Icons.phone_outlined, 
                              'Phone', 
                              phone, 
                              () => _makePhoneCall(phone),
                              'Call',
                            ),
                            if (website.isNotEmpty) _buildInteractiveInfoRow(
                              Icons.language, 
                              'Website', 
                              website, 
                              () => _openWebsite(website),
                              'Visit',
                            ),
                            if (address.isNotEmpty) _buildInteractiveInfoRow(
                              Icons.location_on_outlined, 
                              'Address', 
                              address, 
                              () => _getDirections(address),
                              'Directions',
                            ),
                            _buildInfoRow(Icons.calendar_today, 'Scanned', _formatDate(scannedDate)),
                            const SizedBox(height: 20), // Extra padding at bottom
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(String imagePath, String fallbackText) {
    print('Checking image path: $imagePath');
    if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
      print('Image exists, loading: $imagePath');
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return _buildFallbackCard(fallbackText);
        },
      );
    } else {
      print('Image not found or path empty: $imagePath');
      return _buildFallbackCard(fallbackText);
    }
  }

  Widget _buildFallbackCard(String side) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getPrimary(context).withValues(alpha: 0.1),
            AppColors.getPrimary(context).withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            side == 'Front' ? Icons.business : Icons.contact_page,
            size: 48,
            color: AppColors.getPrimary(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Card $side',
            style: AppTextStyles.title3.copyWith(
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Image not available',
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.getPrimary(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.getPrimary(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveInfoRow(IconData icon, String label, String value, VoidCallback onTap, String actionText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.getPrimary(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.getPrimary(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.getPrimary(context),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.getPrimary(context).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                actionText,
                style: AppTextStyles.caption1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar('Could not launch phone app');
      }
    } catch (e) {
      _showErrorSnackBar('Error making phone call: $e');
    }
  }

  Future<void> _openWebsite(String website) async {
    try {
      String url = website;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      
      final Uri websiteUri = Uri.parse(url);
      if (await canLaunchUrl(websiteUri)) {
        await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open website');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening website: $e');
    }
  }

  Future<void> _getDirections(String address) async {
    try {
      final Uri directionsUri = Uri.parse('https://maps.google.com/maps?q=${Uri.encodeComponent(address)}');
      if (await canLaunchUrl(directionsUri)) {
        await launchUrl(directionsUri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open maps');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening maps: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.getError(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDeleteConfirmation() {
    final extractedData = widget.card['extractedData'] ?? {};
    final name = extractedData['name'] ?? 'Unknown';
    final company = extractedData['company'] ?? '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.getError(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.getError(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Card',
                style: AppTextStyles.title2.copyWith(
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this card?',
              style: AppTextStyles.body.copyWith(
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.getBorder(context),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  if (company.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      company,
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getError(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.getError(context).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.getError(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The card and its images will be permanently deleted.',
                      style: AppTextStyles.caption1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.getError(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: AppTextStyles.headline.copyWith(
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close confirmation dialog
              Navigator.of(context).pop(); // Close card details popup
              _deleteCard();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getError(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: AppTextStyles.headline.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard() async {
    try {
      final cardId = widget.card['id'];
      final cardType = widget.card['cardType'] ?? 'physical';
      
      if (cardId == null) {
        throw Exception('Card ID not found');
      }

      // Delete the card from storage
      await CardStorageService.deleteCard(cardId, cardType);
      
      // Delete associated image files for physical cards only
      if (cardType == 'physical') {
        final frontImagePath = widget.card['frontImagePath'];
        final backImagePath = widget.card['backImagePath'];
        
        if (frontImagePath != null && frontImagePath.isNotEmpty) {
          final frontFile = File(frontImagePath);
          if (await frontFile.exists()) {
            await frontFile.delete();
          }
        }
        
        if (backImagePath != null && backImagePath.isNotEmpty) {
          final backFile = File(backImagePath);
          if (await backFile.exists()) {
            await backFile.delete();
          }
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('${cardType == 'virtual' ? 'Virtual' : 'Physical'} card deleted successfully'),
              ],
            ),
            backgroundColor: AppColors.getSuccess(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('Error deleting card: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text('Failed to delete card'),
              ],
            ),
            backgroundColor: AppColors.getError(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
