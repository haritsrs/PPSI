import 'package:flutter/material.dart';
import 'dart:math' as math;

class ResponsiveHelper {
  // CANONICAL METHODS - Use with LayoutBuilder
  
  /// Check if layout is horizontal (landscape-like)
  /// Must be called from LayoutBuilder with BoxConstraints
  static bool isHorizontal(BoxConstraints constraints) {
    return constraints.maxWidth / constraints.maxHeight > 1.1;
  }

  /// Check if layout is vertical (portrait-like)
  static bool isVertical(BoxConstraints constraints) {
    return !isHorizontal(constraints);
  }

  /// Check if device is tablet-sized (7"+ screens)
  static bool isTablet(BoxConstraints constraints) {
    return math.min(constraints.maxWidth, constraints.maxHeight) >= 600;
  }

  /// Check if screen is wide enough for desktop-like layouts
  static bool isWideScreen(BoxConstraints constraints) {
    return constraints.maxWidth >= constraints.maxHeight * 1.3;
  }

  // DEPRECATED CONTEXT-BASED METHODS - For backward compatibility only
  // New code should use LayoutBuilder + BoxConstraints versions above
  
  // Get screen dimensions
  static Size getScreenSize(BuildContext context) {
    try {
      final mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery != null) {
        return mediaQuery.size;
      }
      return const Size(360, 640);
    } catch (e) {
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
      return 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  @Deprecated('Use LayoutBuilder with isWideScreen(constraints)')
  static bool isWideScreenContext(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    final shortestSide = getScreenSize(context).shortestSide;
    return aspectRatio >= 1.5 && shortestSide >= 500;
  }

  @Deprecated('Use LayoutBuilder with isHorizontal(constraints)')
  static bool isHorizontalContext(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    return aspectRatio > 1.0;
  }

  @Deprecated('Use LayoutBuilder with isVertical(constraints)')
  static bool isVerticalContext(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    return aspectRatio < 1.0;
  }

  @Deprecated('Use LayoutBuilder with isTablet(constraints)')
  static bool isTabletContext(BuildContext context) {
    try {
      final aspectRatio = getAspectRatio(context);
      final size = getScreenSize(context);
      final mediaQuery = MediaQuery.maybeOf(context);
      
      if (mediaQuery != null) {
        final shortestSide = size.width < size.height ? size.width : size.height;
        return shortestSide >= 600 && aspectRatio >= 0.7 && aspectRatio <= 1.7;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static bool isVeryWideScreen(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    return aspectRatio >= 1.7;
  }

  static bool isTallScreen(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    return aspectRatio < 0.5;
  }

  static bool isTallPhoneInLandscape(BuildContext context) {
    final aspectRatio = getAspectRatio(context);
    final size = getScreenSize(context);
    final shortestSide = size.width < size.height ? size.width : size.height;
    return aspectRatio > 2.0 && shortestSide < 600;
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


