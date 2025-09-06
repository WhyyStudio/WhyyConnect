import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int page = 0;
  late LiquidController liquidController;

    final List<OnboardingSlide> slides = [
    OnboardingSlide(
      title: 'Digital Business Cards',
      subtitle: 'Create and share professional digital business cards instantly',
      description: 'No more paper waste, always up-to-date information',
      icon: Icons.business_center_outlined,
      imagePath: 'assets/CARD APP MAQUINA.gif',
      color: const Color(0xFFFFCC00),
    ),
    OnboardingSlide(
      title: 'Seamless Sharing',
      subtitle: 'Share your business card with anyone, anywhere',
      description: 'QR codes, links, and instant sharing make networking effortless',
      icon: Icons.share_outlined,
      imagePath: 'assets/Friend.gif',
      color: const Color(0xFF0065F8),
    ),
    OnboardingSlide(
      title: 'Smart Card Wallet',
      subtitle: 'Store and organize all your business contacts',
      description: 'Easy access to important connections',
      icon: Icons.account_balance_wallet_outlined,
      imagePath: 'assets/online-wallet.gif',
      color: const Color(0xFFFFFFFF),
    ),
  ];

  @override
  void initState() {
    liquidController = LiquidController();
    super.initState();
  }

  Widget _buildDot(int index) {
    double selectedness = Curves.easeOut.transform(
      max(
        0.0,
        1.0 - ((page) - index).abs(),
      ),
    );
    double zoom = 1.0 + (2.0 - 1.0) * selectedness;
    return Container(
      width: 25.0,
      child: Center(
        child: Material(
          color: slides[page].color == Colors.white ? const Color(0xFF1C1C1E) : Colors.white,
          type: MaterialType.circle,
          child: Container(
            width: 8.0 * zoom,
            height: 8.0 * zoom,
          ),
        ),
      ),
    );
  }

  void _navigateToLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (e) {
      // If shared preferences fails, continue with navigation
    }
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  void pageChangeCallback(int lpage) {
    setState(() {
      page = lpage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Stack(
        children: <Widget>[
          LiquidSwipe.builder(
            itemCount: slides.length,
            itemBuilder: (context, index) {
              return Container(
                width: double.infinity,
                color: slides[index].color,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.06,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.08),
                        Image.asset(
                          slides[index].imagePath,
                          width: screenWidth * 0.55,
                          height: screenWidth * 0.55,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: screenWidth * 0.35,
                              height: screenWidth * 0.35,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(screenWidth * 0.175),
                              ),
                              child: Icon(
                                slides[index].icon,
                                size: screenWidth * 0.18,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: screenHeight * 0.08),
                        Column(
                          children: [
                            Text(
                              slides[index].title,
                              style: TextStyle(
                                fontSize: screenWidth * 0.085,
                                fontWeight: FontWeight.w700,
                                color: slides[index].color == Colors.white ? const Color(0xFF1C1C1E) : Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.025),
                            Text(
                              slides[index].subtitle,
                              style: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.w600,
                                color: slides[index].color == Colors.white 
                                    ? const Color(0xFF1C1C1E).withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.95),
                                letterSpacing: -0.2,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              slides[index].description,
                              style: TextStyle(
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.w400,
                                color: slides[index].color == Colors.white 
                                    ? const Color(0xFF1C1C1E).withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.85),
                                letterSpacing: -0.1,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
            positionSlideIcon: 0.8,
            slideIconWidget: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPageChangeCallback: pageChangeCallback,
            waveType: WaveType.liquidReveal,
            liquidController: liquidController,
            fullTransitionValue: 880,
            enableSideReveal: true,
            preferDragFromRevealedArea: true,
            enableLoop: false,
            ignoreUserGestureWhileAnimating: true,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 24,
            child: GestureDetector(
              onTap: _navigateToLogin,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: slides[page].color == Colors.white 
                      ? const Color(0xFF1C1C1E).withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: slides[page].color == Colors.white 
                        ? const Color(0xFF1C1C1E).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: slides[page].color == Colors.white 
                        ? const Color(0xFF1C1C1E)
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 20,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(slides.length, _buildDot),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  if (page == slides.length - 1)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _navigateToLogin,
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1C1C1E),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
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
}

class OnboardingSlide {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String imagePath;
  final Color color;

  OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.imagePath,
    required this.color,
  });
}
