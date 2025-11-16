import 'package:flutter/material.dart';

class ResponsivePage extends StatelessWidget {
  final Widget child;
  final double tabletBreakpoint;
  final double desktopBreakpoint;
  final double maxWidthTablet;
  final double maxWidthDesktop;
  final EdgeInsetsGeometry? basePadding;

  const ResponsivePage({
    super.key,
    required this.child,
    this.tabletBreakpoint = 600,
    this.desktopBreakpoint = 1024,
    this.maxWidthTablet = 840,
    this.maxWidthDesktop = 1000,
    this.basePadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= tabletBreakpoint && width < desktopBreakpoint;
        final isDesktop = width >= desktopBreakpoint;
        final maxWidth = isDesktop ? maxWidthDesktop : (isTablet ? maxWidthTablet : double.infinity);
        final horizontal = isDesktop ? 24.0 : (isTablet ? 24.0 : 20.0);
        final vertical = 20.0;

        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: basePadding ?? EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

