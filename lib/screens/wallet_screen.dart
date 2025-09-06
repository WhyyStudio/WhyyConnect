import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'card_scanner_screen.dart';
import '../services/card_storage_service.dart';
import '../widgets/card_details_popup.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'nearby_share_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _buttonsController;
  late AnimationController _cardsController;
  
  late Animation<double> _headerAnimation;
  late Animation<double> _buttonsAnimation;
  
  List<Map<String, dynamic>> _scannedCards = [];
  bool _isLoading = true;
  String _selectedCategory = 'All'; // 'All', 'Physical', 'Virtual'

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));

    _buttonsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOutCubic,
    ));


    _loadScannedCards();
    _startAnimations();
  }

  Future<void> _loadScannedCards() async {
    try {
      final allCards = await CardStorageService.getAllCards();
      // final linkedInCards = await _loadLinkedInCards(); // LinkedIn cards loading disabled
      if (mounted) {
        setState(() {
          _scannedCards = allCards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading cards: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredCards {
    switch (_selectedCategory) {
      case 'Physical':
        return _scannedCards.where((card) => card['cardType'] == 'physical').toList();
      case 'Virtual':
        return _scannedCards.where((card) => card['cardType'] == 'virtual').toList();
      default:
        return _scannedCards;
    }
  }

  // LinkedIn cards loading method - disabled
  /*
  Future<List<Map<String, dynamic>>> _loadLinkedInCards() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cards')
          .where('isLinkedInCard', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error loading LinkedIn cards: $e');
      return [];
    }
  }
  */

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _headerController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _buttonsController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _cardsController.forward();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _buttonsController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.getBackground(context),
      child: CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _headerAnimation,
                  builder: (context, child) {
                    final clampedValue = _headerAnimation.value.clamp(0.0, 1.0);
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - clampedValue)),
                      child: Opacity(
                        opacity: clampedValue,
                          child: _buildHeader(context),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _buttonsAnimation,
                  builder: (context, child) {
                    final clampedValue = _buttonsAnimation.value.clamp(0.0, 1.0);
                    return Transform.translate(
                      offset: Offset(0, 40 * (1 - clampedValue)),
                      child: Opacity(
                        opacity: clampedValue,
                          child: _buildActionButtons(context),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildCategorySelector(context),
                const SizedBox(height: 24),
                _buildScannedCards(context),
                const SizedBox(height: 32),
                  // _buildLinkedInCards(context), // LinkedIn cards section disabled
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet',
          style: AppTextStyles.largeTitle.copyWith(
            fontSize: 32,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Store and manage business cards shared with you',
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.title3.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 16),
                 SizedBox(
           height: 120,
           child: Row(
             children: [
               Expanded(
                 child: _buildActionButton(
                   icon: Icons.add_card,
                   title: 'Add Physical',
                   subtitle: 'Cards',
                   gradient: const LinearGradient(
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                     colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
                   ),
                   onTap: () async {
                     HapticFeedback.lightImpact();
                     await Navigator.of(context).push(
                       MaterialPageRoute(
                         builder: (context) => const CardScannerScreen(),
                       ),
                     );
                     _loadScannedCards();
                   },
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: _buildActionButton(
                   icon: Icons.qr_code_scanner,
                   title: 'Scan QR',
                   subtitle: 'Code',
                   gradient: const LinearGradient(
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                     colors: [Color(0xFF34C759), Color(0xFF30D158)],
                   ),
                                   onTap: () {
                  HapticFeedback.lightImpact();
                  _showQRScanner();
                },
                 ),
               ),
             ],
           ),
         ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: _buildActionButton(
            icon: Icons.share,
            title: 'Receive Card',
            subtitle: 'Enter PIN to receive cards',
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF9500), Color(0xFFFFB340)],
            ),
            isFullWidth: true,
            onTap: () async {
              HapticFeedback.lightImpact();
              await _receiveCardByPIN();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Categories',
          style: AppTextStyles.title3.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.getBorder(context),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildCategoryButton(
                  context: context,
                  label: 'All',
                  isSelected: _selectedCategory == 'All',
                  onTap: () => setState(() => _selectedCategory = 'All'),
                ),
              ),
              Expanded(
                child: _buildCategoryButton(
                  context: context,
                  label: 'Physical',
                  isSelected: _selectedCategory == 'Physical',
                  onTap: () => setState(() => _selectedCategory = 'Physical'),
                ),
              ),
              Expanded(
                child: _buildCategoryButton(
                  context: context,
                  label: 'Virtual',
                  isSelected: _selectedCategory == 'Virtual',
                  onTap: () => setState(() => _selectedCategory = 'Virtual'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.getPrimary(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.headline.copyWith(
            color: isSelected 
                ? Colors.white 
                : AppColors.getTextPrimary(context),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // LinkedIn cards section - disabled
  /*
  Widget _buildLinkedInCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LinkedIn Cards',
              style: AppTextStyles.title3.copyWith(
                color: AppColors.getTextPrimary(context),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077B5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_linkedInCards.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showLinkedInQRScanner(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.getPrimary(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Scan QR',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_linkedInCards.isEmpty)
          _buildLinkedInEmptyState(context)
        else
          _buildLinkedInCardsList(context),
      ],
    );
  }
  */

  // LinkedIn empty state - disabled
  /*
  Widget _buildLinkedInEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorder(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0077B5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.work,
              size: 40,
              color: Color(0xFF0077B5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No LinkedIn Cards Yet',
            style: AppTextStyles.headline.copyWith(
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan LinkedIn QR codes to store professional cards',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showLinkedInQRScanner(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0077B5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scan LinkedIn QR Code',
                    style: AppTextStyles.headline.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  */

  // LinkedIn cards list - disabled
  /*
  Widget _buildLinkedInCardsList(BuildContext context) {
    return SizedBox(
      height: 220, // Fixed height for the LinkedIn cards list
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _linkedInCards.length,
        itemBuilder: (context, index) {
          final card = _linkedInCards[index];
          return Container(
            width: 280, // Fixed width for each card
            margin: EdgeInsets.only(
              right: index < _linkedInCards.length - 1 ? 16 : 0,
            ),
            child: _buildLinkedInCardItem(context, card),
          );
        },
      ),
    );
  }
  */

  // LinkedIn card item - disabled
  /*
  Widget _buildLinkedInCardItem(BuildContext context, Map<String, dynamic> card) {
    final name = card['name'] ?? 'Unknown';
    final company = card['company'] ?? '';
    final headline = card['headline'] ?? '';
    final industry = card['industry'] ?? '';

    return GestureDetector(
      onTap: () => _showLinkedInCardDetails(context, card),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0077B5), Color(0xFF005885), Color(0xFF004066)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0077B5).withValues(alpha: 0.3),
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
            // Main content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with LinkedIn branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.work,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'LINKEDIN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showLinkedInShareOptions(context, card),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.share,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Card details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        if (headline.isNotEmpty) ...[
                          Text(
                            headline,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          company.isNotEmpty ? company : industry,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // LinkedIn profile link
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.link,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  */

  Widget _buildScannedCards(BuildContext context) {
    final filteredCards = _filteredCards;
    final physicalCount = _scannedCards.where((card) => card['cardType'] == 'physical').length;
    final virtualCount = _scannedCards.where((card) => card['cardType'] == 'virtual').length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategory == 'All' ? 'All Cards' : '$_selectedCategory Cards',
              style: AppTextStyles.title3.copyWith(
                color: AppColors.getTextPrimary(context),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$physicalCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$virtualCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredCards.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_isLoading)
          _buildLoadingState()
        else if (filteredCards.isEmpty)
          _buildEmptyState()
        else
          _buildScannedCardsList(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
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
            'Loading Cards...',
            style: AppTextStyles.headline,
          ),
        ],
      ),
    );
  }

  Widget _buildScannedCardsList() {
    final filteredCards = _filteredCards;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredCards.length,
      itemBuilder: (context, index) {
        final card = filteredCards[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < filteredCards.length - 1 ? 16 : 20,
          ),
          child: _buildScannedCardItem(card),
        );
      },
    );
  }

  Widget _buildScannedCardItem(Map<String, dynamic> card) {
    final extractedData = card['extractedData'] ?? {};
    final name = extractedData['name'] ?? 'Unknown';
    final company = extractedData['company'] ?? '';
    final email = extractedData['email'] ?? '';
    final phone = extractedData['phone'] ?? '';
    final position = extractedData['position'] ?? '';
    final cardType = card['cardType'] ?? 'physical';
    final isVirtual = cardType == 'virtual';
    final cardColor = card['cardColor'] ?? 'gold';

    return GestureDetector(
      onTap: () => _showCardDetails(card),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row with Card Type and Color
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Whhy Card - ${isVirtual ? 'Virtual' : 'Physical'}',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cardColor.isNotEmpty
                                  ? cardColor[0].toUpperCase() + cardColor.substring(1).toLowerCase()
                                  : 'Gold',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showDeleteConfirmation(card),
                        child: Container(
                              padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                                size: 16,
                            color: Colors.white,
                          ),
                        ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Card Details with Name, Company, and Position
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Person's Name (Main focus)
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 28,
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
                      
                      // Company Name
                        Text(
                        company.isNotEmpty ? company : 'Unknown Company',
                          style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                          letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                      
                      // Position/Title
                      if (position.isNotEmpty)
                      Text(
                          position,
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                        ),
                      ),
                    ],
                                ),
                              ],
                            ),
            ),
            // Bottom branding
            Positioned(
              bottom: 24,
              right: 24,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                child: Text(
                  'Whyy Connect',
                                      style: TextStyle(
                    fontFamily: 'Montserrat',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
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


  void _showCardDetails(Map<String, dynamic> card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CardDetailsPopup(card: card),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> card) {
    final extractedData = card['extractedData'] ?? {};
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
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Card',
                style: AppTextStyles.title2,
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
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.headline,
                  ),
                  if (company.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      company,
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.textSecondary,
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
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The card and its images will be permanently deleted.',
                      style: AppTextStyles.caption1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
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
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCard(card);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
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

  Future<void> _deleteCard(Map<String, dynamic> card) async {
    try {
      final cardId = card['id'];
      final cardType = card['cardType'] ?? 'physical';
      
      if (cardId == null) {
        throw Exception('Card ID not found');
      }

      await CardStorageService.deleteCard(cardId, cardType);
      
      // Delete image files for physical cards only
      if (cardType == 'physical') {
        final frontImagePath = card['frontImagePath'];
        final backImagePath = card['backImagePath'];
        
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

      await _loadScannedCards();
      
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
            backgroundColor: AppColors.success,
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
            backgroundColor: AppColors.error,
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

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;
    Color iconColor;
    
    switch (_selectedCategory) {
      case 'Physical':
        title = 'No Physical Cards';
        subtitle = 'Scan physical business cards to store them here';
        icon = Icons.camera_alt_outlined;
        iconColor = const Color(0xFF007AFF);
        break;
      case 'Virtual':
        title = 'No Virtual Cards';
        subtitle = 'Scan QR codes or receive cards via nearby sharing to store them here';
        icon = Icons.qr_code_outlined;
        iconColor = const Color(0xFF34C759);
        break;
      default:
        title = 'No Cards Yet';
        subtitle = 'Scan physical cards or add virtual cards via QR codes to store them here';
        icon = Icons.inbox_outlined;
        iconColor = AppColors.getPrimary(context);
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorder(context),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              icon,
              size: 40,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: AppTextStyles.title2.copyWith(
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.getPrimary(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Start scanning cards now',
              style: AppTextStyles.headline.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onQRCodeScanned: (qrData) {
            _processQRData(qrData);
          },
        ),
      ),
    );
  }



  void _processQRData(String qrData) async {
    try {
      final cardData = jsonDecode(qrData) as Map<String, dynamic>;
      
      // Create a virtual card entry
      final cardEntry = {
        'extractedData': {
          'name': cardData['name'] ?? 'Unknown',
          'company': cardData['company'] ?? '',
          'email': cardData['email'] ?? '',
          'phone': cardData['phone'] ?? '',
          'website': cardData['website'] ?? '',
          'address': cardData['address'] ?? '',
          'position': cardData['position'] ?? '',
        },
        'socialData': cardData['social'] ?? {},
        'cardType': cardData['cardType'] ?? 'Business',
        'source': 'QR Code',
        'qrCardId': cardData['cardId'],
        'cardColor': cardData['cardColor'] ?? 'gold', // Use the color from QR data
      };
      
      // Save virtual card to storage
      await CardStorageService.saveVirtualCard(cardEntry);
      
      // Reload cards to show the new one
      await _loadScannedCards();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Virtual card added: ${cardData['name']}'),
              ],
            ),
            backgroundColor: const Color(0xFF34C759),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Invalid QR code: $e'),
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
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _receiveCardByPIN() async {
    try {
      // Navigate to nearby share screen for receiving
      final receivedCard = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NearbyShareScreen(
            cardData: {}, // Empty for receiving
            isSharing: false,
          ),
        ),
      );

      // If card was received successfully, save it and reload cards
      if (receivedCard != null) {
        // Save the received card as a virtual card
        final cardEntry = {
          'extractedData': {
            'name': receivedCard['name'] ?? 'Unknown',
            'company': receivedCard['company'] ?? '',
            'email': receivedCard['email'] ?? '',
            'phone': receivedCard['phone'] ?? '',
            'website': receivedCard['website'] ?? '',
            'address': receivedCard['address'] ?? '',
            'position': receivedCard['position'] ?? '',
          },
          'socialData': receivedCard['social'] ?? {},
          'cardType': receivedCard['cardType'] ?? 'Business',
          'source': 'Nearby Share',
          'qrCardId': receivedCard['cardId'],
          'cardColor': receivedCard['cardColor'] ?? 'gold',
          'sharedBy': receivedCard['sharedBy'],
          'sharedByName': receivedCard['sharedByName'],
          'sharingPIN': receivedCard['sharingPIN'],
        };

        await CardStorageService.saveVirtualCard(cardEntry);
        await _loadScannedCards();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Card received successfully!'),
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
      }
    } catch (e) {
      _showErrorSnackBar('Error receiving card: $e');
    }
  }

  // LinkedIn-specific methods - disabled
  /*
  void _showLinkedInQRScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LinkedInQRScannerScreen(
          onLinkedInQRScanned: (qrData) {
            _processLinkedInQRData(qrData);
          },
        ),
      ),
    );
  }
  */

  /*
  void _processLinkedInQRData(String qrData) async {
    try {
      final cardData = jsonDecode(qrData) as Map<String, dynamic>;
      
      // Check if it's a LinkedIn card
      if (cardData['cardType'] == 'LinkedIn' || cardData['source'] == 'LinkedIn') {
        // Create a LinkedIn card entry
        final cardEntry = {
          'cardType': 'LinkedIn',
          'cardColor': cardData['cardColor'] ?? 'diamond',
          'name': cardData['name'] ?? 'Unknown',
          'firstName': cardData['firstName'] ?? '',
          'lastName': cardData['lastName'] ?? '',
          'email': cardData['email'] ?? '',
          'profilePicture': cardData['linkedInData']?['profilePicture'] ?? '',
          'headline': cardData['linkedInData']?['headline'] ?? '',
          'industry': cardData['linkedInData']?['industry'] ?? '',
          'location': cardData['address'] ?? '',
          'summary': cardData['linkedInData']?['summary'] ?? '',
          'currentPosition': cardData['position'] ?? '',
          'company': cardData['company'] ?? '',
          'linkedInProfile': cardData['social']?['linkedin'] ?? '',
          'experience': cardData['linkedInData']?['experience'] ?? [],
          'education': cardData['linkedInData']?['education'] ?? [],
          'skills': cardData['linkedInData']?['skills'] ?? [],
          'linkedInId': cardData['cardId']?.split('_')[1] ?? '',
          'source': 'LinkedIn QR',
          'isLinkedInCard': true,
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        // Save LinkedIn card to Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cards')
              .add(cardEntry);

          // Also save to top-level cards collection
          await FirebaseFirestore.instance
              .collection('cards')
              .add({
                ...cardEntry,
                'userId': user.uid,
              });
        }
        
        // Reload cards to show the new one
        await _loadScannedCards();
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('LinkedIn card added: ${cardData['name']}'),
                ],
              ),
              backgroundColor: const Color(0xFF0077B5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        // Handle regular QR codes
        _processQRData(qrData);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Invalid LinkedIn QR code: $e'),
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
  }
  */

  /*
  void _showLinkedInCardDetails(BuildContext context, Map<String, dynamic> card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LinkedInCardDetailsPopup(card: card),
    );
  }

  void _showLinkedInShareOptions(BuildContext context, Map<String, dynamic> card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => LinkedInShareOptionsBottomSheet(card: card),
    );
  }
  */
}

class QRScannerScreen extends StatefulWidget {
  final Function(String) onQRCodeScanned;
  
  const QRScannerScreen({super.key, required this.onQRCodeScanned});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.flash_off : Icons.flash_on),
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {
                _isScanning = !_isScanning;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _onQRCodeDetected(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF34C759),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Corner indicators
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              // Center text
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFF34C759),
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Position QR code here',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQRCodeDetected(String qrData) {
    // Stop scanning to prevent multiple scans
    cameraController.stop();
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('QR Code detected!'),
          ],
        ),
        backgroundColor: Color(0xFF34C759),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Process the QR data and return to previous screen
    widget.onQRCodeScanned(qrData);
    Navigator.pop(context);
  }
}

// LinkedIn QR Scanner Screen
class LinkedInQRScannerScreen extends StatefulWidget {
  final Function(String) onLinkedInQRScanned;
  
  const LinkedInQRScannerScreen({super.key, required this.onLinkedInQRScanned});

  @override
  State<LinkedInQRScannerScreen> createState() => _LinkedInQRScannerScreenState();
}

class _LinkedInQRScannerScreenState extends State<LinkedInQRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Scan LinkedIn QR Code',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.flash_off : Icons.flash_on),
            onPressed: () {
              cameraController.toggleTorch();
              setState(() {
                _isScanning = !_isScanning;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _onLinkedInQRCodeDetected(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          _buildLinkedInOverlay(),
        ],
      ),
    );
  }

  Widget _buildLinkedInOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF0077B5),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Corner indicators
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0077B5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0077B5),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0077B5),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0077B5),
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              // Center text
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work,
                      color: Color(0xFF0077B5),
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Position LinkedIn QR here',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onLinkedInQRCodeDetected(String qrData) {
    // Stop scanning to prevent multiple scans
    cameraController.stop();
    
    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('LinkedIn QR Code detected!'),
          ],
        ),
        backgroundColor: Color(0xFF0077B5),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Process the QR data and return to previous screen
    widget.onLinkedInQRScanned(qrData);
    Navigator.pop(context);
  }
}

// LinkedIn Card Details Popup
class LinkedInCardDetailsPopup extends StatelessWidget {
  final Map<String, dynamic> card;
  
  const LinkedInCardDetailsPopup({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildLinkedInCardPreview(context),
                  const SizedBox(height: 32),
                  _buildLinkedInDetails(context),
                  const SizedBox(height: 32),
                  _buildLinkedInActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            'LinkedIn Card Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context),
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

  Widget _buildLinkedInCardPreview(BuildContext context) {
    final name = card['name'] ?? 'Unknown';
    final company = card['company'] ?? '';
    final headline = card['headline'] ?? '';

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0077B5), Color(0xFF005885), Color(0xFF004066)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0077B5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.work,
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
                    'LINKEDIN CARD',
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
            const Spacer(),
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            if (headline.isNotEmpty) ...[
              Text(
                headline,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              company,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedInDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Professional Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 20),
        _buildDetailItem(context, 'Name', card['name'] ?? ''),
        _buildDetailItem(context, 'Headline', card['headline'] ?? ''),
        _buildDetailItem(context, 'Company', card['company'] ?? ''),
        _buildDetailItem(context, 'Industry', card['industry'] ?? ''),
        _buildDetailItem(context, 'Location', card['location'] ?? ''),
        _buildDetailItem(context, 'Email', card['email'] ?? ''),
        if (card['summary'] != null && card['summary'].toString().isNotEmpty)
          _buildDetailItem(context, 'Summary', card['summary']),
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedInActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openLinkedInProfile(context),
            icon: const Icon(Icons.work),
            label: const Text('Open LinkedIn Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _shareLinkedInCard(context),
            icon: const Icon(Icons.share),
            label: const Text('Share LinkedIn Card'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0077B5),
              side: const BorderSide(color: Color(0xFF0077B5)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openLinkedInProfile(BuildContext context) {
    final linkedInProfile = card['linkedInProfile'] ?? '';
    if (linkedInProfile.isNotEmpty) {
      // TODO: Implement LinkedIn profile opening
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening LinkedIn profile...'),
          backgroundColor: Color(0xFF0077B5),
        ),
      );
    }
  }

  void _shareLinkedInCard(BuildContext context) {
    // TODO: Implement LinkedIn card sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing LinkedIn card...'),
        backgroundColor: Color(0xFF0077B5),
      ),
    );
  }
}

// LinkedIn Share Options Bottom Sheet
class LinkedInShareOptionsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> card;
  
  const LinkedInShareOptionsBottomSheet({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Share LinkedIn Card',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildShareOption(
                  context,
                  icon: Icons.qr_code,
                  label: 'QR Code',
                  color: const Color(0xFF007AFF),
                  onTap: () => _shareAsQR(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildShareOption(
                  context,
                  icon: Icons.share,
                  label: 'Nearby',
                  color: const Color(0xFF34C759),
                  onTap: () => _shareNearby(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
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

  void _shareAsQR(BuildContext context) {
    Navigator.pop(context);
    // TODO: Implement QR code sharing for LinkedIn card
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating LinkedIn QR code...'),
        backgroundColor: Color(0xFF007AFF),
      ),
    );
  }

  void _shareNearby(BuildContext context) {
    Navigator.pop(context);
    // TODO: Implement nearby sharing for LinkedIn card
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing LinkedIn card nearby...'),
        backgroundColor: Color(0xFF34C759),
      ),
    );
  }
}
