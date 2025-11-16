import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Get screen dimensions
  static Size getScreenSize(BuildContext context) {
    try {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery != null) {
        return mediaQuery.size;
      }
      // Fallback to a default size if MediaQuery is not available
      return const Size(360, 640);
    } catch (e) {
      // Fallback to a default size if there's an error
      return const Size(360, 640);
    }
  }

  // Get aspect ratio
  static double getAspectRatio(BuildContext context) {
    try {
      final size = getScreenSize(context);
      if (size.height > 0) {
        return size.width / size.height;
      }
      return 1.0; // Default aspect ratio
    } catch (e) {
      return 1.0; // Default aspect ratio
    }
  }

  // Check if screen is wide (16:9 or 16:10)
  static bool isWideScreen(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    final shortestSide = getScreenSize(context).shortestSide;
    // Consider displays that are clearly wide or in desktop-like modes.
    return aspectRatio >= 1.5 && shortestSide >= 500;
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

  // Check if screen is horizontal/landscape
  static bool isHorizontal(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    // Landscape mode: aspect ratio > 1 (width > height)
    return aspectRatio > 1.0;
  }

  // Check if screen is a tablet (typical tablet aspect ratios: 4:3, 16:10, etc.)
  static bool isTablet(BuildContext context) {
    try {
      final aspectRatio = getAspectRatio(context);
      final size = getScreenSize(context);
      final mediaQuery = MediaQuery.maybeOf(context);
      
      if (mediaQuery != null) {
        final shortestSide = size.width < size.height ? size.width : size.height;
        // Tablets typically have:
        // - Shortest side >= 600dp (physical size check)
        // - Aspect ratio between 0.7 and 1.7 (covers 4:3, 16:10, 3:4, 10:16)
        return shortestSide >= 600 && aspectRatio >= 0.7 && aspectRatio <= 1.7;
      }
      return false; // Default to not a tablet if MediaQuery is not available
    } catch (e) {
      return false; // Default to not a tablet on error
    }
  }

  // Check if it's a tall phone in landscape mode (like 19.3:9 rotated = aspect ratio > 2.0)
  static bool isTallPhoneInLandscape(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    // Tall phones in landscape have aspect ratio > 2.0 (like 19.3:9 = 2.14)
    // But exclude tablets
    return isHorizontal(context) && aspectRatio > 2.0 && !isTablet(context);
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
    } else if (aspectRatio < 0.5) {
      return 0.95; // Slightly smaller on very tall phones to fit content
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
    } else if (aspectRatio < 0.5) {
      return 0.95; // Slightly reduce to prevent overflow on extra-tall phones
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
    } else if (aspectRatio < 0.5) {
      return 0.9; // Tighten padding on very tall phones to avoid clipping
    } else {
      return 1.0;
    }
  }

  // Get responsive spacing
  static double getSpacing(BuildContext context, double baseSpacing) {
    return baseSpacing * getPaddingScale(context);
  }
}

