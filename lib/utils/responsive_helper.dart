import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Get screen dimensions
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  // Get aspect ratio
  static double getAspectRatio(BuildContext context) {
    final size = getScreenSize(context);
    return size.width / size.height;
  }

  // Check if screen is wide (16:9 or 16:10)
  static bool isWideScreen(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    // 16:9 = 1.78, 16:10 = 1.6, 4:3 = 1.33
    return aspectRatio >= 1.5;
  }

  // Check if screen is very wide (16:9)
  static bool isVeryWideScreen(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    return aspectRatio >= 1.7;
  }

  // Check if screen is vertical (portrait mode)
  static bool isVertical(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    // Portrait mode: aspect ratio < 1 (width < height)
    return aspectRatio < 1.0;
  }

  // Check if screen is tall/narrow (like Samsung S22 Ultra in portrait: 19.3:9 = ~0.466)
  static bool isTallScreen(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    // Very tall screens have aspect ratio < 0.5
    return aspectRatio < 0.5;
  }

  // Get responsive AppBar height based on aspect ratio
  static double getAppBarHeight(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    if (aspectRatio >= 1.7) {
      // 16:9 - taller AppBar
      return 80.0;
    } else if (aspectRatio >= 1.5) {
      // 16:10 - medium AppBar
      return 70.0;
    } else {
      // 4:3 or narrower - standard AppBar
      return 56.0;
    }
  }

  // Get responsive BottomNavigationBar height
  static double getBottomNavBarHeight(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    if (aspectRatio >= 1.7) {
      // 16:9 - taller bottom bar
      return 80.0;
    } else if (aspectRatio >= 1.5) {
      // 16:10 - medium bottom bar
      return 70.0;
    } else {
      // 4:3 or narrower - standard height
      return 60.0;
    }
  }

  // Get responsive icon size multiplier
  static double getIconScale(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    if (aspectRatio >= 1.7) {
      return 1.3; // 30% larger for 16:9
    } else if (aspectRatio >= 1.5) {
      return 1.15; // 15% larger for 16:10
    } else {
      return 1.0; // Normal size for 4:3
    }
  }

  // Get responsive font size multiplier
  static double getFontScale(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    if (aspectRatio >= 1.7) {
      return 1.2;
    } else if (aspectRatio >= 1.5) {
      return 1.1;
    } else {
      return 1.0;
    }
  }

  // Get responsive padding multiplier
  static double getPaddingScale(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    if (aspectRatio >= 1.7) {
      return 1.25;
    } else if (aspectRatio >= 1.5) {
      return 1.15;
    } else {
      return 1.0;
    }
  }

  // Get responsive spacing
  static double getSpacing(BuildContext context, double baseSpacing) {
    return baseSpacing * getPaddingScale(context);
  }
}

