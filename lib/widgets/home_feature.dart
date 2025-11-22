import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class HomeFeature extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const HomeFeature({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<HomeFeature> createState() => _HomeFeatureState();
}

class _HomeFeatureState extends State<HomeFeature>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconScale = ResponsiveHelper.getIconScale(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualIconSize = (constraints.maxWidth * 0.35 * iconScale).clamp(20.0, 36.0);
        final actualPadding = (actualIconSize * 0.5).clamp(10.0, 16.0);
        
        return GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          onTap: widget.onTap,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: widget.color.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(actualPadding),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: actualIconSize,
                    ),
                  ),
                  SizedBox(height: 8 * ResponsiveHelper.getPaddingScale(context)),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF374151),
                      fontWeight: FontWeight.w600,
                      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) * ResponsiveHelper.getFontScale(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

