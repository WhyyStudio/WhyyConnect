import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/enhanced_home_screen.dart';
import 'utils/theme_provider.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully!');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const WhyyConnectApp(),
    ),
  );
}

class WhyyConnectApp extends StatelessWidget {
  const WhyyConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: themeProvider.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            systemNavigationBarIconBrightness: themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'Whyy Connect - Business Cards',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme.copyWith(
            textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
          ),
          darkTheme: AppTheme.darkTheme.copyWith(
            textTheme: GoogleFonts.interTextTheme(AppTheme.darkTheme.textTheme),
          ),
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return const EnhancedHomeScreen();
          }
          
          return const SplashScreen();
        },
      );
    } catch (e) {
      print('AuthWrapper error: $e');
      return const SplashScreen();
    }
  }
}
