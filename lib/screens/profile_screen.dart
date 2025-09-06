import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../screens/login_screen.dart';
import 'edit_profile_screen.dart';
import 'sharing_stats_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _profileController;
  late AnimationController _menuController;
  
  late Animation<double> _headerAnimation;
  late Animation<double> _profileAnimation;
  late Animation<double> _menuAnimation;
  late Animation<Offset> _slideAnimation;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));

    _profileAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _profileController,
      curve: Curves.easeOutCubic,
    ));

    _menuAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
    ));

    _loadUserData();
    _startAnimations();
  }

  Future<void> _loadUserData() async {
    if (_currentUser != null) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _headerController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _profileController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _menuController.forward();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _profileController.dispose();
    _menuController.dispose();
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

  String _getUserEmail() {
    return _currentUser?.email ?? 'No email available';
  }

  String _getUserInitials() {
    final name = _getUserDisplayName();
    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name.toUpperCase();
  }

  String _getUserCompany() {
    if (_userData != null && _userData!['company'] != null) {
      return _userData!['company'];
    }
    return 'Company not set';
  }

  String _getUserPosition() {
    if (_userData != null && _userData!['position'] != null) {
      return _userData!['position'];
    }
    return 'Position not set';
  }

  String _getUserPhone() {
    if (_userData != null && _userData!['phone'] != null) {
      return _userData!['phone'];
    }
    return 'Phone not set';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.getBackground(context),
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
                    child: _buildHeader(context),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _profileAnimation,
              builder: (context, child) {
                final clampedValue = _profileAnimation.value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 40 * (1 - clampedValue)),
                  child: Opacity(
                    opacity: clampedValue,
                    child: _buildProfileCard(context),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) {
                final clampedValue = _menuAnimation.value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - clampedValue)),
                  child: Opacity(
                    opacity: clampedValue,
                    child: _buildMenuItems(context),
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
        Text(
          'Profile',
          style: AppTextStyles.largeTitle.copyWith(
            fontSize: 32,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        Text(
          'Manage your account and preferences',
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.getBorder(context),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFCC61D),
                  const Color(0xFFFFB200),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFCC61D).withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getUserInitials(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _getUserDisplayName(),
            style: AppTextStyles.title2.copyWith(
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getUserEmail(),
            style: AppTextStyles.body.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.business, _getUserCompany()),
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.work, _getUserPosition()),
          const SizedBox(height: 8),
          _buildInfoRow(context, Icons.phone, _getUserPhone()),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFCC61D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFCC61D),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 16,
                  color: const Color(0xFFFCC61D),
                ),
                const SizedBox(width: 8),
                Text(
                  'Verified User',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFCC61D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildProfileStat(context, 'Cards', '12', Icons.credit_card),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.getBorder(context),
              ),
              Expanded(
                child: _buildProfileStat(context, 'Views', '1.2K', Icons.visibility),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.getBorder(context),
              ),
              Expanded(
                child: _buildProfileStat(context, 'Shares', '89', Icons.share),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.getTextSecondary(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStat(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.getPrimary(context),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTextStyles.title3.copyWith(
                color: AppColors.getTextPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.footnote.copyWith(
            color: AppColors.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: AppTextStyles.title3.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
        ),
        const SizedBox(height: 16),
        SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildMenuItem(
                context,
                Icons.person_outline,
                'Edit Profile',
                'Update your personal information',
                const Color(0xFF007AFF),
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                Icons.analytics,
                'Sharing Stats',
                'View your card sharing activity',
                const Color(0xFF34C759),
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SharingStatsScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                context,
                Icons.favorite,
                'Donate',
                'Support our development',
                const Color(0xFFFF3B30),
                () => _openDonateLink(),
              ),
              _buildMenuItem(
                context,
                Icons.help_outline,
                'Help & Support',
                'Get help and contact support',
                const Color(0xFFAF52DE),
                () => _showHelpDialog(context),
              ),
              _buildMenuItem(
                context,
                Icons.info_outline,
                'About',
                'App version and information',
                const Color(0xFF8E8E93),
                () => _showAboutDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Sign Out',
          onPressed: _signOut,
          backgroundColor: const Color(0xFFFF3B30),
          textColor: Colors.white,
          prefixIcon: Icons.logout,
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.headline.copyWith(
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.footnote.copyWith(
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.getTextTertiary(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDonateLink() async {
    try {
      final Uri donateUri = Uri.parse('https://buymeacoffee.com/whyystudio');
      
      // Try different launch modes
      if (await canLaunchUrl(donateUri)) {
        await launchUrl(
          donateUri, 
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: try with platformDefault mode
        try {
          await launchUrl(
            donateUri, 
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          // Final fallback: try with externalApplication mode
          await launchUrl(
            donateUri, 
            mode: LaunchMode.externalApplication,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Could not open donation link. Please try again or visit: buymeacoffee.com/whyystudio'),
                ),
              ],
            ),
            backgroundColor: AppColors.getError(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (Fixed)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    children: [
                      // App Icon/Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFCC61D),
                              Color(0xFFFFB200),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFCC61D).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // App Name
                      Text(
                        'Whyy Connect',
                        style: AppTextStyles.title2.copyWith(
                          color: AppColors.getTextPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // App Description
                      Text(
                        'Digital Business Card Platform',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                
                // Version Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Version 1.0.0',
                    style: AppTextStyles.footnote.copyWith(
                      color: AppColors.getPrimary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Company Info
                _buildAboutInfoRow(
                  context,
                  Icons.business,
                  'Whyy Studio',
                  'Development Team',
                ),
                const SizedBox(height: 12),
                
                // Help Email
                _buildAboutInfoRow(
                  context,
                  Icons.email,
                  'helpwhyyconnect@whyystudio.com',
                  'Support Email',
                ),
                const SizedBox(height: 12),
                
                // Website
                _buildAboutInfoRow(
                  context,
                  Icons.language,
                  'whyystudio.com',
                  'Website',
                ),
                const SizedBox(height: 20),
                
                // Features List
                Text(
                  'Features',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                
                        _buildFeatureItem(context, 'Digital Business Cards'),
                        _buildFeatureItem(context, 'QR Code Sharing'),
                        _buildFeatureItem(context, 'Nearby Sharing'),
                        _buildFeatureItem(context, 'Real-time Synchronization'),
                        _buildFeatureItem(context, 'Dark Mode Support'),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Footer (Fixed)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      backgroundColor: AppColors.getPrimary(context),
                      textColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutInfoRow(BuildContext context, IconData icon, String text, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.getPrimary(context),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.getTextPrimary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.footnote.copyWith(
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.getSuccess(context),
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (Fixed)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    children: [
                      // Help Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFAF52DE),
                              Color(0xFF8E44AD),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFAF52DE).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        'Help & Support',
                        style: AppTextStyles.title2.copyWith(
                          color: AppColors.getTextPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'We\'re here to help you!',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                
                // Contact Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getPrimary(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.getPrimary(context).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Contact Support',
                        style: AppTextStyles.headline.copyWith(
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Email Row
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 20,
                            color: AppColors.getPrimary(context),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'helpwhyyconnect@whyystudio.com',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.getTextPrimary(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Email Support',
                                  style: AppTextStyles.footnote.copyWith(
                                    color: AppColors.getTextSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard('helpwhyyconnect@whyystudio.com'),
                            icon: Icon(
                              Icons.copy,
                              color: AppColors.getPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // FAQ Section
                Text(
                  'Frequently Asked Questions',
                  style: AppTextStyles.headline.copyWith(
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),
                
                        _buildFAQItem(context, 'How do I create a digital business card?', 'Go to the Cards tab and tap "Create New Card" to design your digital business card.'),
                        _buildFAQItem(context, 'How do I share my card?', 'Use the nearby sharing feature with PIN codes or generate QR codes for easy sharing.'),
                        _buildFAQItem(context, 'How do I scan someone else\'s card?', 'Go to the Wallet tab and use the QR scanner to scan and save other business cards.'),
                        _buildFAQItem(context, 'Is my data secure?', 'Yes, all your data is encrypted and stored securely.'),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Footer (Fixed)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      backgroundColor: AppColors.getPrimary(context),
                      textColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
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
            question,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.getTextPrimary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: AppTextStyles.footnote.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white),
            const SizedBox(width: 8),
            Text('Copied to clipboard: $text'),
          ],
        ),
        backgroundColor: AppColors.getSuccess(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
