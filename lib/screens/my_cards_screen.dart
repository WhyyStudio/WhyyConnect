import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../services/card_storage_service.dart';
import '../services/simple_sharing_service.dart';
import 'tap_to_share_screen.dart';

class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimations();
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
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
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
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _contentAnimation,
                builder: (context, child) {
                  final clampedValue = _contentAnimation.value.clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, 40 * (1 - clampedValue)),
                    child: Opacity(
                      opacity: clampedValue,
                      child: _buildContent(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Cards',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Create and manage your digital cards',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildAddCardButton(context),
        const SizedBox(height: 32),
        _buildMyCardsList(),
      ],
    );
  }

  Widget _buildAddCardButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFCC61D),
            const Color(0xFFFFB200),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFCC61D).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showAddCardDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.add_card,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Add New Card',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Design your digital business card',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyCardsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_currentUser?.uid)
          .collection('cards')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading cards: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final cards = snapshot.data?.docs ?? [];

        if (cards.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Cards (${cards.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 16),
            ...cards.map((card) => _buildCardItem(card)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.credit_card_outlined,
              size: 60,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No cards yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first digital card to get started',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

Widget _buildCardItem(DocumentSnapshot card) {
  try {
    final data = card.data() as Map<String, dynamic>;
    final cardType = data['cardType']?.toString() ?? 'Business';
    final cardName = data['name']?.toString() ?? 'Unknown';
    final cardColor = data['cardColor']?.toString() ?? 'gold';

         // Get card-specific details based on type
     String cardTitle = '';

    switch (cardType.toLowerCase()) {
               case 'business':
           cardTitle = data['businessName']?.toString() ?? 'Business';
           break;
         case 'social':
           cardTitle = data['companyWebsite']?.toString() ?? 'Company';
           break;
         case 'email':
           cardTitle = data['companyName']?.toString() ?? 'Company';
           break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      height: 220,
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
          // Background circles
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
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.02),
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.01),
                ],
              ),
            ),
          ),
          // Main card content
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _viewCardDetails(card),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                         // Top Row with NFC + Whyy Card + Menu
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
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.black.withValues(alpha: 0.1),
                                     offset: const Offset(0, 2),
                                     blurRadius: 4,
                                   ),
                                 ],
                               ),
                               child: Icon(
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
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.black.withValues(alpha: 0.1),
                                     offset: const Offset(0, 1),
                                     blurRadius: 2,
                                   ),
                                 ],
                               ),
                               child: Text(
                                 'WHYY CONNECT',
                                 style: TextStyle(
                                   fontFamily: 'Montserrat',
                                   fontSize: 12,
                                   fontWeight: FontWeight.w800,
                                   color: Colors.white,
                                   letterSpacing: 1.5,
                                   shadows: [
                                     Shadow(
                                       offset: const Offset(0, 1),
                                       blurRadius: 1,
                                       color: Colors.black.withValues(alpha: 0.2),
                                     ),
                                   ],
                                 ),
                               ),
                             ),
                           ],
                         ),
                      ],
                    ),

                    const Spacer(),

                    // Card Details with Company, Name, Email, and Type
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         // Company Name
                         if (cardType.toLowerCase() == 'email' && data['companyName'] != null)
                           Text(
                             data['companyName'].toString(),
                             style: TextStyle(
                               fontFamily: 'Montserrat',
                               fontSize: 18,
                               fontWeight: FontWeight.w700,
                               color: Colors.white.withValues(alpha: 0.9),
                               letterSpacing: 0.5,
                             ),
                           ),
                         if (cardType.toLowerCase() == 'email' && data['companyName'] != null)
                           const SizedBox(height: 8),
                         
                         // Person's Name
                         Text(
                           cardName,
                           style: TextStyle(
                             fontFamily: 'Playfair Display',
                             fontSize: 26,
                             fontWeight: FontWeight.w800,
                             color: Colors.white,
                             letterSpacing: 1.0,
                             shadows: [
                               Shadow(
                                 offset: const Offset(2, 2),
                                 blurRadius: 4,
                                 color: Colors.black.withValues(alpha: 0.4),
                               ),
                             ],
                           ),
                         ),
                         const SizedBox(height: 8),
                         
                         // Position/Title
                         Text(
                           cardTitle,
                           style: TextStyle(
                             fontFamily: 'Montserrat',
                             fontSize: 16,
                             fontWeight: FontWeight.w600,
                             color: Colors.white.withValues(alpha: 0.95),
                             letterSpacing: 0.5,
                           ),
                         ),
                         const SizedBox(height: 4),
                         
                         
                         // Card Type with Whyy Card branding
                         Row(
                           children: [
                             Icon(
                               Icons.nfc,
                               color: Colors.white.withValues(alpha: 0.8),
                               size: 16,
                             ),
                             const SizedBox(width: 6),
                                                            Text(
                                 'Whyy Card - $cardType',
                               style: TextStyle(
                                 fontFamily: 'Montserrat',
                                 fontSize: 12,
                                 fontWeight: FontWeight.w600,
                                 color: Colors.white.withValues(alpha: 0.8),
                                 letterSpacing: 0.5,
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom details row
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                                         Row(
                      //  children: [
                      //    Icon(
                      //      Icons.credit_card,
                      //      color: Colors.white.withValues(alpha: 0.8),
                      //      size: 16,
                      //    ),
                      //    const SizedBox(width: 6),
                      //    Text(
                      //      'Whyy Card',
                      //      style: TextStyle(
                      //        fontFamily: 'Montserrat',
                      //        fontSize: 11,
                      //        fontWeight: FontWeight.w600,
                      //        color: Colors.white.withValues(alpha: 0.8),
                      //        letterSpacing: 0.5,
                      //      ),
                      //    ),
                      //  ],
                     ),
                    Row(
                      children: [
                        Icon(
                          Icons.palette,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cardColor.isNotEmpty
                              ? cardColor[0].toUpperCase() + cardColor.substring(1).toLowerCase()
                              : 'Gold',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  } catch (e) {
    // Fallback card
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCC61D), Color(0xFFFFB200), Color(0xFFFF9500)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              'Card Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
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



  void _showAddCardDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddCardBottomSheet(),
    );
  }

  void _editCard(DocumentSnapshot card) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteCard(String cardId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUser?.uid)
          .collection('cards')
          .doc(cardId)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewCardDetails(DocumentSnapshot card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CardDetailsPopup(card: card),
    );
  }

  void _shareCard(DocumentSnapshot card) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

class AddCardBottomSheet extends StatefulWidget {
  const AddCardBottomSheet({super.key});

  @override
  State<AddCardBottomSheet> createState() => _AddCardBottomSheetState();
}

class _AddCardBottomSheetState extends State<AddCardBottomSheet> {
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardTypeSelector(),
                    const SizedBox(height: 24),
                    _buildCardColorSelector(),
                    const SizedBox(height: 24),
                    _buildCardFields(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          Text(
            'Create New Card',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1C1E),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCardType,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: _cardTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
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

  Widget _buildCardColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Color',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCardColor,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
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
                      Text(color[0].toUpperCase() + color.substring(1).toLowerCase()),
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

  Widget _buildCardFields() {
    switch (_selectedCardType) {
      case 'Business':
        return _buildBusinessCardFields();
      case 'Social':
        return _buildSocialCardFields();
      case 'Email':
        return _buildEmailCardFields();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBusinessCardFields() {
    return Column(
      children: [
        _buildTextField(
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
          controller: _hotlineController,
          label: 'Hotline (Optional)',
          hint: 'Enter hotline number',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
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
          controller: _websiteController,
          label: 'Website (Optional)',
          hint: 'Enter website URL',
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildSocialCardFields() {
    return Column(
      children: [
        _buildTextField(
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
          controller: _instagramController,
          label: 'Instagram',
          hint: 'Enter Instagram handle',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _linkedinController,
          label: 'LinkedIn',
          hint: 'Enter LinkedIn profile',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _facebookController,
          label: 'Facebook',
          hint: 'Enter Facebook profile',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _xController,
          label: 'X (Twitter)',
          hint: 'Enter X handle',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _behanceController,
          label: 'Behance',
          hint: 'Enter Behance profile',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _pinterestController,
          label: 'Pinterest',
          hint: 'Enter Pinterest profile',
        ),
      ],
    );
  }

  Widget _buildEmailCardFields() {
    return Column(
      children: [
        _buildTextField(
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveCard,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFCC61D),
          foregroundColor: const Color(0xFF1C1C1E),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Card',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final cardData = _buildCardData();
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .add(cardData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _buildCardData() {
    final baseData = {
      'cardType': _selectedCardType,
      'cardColor': _selectedCardColor,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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
}

class CardDetailsPopup extends StatefulWidget {
  final DocumentSnapshot card;
  
  const CardDetailsPopup({super.key, required this.card});

  @override
  State<CardDetailsPopup> createState() => _CardDetailsPopupState();
}

class _CardDetailsPopupState extends State<CardDetailsPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.card.data() as Map<String, dynamic>;
    final cardType = data['cardType']?.toString() ?? 'Business';
    final cardColor = data['cardColor']?.toString() ?? 'gold';
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildCardPreview(data, cardType, cardColor),
                  const SizedBox(height: 32),
                  _buildCardDetails(data, cardType),
                  const SizedBox(height: 32),
                  _buildSharingOptions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          Text(
            'Card Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1C1E),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview(Map<String, dynamic> data, String cardType, String cardColor) {
    final cardName = data['name']?.toString() ?? 'Unknown';
    String cardTitle = '';
    
    switch (cardType.toLowerCase()) {
      case 'business':
        cardTitle = data['businessName']?.toString() ?? 'Business';
        break;
      case 'social':
        cardTitle = data['companyWebsite']?.toString() ?? 'Company';
        break;
      case 'email':
        cardTitle = data['companyName']?.toString() ?? 'Company';
        break;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
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
                                    fontFamily: 'Montserrat',
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
                          if (cardType.toLowerCase() == 'email' && data['companyName'] != null) ...[
                            Text(
                              data['companyName'].toString(),
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            cardName,
                            style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.0,
                              shadows: [
                                Shadow(
                                  offset: const Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black.withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cardTitle,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.nfc,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Whyy Card - $cardType',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardDetails(Map<String, dynamic> data, String cardType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 20),
        _buildDetailSection(data, cardType),
      ],
    );
  }

  Widget _buildDetailSection(Map<String, dynamic> data, String cardType) {
    switch (cardType.toLowerCase()) {
      case 'business':
        return _buildBusinessDetails(data);
      case 'social':
        return _buildSocialDetails(data);
      case 'email':
        return _buildEmailDetails(data);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBusinessDetails(Map<String, dynamic> data) {
    final details = <Map<String, String?>>[
      {'label': 'Business Name', 'value': data['businessName']?.toString()},
      {'label': 'Name', 'value': data['name']?.toString()},
      {'label': 'Position', 'value': data['position']?.toString()},
      {'label': 'Mobile', 'value': data['mobile']?.toString()},
      {'label': 'Hotline', 'value': data['hotline']?.toString()},
      {'label': 'Address', 'value': data['address']?.toString()},
      {'label': 'Website', 'value': data['website']?.toString()},
    ];

    return _buildDetailsList(details);
  }

  Widget _buildSocialDetails(Map<String, dynamic> data) {
    final details = <Map<String, String?>>[
      {'label': 'Name', 'value': data['name']?.toString()},
      {'label': 'Company Website', 'value': data['companyWebsite']?.toString()},
      {'label': 'Instagram', 'value': data['instagram']?.toString()},
      {'label': 'LinkedIn', 'value': data['linkedin']?.toString()},
      {'label': 'Facebook', 'value': data['facebook']?.toString()},
      {'label': 'X (Twitter)', 'value': data['x']?.toString()},
      {'label': 'Behance', 'value': data['behance']?.toString()},
      {'label': 'Pinterest', 'value': data['pinterest']?.toString()},
    ];

    return _buildDetailsList(details);
  }

  Widget _buildEmailDetails(Map<String, dynamic> data) {
    final details = <Map<String, String?>>[
      {'label': 'Name', 'value': data['name']?.toString()},
      {'label': 'Email', 'value': data['email']?.toString()},
      {'label': 'Company Name', 'value': data['companyName']?.toString()},
      {'label': 'Position', 'value': data['position']?.toString()},
    ];

    return _buildDetailsList(details);
  }

  Widget _buildDetailsList(List<Map<String, String?>> details) {
    return Column(
      children: details.map((detail) {
        if (detail['value'] == null || detail['value']!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail['label']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail['value']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1C1C1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionButtons(detail['label']!, detail['value']!),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(String label, String value) {
    switch (label.toLowerCase()) {
      case 'mobile':
      case 'hotline':
        return Row(
          children: [
            _buildDetailActionButton(
              icon: Icons.phone,
              label: 'Call',
              color: const Color(0xFF34C759),
              onTap: () => _makePhoneCall(value),
            ),
            const SizedBox(width: 8),
            _buildDetailActionButton(
              icon: Icons.message,
              label: 'SMS',
              color: const Color(0xFF007AFF),
              onTap: () => _sendSMS(value),
            ),
          ],
        );
      case 'website':
        return Row(
          children: [
            _buildDetailActionButton(
              icon: Icons.language,
              label: 'Open Website',
              color: const Color(0xFF007AFF),
              onTap: () => _openWebsite(value),
            ),
          ],
        );
      case 'address':
        return Row(
          children: [
            _buildDetailActionButton(
              icon: Icons.map,
              label: 'Open in Maps',
              color: const Color(0xFF34C759),
              onTap: () => _openInMaps(value),
            ),
            const SizedBox(width: 8),
            _buildDetailActionButton(
              icon: Icons.directions,
              label: 'Get Directions',
              color: const Color(0xFFFF9500),
              onTap: () => _getDirections(value),
            ),
          ],
        );
      case 'instagram':
        return Row(
          children: [
            _buildDetailActionButton(
              icon: Icons.camera_alt,
              label: 'Open Instagram',
              color: const Color(0xFFE4405F),
              onTap: () => _openInstagram(value),
            ),
          ],
        );
      case 'linkedin':
        return Row(
          children: [
            _buildDetailActionButton(
              icon: Icons.work,
              label: 'Open LinkedIn',
              color: const Color(0xFF0077B5),
              onTap: () => _openLinkedIn(value),
            ),
          ],
        );
      case 'facebook':
        return Row(
          children: [
            _buildDetailActionButton(
              icon: Icons.facebook,
              label: 'Open Facebook',
              color: const Color(0xFF1877F2),
              onTap: () => _openFacebook(value),
            ),
          ],
        );
      case 'x (twitter)':
        return Row(
          children: [
            _buildDetailActionButton(
              icon: Icons.flutter_dash,
              label: 'Open X',
              color: const Color(0xFF000000),
              onTap: () => _openTwitter(value),
            ),
          ],
        );
      case 'behance':
        return Row(
          children: [
            _buildDetailActionButton(
              icon: Icons.design_services,
              label: 'Open Behance',
              color: const Color(0xFF1769FF),
              onTap: () => _openBehance(value),
            ),
          ],
        );
      case 'pinterest':
        return Row(
          children: [
            _buildDetailActionButton(
              icon: Icons.photo_library,
              label: 'Open Pinterest',
              color: const Color(0xFFE60023),
              onTap: () => _openPinterest(value),
            ),
          ],
        );
      case 'email':
        return Row(
          children: [
            _buildDetailActionButton(
              icon: Icons.email,
              label: 'Send Email',
              color: const Color(0xFF007AFF),
              onTap: () => _sendEmail(value),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSharingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Card',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildShareButton(
                icon: Icons.qr_code,
                label: 'QR Code',
                color: const Color(0xFF007AFF),
                onTap: () => _shareWithQR(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildShareButton(
                icon: Icons.nfc,
                label: 'NFC',
                color: const Color(0xFF34C759),
                onTap: () => _shareWithNFC(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildShareButton(
                icon: Icons.link,
                label: 'Link',
                color: const Color(0xFFFF9500),
                onTap: () => _shareWithLink(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildAdditionalActions(),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalActions() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.edit_outlined,
          label: 'Edit Card',
          onTap: () => _editCard(),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.delete_outline,
          label: 'Delete Card',
          isDestructive: true,
          onTap: () => _deleteCard(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFFF3B30) : const Color(0xFF007AFF);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
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

  void _shareWithQR() {
    final data = widget.card.data() as Map<String, dynamic>;
    final cardId = widget.card.id;
    
    // Create a unique card data structure for QR
    final cardData = {
      'cardId': cardId,
      'cardType': data['cardType'] ?? 'Business',
      'name': data['name'] ?? 'Unknown',
      'company': data['businessName'] ?? data['companyName'] ?? '',
      'email': data['email'] ?? '',
      'phone': data['mobile'] ?? '',
      'website': data['website'] ?? '',
      'address': data['address'] ?? '',
      'position': data['position'] ?? '',
      'cardColor': data['cardColor'] ?? 'gold', // Include card color
      'social': {
        'instagram': data['instagram'] ?? '',
        'linkedin': data['linkedin'] ?? '',
        'facebook': data['facebook'] ?? '',
        'twitter': data['x'] ?? '',
        'behance': data['behance'] ?? '',
        'pinterest': data['pinterest'] ?? '',
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    final qrData = jsonEncode(cardData);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      color: Color(0xFF007AFF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share Card QR Code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan this QR code with another device to add this card to your wallet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveQRCode(qrData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save QR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveQRCode(String qrData) {
    // TODO: Implement QR code saving to gallery
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('QR Code saved to gallery'),
          ],
        ),
        backgroundColor: Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
    Navigator.pop(context);
  }

  void _shareWithNFC() async {
    try {
      final data = widget.card.data() as Map<String, dynamic>;
      final cardId = widget.card.id;
      
      // Create card data for NFC sharing
      final cardData = {
        'cardId': cardId,
        'cardType': data['cardType'] ?? 'Business',
        'name': data['name'] ?? 'Unknown',
        'company': data['businessName'] ?? data['companyName'] ?? '',
        'email': data['email'] ?? '',
        'phone': data['mobile'] ?? '',
        'website': data['website'] ?? '',
        'address': data['address'] ?? '',
        'position': data['position'] ?? '',
        'cardColor': data['cardColor'] ?? 'gold',
        'social': {
          'instagram': data['instagram'] ?? '',
          'linkedin': data['linkedin'] ?? '',
          'facebook': data['facebook'] ?? '',
          'twitter': data['x'] ?? '',
          'behance': data['behance'] ?? '',
          'pinterest': data['pinterest'] ?? '',
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Navigate to tap-to-share screen
      Navigator.pop(context); // Close the current dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TapToShareScreen(
            cardData: cardData,
            isSharing: true,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _shareWithLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link sharing coming soon!'),
        backgroundColor: Color(0xFFFF9500),
      ),
    );
  }

  void _editCard() {
    Navigator.pop(context);
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Synchronize virtual cards when original card is updated
  Future<void> _synchronizeVirtualCards(String cardId, Map<String, dynamic> updatedData) async {
    try {
      // Create updated card data for QR
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
        'social': {
          'instagram': updatedData['instagram'] ?? '',
          'linkedin': updatedData['linkedin'] ?? '',
          'facebook': updatedData['facebook'] ?? '',
          'twitter': updatedData['x'] ?? '',
          'behance': updatedData['behance'] ?? '',
          'pinterest': updatedData['pinterest'] ?? '',
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Update virtual card in storage
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
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('Virtual cards synchronized for card: $cardId');
    } catch (e) {
      print('Error synchronizing virtual cards: $e');
    }
  }

  void _deleteCard() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this card? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete functionality coming soon!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B30),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorSnackBar('Could not launch phone app');
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      _showErrorSnackBar('Could not launch SMS app');
    }
  }

  Future<void> _openWebsite(String url) async {
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }
    
    final Uri websiteUri = Uri.parse(formattedUrl);
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open website');
    }
  }

  Future<void> _openInMaps(String address) async {
    final Uri mapsUri = Uri.parse(
      'https://maps.google.com/?q=${Uri.encodeComponent(address)}'
    );
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open maps');
    }
  }

  Future<void> _getDirections(String address) async {
    final Uri directionsUri = Uri.parse(
      'https://maps.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}'
    );
    if (await canLaunchUrl(directionsUri)) {
      await launchUrl(directionsUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open directions');
    }
  }

  Future<void> _openInstagram(String username) async {
    String formattedUsername = username;
    if (username.startsWith('@')) {
      formattedUsername = username.substring(1);
    }
    
    final Uri instagramUri = Uri.parse('https://instagram.com/$formattedUsername');
    if (await canLaunchUrl(instagramUri)) {
      await launchUrl(instagramUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open Instagram');
    }
  }

  Future<void> _openLinkedIn(String profile) async {
    String formattedProfile = profile;
    if (profile.startsWith('linkedin.com/')) {
      formattedProfile = 'https://$profile';
    } else if (!profile.startsWith('http')) {
      formattedProfile = 'https://linkedin.com/in/$profile';
    }
    
    final Uri linkedinUri = Uri.parse(formattedProfile);
    if (await canLaunchUrl(linkedinUri)) {
      await launchUrl(linkedinUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open LinkedIn');
    }
  }

  Future<void> _openFacebook(String profile) async {
    String formattedProfile = profile;
    if (profile.startsWith('facebook.com/')) {
      formattedProfile = 'https://$profile';
    } else if (!profile.startsWith('http')) {
      formattedProfile = 'https://facebook.com/$profile';
    }
    
    final Uri facebookUri = Uri.parse(formattedProfile);
    if (await canLaunchUrl(facebookUri)) {
      await launchUrl(facebookUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open Facebook');
    }
  }

  Future<void> _openTwitter(String username) async {
    String formattedUsername = username;
    if (username.startsWith('@')) {
      formattedUsername = username.substring(1);
    }
    
    final Uri twitterUri = Uri.parse('https://twitter.com/$formattedUsername');
    if (await canLaunchUrl(twitterUri)) {
      await launchUrl(twitterUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open X (Twitter)');
    }
  }

  Future<void> _openBehance(String profile) async {
    String formattedProfile = profile;
    if (profile.startsWith('behance.net/')) {
      formattedProfile = 'https://$profile';
    } else if (!profile.startsWith('http')) {
      formattedProfile = 'https://behance.net/$profile';
    }
    
    final Uri behanceUri = Uri.parse(formattedProfile);
    if (await canLaunchUrl(behanceUri)) {
      await launchUrl(behanceUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open Behance');
    }
  }

  Future<void> _openPinterest(String profile) async {
    String formattedProfile = profile;
    if (profile.startsWith('pinterest.com/')) {
      formattedProfile = 'https://$profile';
    } else if (!profile.startsWith('http')) {
      formattedProfile = 'https://pinterest.com/$profile';
    }
    
    final Uri pinterestUri = Uri.parse(formattedProfile);
    if (await canLaunchUrl(pinterestUri)) {
      await launchUrl(pinterestUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open Pinterest');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorSnackBar('Could not open email app');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}


