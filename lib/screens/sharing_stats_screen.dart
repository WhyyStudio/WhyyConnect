import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/nearby_share_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class SharingStatsScreen extends StatefulWidget {
  const SharingStatsScreen({super.key});

  @override
  State<SharingStatsScreen> createState() => _SharingStatsScreenState();
}

class _SharingStatsScreenState extends State<SharingStatsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _cardsController;
  
  late Animation<double> _headerAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _cardsAnimation;

  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _sharedCards = [];
  List<Map<String, dynamic>> _receivedCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardsController = AnimationController(
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

    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutCubic,
    ));

    _cardsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardsController,
      curve: Curves.easeOutCubic,
    ));

    _loadData();
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _headerController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _statsController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _cardsController.forward();
    }
  }

  Future<void> _loadData() async {
    try {
      final stats = await NearbyShareService.getSharingStats();
      final sharedCards = await NearbyShareService.getSharedCards();
      final receivedCards = await NearbyShareService.getReceivedCards();

      setState(() {
        _stats = stats;
        _sharedCards = sharedCards;
        _receivedCards = receivedCards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load sharing data: $e');
    }
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
        backgroundColor: AppColors.getError(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.getTextPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Sharing Stats',
          style: AppTextStyles.title2.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, color: AppColors.getTextPrimary(context)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.getPrimary(context)),
              ),
            )
          : SingleChildScrollView(
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
                          child: _buildHeader(context),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _statsAnimation,
                    builder: (context, child) {
                      final clampedValue = _statsAnimation.value.clamp(0.0, 1.0);
                      return Transform.translate(
                        offset: Offset(0, 40 * (1 - clampedValue)),
                        child: Opacity(
                          opacity: clampedValue,
                          child: _buildStatsSection(context),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  AnimatedBuilder(
                    animation: _cardsAnimation,
                    builder: (context, child) {
                      final clampedValue = _cardsAnimation.value.clamp(0.0, 1.0);
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - clampedValue)),
                        child: Opacity(
                          opacity: clampedValue,
                          child: _buildCardsSection(context),
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

  Widget _buildHeader(BuildContext context) {
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
                AppColors.getPrimary(context),
                AppColors.getPrimary(context).withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.getPrimary(context).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.analytics,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Sharing Analytics',
          style: AppTextStyles.largeTitle.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your card sharing activity and connections',
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: AppTextStyles.title3.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Cards Shared',
                _stats['shared']?.toString() ?? '0',
                Icons.share,
                AppColors.getPrimary(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                context,
                'Cards Received',
                _stats['received']?.toString() ?? '0',
                Icons.download,
                AppColors.getSuccess(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          context,
          'Total Shares',
          _stats['totalShares']?.toString() ?? '0',
          Icons.people,
          AppColors.getWarning(context),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorder(context),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppTextStyles.title3.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 16),
        if (_sharedCards.isNotEmpty) ...[
          _buildSectionHeader(context, 'Shared Cards', _sharedCards.length),
          const SizedBox(height: 12),
          ..._sharedCards.take(3).map((card) => _buildSharedCardItem(context, card)),
          const SizedBox(height: 24),
        ],
        if (_receivedCards.isNotEmpty) ...[
          _buildSectionHeader(context, 'Received Cards', _receivedCards.length),
          const SizedBox(height: 12),
          ..._receivedCards.take(3).map((card) => _buildReceivedCardItem(context, card)),
        ],
        if (_sharedCards.isEmpty && _receivedCards.isEmpty)
          _buildEmptyState(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.headline.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.getPrimary(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.getPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedCardItem(BuildContext context, Map<String, dynamic> card) {
    final cardData = card['cardData'] as Map<String, dynamic>;
    final receivedBy = List<String>.from(card['receivedBy'] ?? []);
    final createdAt = (card['createdAt'] as Timestamp).toDate();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: _getCardColorGradient(cardData['cardColor'] ?? 'gold'),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardData['name'] ?? 'Unknown',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shared ${receivedBy.length} times',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(createdAt),
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.getTextTertiary(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.getSuccess(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              card['pin'] ?? '',
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.getSuccess(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedCardItem(BuildContext context, Map<String, dynamic> card) {
    final receivedAt = (card['receivedAt'] as Timestamp).toDate();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: _getCardColorGradient(card['cardColor'] ?? 'gold'),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card['name'] ?? 'Unknown',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'From ${card['sharedByName'] ?? 'Unknown'}',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(receivedAt),
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.getTextTertiary(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.getWarning(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Received',
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.getWarning(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
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
          Icon(
            Icons.share,
            size: 64,
            color: AppColors.getTextTertiary(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No Sharing Activity Yet',
            style: AppTextStyles.title3.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start sharing your cards or receive cards from others to see activity here',
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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
}
