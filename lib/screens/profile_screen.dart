import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../screens/login_screen.dart';

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
  bool _isLoading = true;

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
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
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
    return SingleChildScrollView(
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
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: _profileAnimation,
            builder: (context, child) {
              final clampedValue = _profileAnimation.value.clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, 40 * (1 - clampedValue)),
                child: Opacity(
                  opacity: clampedValue,
                  child: _buildProfileCard(),
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
                  child: _buildMenuItems(),
                ),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C1C1E),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Manage your account and preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getUserEmail(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.business, _getUserCompany()),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.work, _getUserPosition()),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.phone, _getUserPhone()),
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
                child: _buildProfileStat('Cards', '12', Icons.credit_card),
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFE5E5EA),
              ),
              Expanded(
                child: _buildProfileStat('Views', '1.2K', Icons.visibility),
              ),
              Container(
                width: 1,
                height: 40,
                color: const Color(0xFFE5E5EA),
              ),
              Expanded(
                child: _buildProfileStat('Shares', '89', Icons.share),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF8E8E93),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E8E93),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFFFCC61D),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 16),
        SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildMenuItem(
                Icons.person_outline,
                'Edit Profile',
                'Update your personal information',
                const Color(0xFF007AFF),
                () {},
              ),
              _buildMenuItem(
                Icons.notifications_outlined,
                'Notifications',
                'Manage your notification preferences',
                const Color(0xFF34C759),
                () {},
              ),
              _buildMenuItem(
                Icons.security,
                'Privacy & Security',
                'Control your privacy settings',
                const Color(0xFFFF9500),
                () {},
              ),
              _buildMenuItem(
                Icons.favorite,
                'Donate',
                'Support our development',
                const Color(0xFFFF3B30),
                () {},
              ),
              _buildMenuItem(
                Icons.help_outline,
                'Help & Support',
                'Get help and contact support',
                const Color(0xFFAF52DE),
                () {},
              ),
              _buildMenuItem(
                Icons.info_outline,
                'About',
                'App version and information',
                const Color(0xFF8E8E93),
                () {},
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
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFFC7C7CC),
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
}
