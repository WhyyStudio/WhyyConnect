import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'wallet_screen.dart';
import 'my_cards_screen.dart';
import 'profile_screen.dart';
import 'sharing_stats_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../services/nearby_share_service.dart';
import '../services/card_storage_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChanged;
  
  const HomeScreen({super.key, this.onTabChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Widget> get _pages => [
    HomeContent(onTabChanged: widget.onTabChanged),
    const WalletScreen(),
    const MyCardsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _fadeController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _slideController.forward();
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _currentIndex = index;
    });
    
    if (mounted) {
      _slideController.stop();
      _slideController.reset();
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _pages[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Wallet'),
                _buildNavItem(2, Icons.credit_card_outlined, Icons.credit_card, 'Cards'),
                _buildNavItem(3, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                letterSpacing: -0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final Function(int)? onTabChanged;
  
  const HomeContent({super.key, this.onTabChanged});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with TickerProviderStateMixin {
  late AnimationController _welcomeController;
  late AnimationController _statsController;
  late AnimationController _actionsController;
  late Animation<double> _welcomeAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _actionsAnimation;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _userData;
  int _cardsCount = 0;
  int _connectionsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _actionsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _welcomeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _welcomeController,
      curve: Curves.easeOutCubic,
    ));

    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutCubic,
    ));

    _actionsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _actionsController,
      curve: Curves.easeOutCubic,
    ));

    _loadUserData();
    _startAnimations();
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data();
          });
        }

        // Get cards created by user from Firestore
        final cardsQuery = await _firestore
            .collection('cards')
            .where('userId', isEqualTo: _currentUser!.uid)
            .get();
        
        // Get shared cards count from nearby sharing service
        final sharedCards = await NearbyShareService.getSharedCards();
        
        // Get received cards count from nearby sharing service
        final receivedCards = await NearbyShareService.getReceivedCards();
        
        // Get local cards count (from SharedPreferences)
        final localCards = await CardStorageService.getAllCards();

        setState(() {
          _cardsCount = cardsQuery.docs.length + localCards.length; // Total cards created
          _connectionsCount = receivedCards.length; // Cards received (connections)
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _welcomeController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _statsController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _actionsController.forward();
    }
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _statsController.dispose();
    _actionsController.dispose();
    super.dispose();
  }

  String _getUserDisplayName() {
    if (_userData != null && _userData!['displayName'] != null) {
      return _userData!['displayName'];
    }
    final displayName = _currentUser?.displayName;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    final email = _currentUser?.email;
    if (email != null) {
      return email.split('@')[0];
    }
    return 'User';
  }

  String _getUserInitials() {
    final name = _getUserDisplayName();
    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name.toUpperCase();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  void _navigateToStats() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SharingStatsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _welcomeAnimation,
                  builder: (context, child) {
                    final clampedValue = _welcomeAnimation.value.clamp(0.0, 1.0);
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - clampedValue)),
                      child: Opacity(
                        opacity: clampedValue,
                        child: _buildWelcomeSection(),
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
                        child: _buildStatsSection(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _actionsAnimation,
                  builder: (context, child) {
                    final clampedValue = _actionsAnimation.value.clamp(0.0, 1.0);
                    return Transform.translate(
                      offset: Offset(0, 40 * (1 - clampedValue)),
                      child: Opacity(
                        opacity: clampedValue,
                        child: _buildQuickActions(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
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
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getUserInitials(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: AppTextStyles.title2.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getUserDisplayName(),
                    style: AppTextStyles.largeTitle.copyWith(
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: AppTextStyles.title3,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                _cardsCount.toString(),
                'Cards Created',
                Icons.credit_card,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                _connectionsCount.toString(),
                'Cards Received',
                Icons.download,
                AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTextStyles.largeTitle.copyWith(
                  fontSize: 32,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.title3,
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildActionTile(
              Icons.add_circle_outline,
              'Create New Card',
              'Design your digital business card',
              AppColors.primary,
              () => widget.onTabChanged?.call(2), // Navigate to Cards tab
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              Icons.qr_code_scanner_outlined,
              'Scan Card',
              'Scan and save other business cards',
              AppColors.success,
              () => widget.onTabChanged?.call(1), // Navigate to Wallet tab
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              Icons.share_outlined,
              'Share Card',
              'Share your business cards with others',
              AppColors.warning,
              () => widget.onTabChanged?.call(2), // Navigate to Cards tab
            ),
            const SizedBox(height: 12),
            _buildActionTile(
              Icons.analytics_outlined,
              'Analytics',
              'View your sharing statistics',
              AppColors.secondary,
              () => _navigateToStats(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.headline,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
