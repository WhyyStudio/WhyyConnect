import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color primary = Color(0xFFFCC61D);
  static const Color primaryLight = Color(0xFFFFB200);
  static const Color primaryDark = Color(0xFFE6B800);
  
  // Dark Mode Colors
  static const Color primaryDarkMode = Color(0xFFFFD700);
  static const Color primaryLightDarkMode = Color(0xFFFFE55C);
  
  static const Color secondary = Color(0xFF5856D6);
  static const Color secondaryLight = Color(0xFF7B61FF);
  static const Color secondaryDarkMode = Color(0xFF5E5CE6);
  
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  
  // Dark Mode Status Colors
  static const Color successDark = Color(0xFF30D158);
  static const Color warningDark = Color(0xFFFF9F0A);
  static const Color errorDark = Color(0xFFFF453A);
  
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  
  // Dark Mode Background Colors
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color cardDark = Color(0xFF1C1C1E);
  
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);
  
  // Dark Mode Text Colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color textTertiaryDark = Color(0xFF48484A);
  
  static const Color border = Color(0xFFE5E5EA);
  static const Color divider = Color(0xFFE5E5EA);
  
  // Dark Mode Border Colors
  static const Color borderDark = Color(0xFF38383A);
  static const Color dividerDark = Color(0xFF38383A);
  
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0A000000);
  
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFFFCC61D),
    Color(0xFFFFB200),
  ];
  
  static const List<Color> primaryGradientDark = [
    Color(0xFFFFD700),
    Color(0xFFFFE55C),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF5856D6),
    Color(0xFF7B61FF),
  ];
  
  static const List<Color> secondaryGradientDark = [
    Color(0xFF5E5CE6),
    Color(0xFF8E8EF0),
  ];
  
  // Helper methods for theme-aware colors
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? primaryDarkMode 
        : primary;
  }
  
  static Color getSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? secondaryDarkMode 
        : secondary;
  }
  
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? backgroundDark 
        : background;
  }
  
  static Color getSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? surfaceDark 
        : surface;
  }
  
  static Color getCard(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? cardDark 
        : card;
  }
  
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? textPrimaryDark 
        : textPrimary;
  }
  
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? textSecondaryDark 
        : textSecondary;
  }
  
  static Color getTextTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? textTertiaryDark 
        : textTertiary;
  }
  
  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? borderDark 
        : border;
  }
  
  static Color getDivider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? dividerDark 
        : divider;
  }
  
  static Color getError(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? errorDark 
        : error;
  }
  
  static Color getSuccess(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? successDark 
        : success;
  }
  
  static Color getWarning(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? warningDark 
        : warning;
  }
  
  static List<Color> getPrimaryGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? primaryGradientDark 
        : primaryGradient;
  }
  
  static List<Color> getSecondaryGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? secondaryGradientDark 
        : secondaryGradient;
  }
}
