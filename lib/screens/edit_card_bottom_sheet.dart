import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/nearby_share_service.dart';
import '../services/card_storage_service.dart';

class EditCardBottomSheet extends StatefulWidget {
  final DocumentSnapshot card;
  
  const EditCardBottomSheet({super.key, required this.card});

  @override
  State<EditCardBottomSheet> createState() => _EditCardBottomSheetState();
}

class _EditCardBottomSheetState extends State<EditCardBottomSheet> {
  String _selectedCardType = 'Business';
  String _selectedCardColor = 'gold';
  final _formKey = GlobalKey<FormState>();
  
  // Business card fields
  final _businessNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _mobileController = TextEditingController();
  final _hotlineController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  
  // Social card fields
  final _socialNameController = TextEditingController();
  final _companyWebsiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _facebookController = TextEditingController();
  final _xController = TextEditingController();
  final _behanceController = TextEditingController();
  final _pinterestController = TextEditingController();
  
  // Email card fields
  final _emailNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailCompanyController = TextEditingController();
  final _emailPositionController = TextEditingController();

  final List<String> _cardTypes = ['Business', 'Social', 'Email'];
  final List<String> _cardColors = [
    'gold', 'emerald', 'diamond', 'platinum', 
    'black', 'ruby', 'silver'
  ];

  @override
  void initState() {
    super.initState();
    _loadCardData();
  }

  void _loadCardData() {
    final data = widget.card.data() as Map<String, dynamic>;
    
    _selectedCardType = data['cardType']?.toString() ?? 'Business';
    _selectedCardColor = data['cardColor']?.toString() ?? 'gold';
    
    // Load data based on card type
    switch (_selectedCardType) {
      case 'Business':
        _businessNameController.text = data['businessName']?.toString() ?? '';
        _nameController.text = data['name']?.toString() ?? '';
        _positionController.text = data['position']?.toString() ?? '';
        _mobileController.text = data['mobile']?.toString() ?? '';
        _hotlineController.text = data['hotline']?.toString() ?? '';
        _addressController.text = data['address']?.toString() ?? '';
        _websiteController.text = data['website']?.toString() ?? '';
        break;
      case 'Social':
        _socialNameController.text = data['name']?.toString() ?? '';
        _companyWebsiteController.text = data['companyWebsite']?.toString() ?? '';
        _instagramController.text = data['instagram']?.toString() ?? '';
        _linkedinController.text = data['linkedin']?.toString() ?? '';
        _facebookController.text = data['facebook']?.toString() ?? '';
        _xController.text = data['x']?.toString() ?? '';
        _behanceController.text = data['behance']?.toString() ?? '';
        _pinterestController.text = data['pinterest']?.toString() ?? '';
        break;
      case 'Email':
        _emailNameController.text = data['name']?.toString() ?? '';
        _emailController.text = data['email']?.toString() ?? '';
        _emailCompanyController.text = data['companyName']?.toString() ?? '';
        _emailPositionController.text = data['position']?.toString() ?? '';
        break;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    _mobileController.dispose();
    _hotlineController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _socialNameController.dispose();
    _companyWebsiteController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _facebookController.dispose();
    _xController.dispose();
    _behanceController.dispose();
    _pinterestController.dispose();
    _emailNameController.dispose();
    _emailController.dispose();
    _emailCompanyController.dispose();
    _emailPositionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: AppColors.getBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardTypeSelector(context),
                      const SizedBox(height: 24),
                      _buildCardColorSelector(context),
                      const SizedBox(height: 24),
                      _buildCardFields(context),
                      const SizedBox(height: 32),
                      _buildSaveButton(context),
                      const SizedBox(height: 24), // Extra padding for keyboard
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppColors.getBorder(context),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.getTextTertiary(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          Text(
            'Edit Card',
            style: AppTextStyles.title3.copyWith(
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Type',
          style: AppTextStyles.headline.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorder(context),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCardType,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.getTextPrimary(context),
              ),
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
              ),
              items: _cardTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCardType = value!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardColorSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Color',
          style: AppTextStyles.headline.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorder(context),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCardColor,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.getTextPrimary(context),
              ),
              style: TextStyle(
                color: AppColors.getTextPrimary(context),
              ),
              items: _cardColors.map((color) {
                return DropdownMenuItem(
                  value: color,
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: _getCardColorGradient(color),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        color[0].toUpperCase() + color.substring(1).toLowerCase(),
                        style: TextStyle(
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCardColor = value!;
                });
              },
            ),
          ),
        ),
      ],
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

  Widget _buildCardFields(BuildContext context) {
    switch (_selectedCardType) {
      case 'Business':
        return _buildBusinessCardFields(context);
      case 'Social':
        return _buildSocialCardFields(context);
      case 'Email':
        return _buildEmailCardFields(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBusinessCardFields(BuildContext context) {
    return Column(
      children: [
        _buildTextField(
          context: context,
          controller: _businessNameController,
          label: 'Business Name *',
          hint: 'Enter business name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Business name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _nameController,
          label: 'Name *',
          hint: 'Enter your name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _positionController,
          label: 'Position *',
          hint: 'Enter your position',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Position is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _mobileController,
          label: 'Mobile Number *',
          hint: 'Enter mobile number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mobile number is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _hotlineController,
          label: 'Hotline (Optional)',
          hint: 'Enter hotline number',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _addressController,
          label: 'Address *',
          hint: 'Enter business address',
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _websiteController,
          label: 'Website (Optional)',
          hint: 'Enter website URL',
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildSocialCardFields(BuildContext context) {
    return Column(
      children: [
        _buildTextField(
          context: context,
          controller: _socialNameController,
          label: 'Name *',
          hint: 'Enter your name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _companyWebsiteController,
          label: 'Company Website *',
          hint: 'Enter company website',
          keyboardType: TextInputType.url,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Company website is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _instagramController,
          label: 'Instagram',
          hint: 'Enter Instagram handle',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _linkedinController,
          label: 'LinkedIn',
          hint: 'Enter LinkedIn profile',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _facebookController,
          label: 'Facebook',
          hint: 'Enter Facebook profile',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _xController,
          label: 'X (Twitter)',
          hint: 'Enter X handle',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _behanceController,
          label: 'Behance',
          hint: 'Enter Behance profile',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _pinterestController,
          label: 'Pinterest',
          hint: 'Enter Pinterest profile',
        ),
      ],
    );
  }

  Widget _buildEmailCardFields(BuildContext context) {
    return Column(
      children: [
        _buildTextField(
          context: context,
          controller: _emailNameController,
          label: 'Name *',
          hint: 'Enter your name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _emailController,
          label: 'Email *',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _emailCompanyController,
          label: 'Company Name *',
          hint: 'Enter company name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Company name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          context: context,
          controller: _emailPositionController,
          label: 'Position *',
          hint: 'Enter your position',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Position is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.footnote.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            color: AppColors.getTextPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.getTextSecondary(context),
            ),
            filled: true,
            fillColor: AppColors.getSurface(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.getBorder(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.getBorder(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.getPrimary(context),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateCard,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.getPrimary(context),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Update Card',
          style: AppTextStyles.headline.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _updateCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.getPrimary(context)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Updating card...',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final cardData = _buildCardData();
      cardData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .doc(widget.card.id)
          .update(cardData);

      // Synchronize with shared cards
      await _synchronizeSharedCards(cardData);

      // Close loading dialog
      Navigator.pop(context);
      
      if (mounted) {
        Navigator.pop(context); // Close edit dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Card updated successfully! Changes will be reflected in other users\' wallets.'),
                ),
              ],
            ),
            backgroundColor: AppColors.getSuccess(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error updating card: $e'),
                ),
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

  Map<String, dynamic> _buildCardData() {
    final baseData = {
      'cardType': _selectedCardType,
      'cardColor': _selectedCardColor,
    };

    switch (_selectedCardType) {
      case 'Business':
        return {
          ...baseData,
          'businessName': _businessNameController.text.trim(),
          'name': _nameController.text.trim(),
          'position': _positionController.text.trim(),
          'mobile': _mobileController.text.trim(),
          'hotline': _hotlineController.text.trim(),
          'address': _addressController.text.trim(),
          'website': _websiteController.text.trim(),
        };
      case 'Social':
        return {
          ...baseData,
          'name': _socialNameController.text.trim(),
          'companyWebsite': _companyWebsiteController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'linkedin': _linkedinController.text.trim(),
          'facebook': _facebookController.text.trim(),
          'x': _xController.text.trim(),
          'behance': _behanceController.text.trim(),
          'pinterest': _pinterestController.text.trim(),
        };
      case 'Email':
        return {
          ...baseData,
          'name': _emailNameController.text.trim(),
          'email': _emailController.text.trim(),
          'companyName': _emailCompanyController.text.trim(),
          'position': _emailPositionController.text.trim(),
        };
      default:
        return baseData;
    }
  }

  Future<void> _synchronizeSharedCards(Map<String, dynamic> updatedData) async {
    try {
      final cardId = widget.card.id;
      
      // Create updated card data for synchronization
      final updatedCardData = {
        'cardId': cardId,
        'cardType': updatedData['cardType'] ?? 'Business',
        'name': updatedData['name'] ?? 'Unknown',
        'company': updatedData['businessName'] ?? updatedData['companyName'] ?? '',
        'email': updatedData['email'] ?? '',
        'phone': updatedData['mobile'] ?? '',
        'website': updatedData['website'] ?? '',
        'address': updatedData['address'] ?? '',
        'position': updatedData['position'] ?? '',
        'cardColor': updatedData['cardColor'] ?? 'gold',
        'social': {
          'instagram': updatedData['instagram'] ?? '',
          'linkedin': updatedData['linkedin'] ?? '',
          'facebook': updatedData['facebook'] ?? '',
          'twitter': updatedData['x'] ?? '',
          'behance': updatedData['behance'] ?? '',
          'pinterest': updatedData['pinterest'] ?? '',
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      // Update nearby shared cards
      await NearbyShareService.updateSharedCard(cardId, updatedCardData);

      // Update virtual cards in local storage
      await CardStorageService.updateVirtualCard(cardId, {
        'extractedData': {
          'name': updatedCardData['name'],
          'company': updatedCardData['company'],
          'email': updatedCardData['email'],
          'phone': updatedCardData['phone'],
          'website': updatedCardData['website'],
          'address': updatedCardData['address'],
          'position': updatedCardData['position'],
        },
        'socialData': updatedCardData['social'],
        'cardType': updatedCardData['cardType'],
        'cardColor': updatedCardData['cardColor'],
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('Card synchronized successfully: $cardId');
    } catch (e) {
      print('Error synchronizing card: $e');
    }
  }
}
