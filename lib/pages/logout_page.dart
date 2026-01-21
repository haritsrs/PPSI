import 'package:flutter/material.dart';
import '../controllers/logout_controller.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/responsive_page.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/auth/confirmation_content.dart';
import '../widgets/auth/auth_button.dart';
import '../widgets/auth/info_card.dart';

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late LogoutController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LogoutController();
    _controller.addListener(_handleControllerChange);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _controller.logout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const GradientAppBar(
        title: "Keluar",
        icon: Icons.logout_rounded,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ResponsivePage(
            child: ConfirmationContent(
              icon: Icons.logout_rounded,
              iconColor: const Color(0xFFEF4444),
              iconBackgroundColor: const Color(0xFFEF4444),
              title: "Keluar dari Akun?",
              description:
                  "Anda akan keluar dari aplikasi. Anda perlu login kembali untuk mengakses akun Anda.",
              additionalContent: Column(
                children: [
                  AuthButton(
                    text: 'Ya, Keluar',
                    icon: Icons.logout_rounded,
                    onPressed: _handleLogout,
                    isLoading: _controller.isLoggingOut,
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  AuthButton(
                    text: 'Batal',
                    icon: Icons.cancel_rounded,
                    isOutlined: true,
                    onPressed: _controller.isLoggingOut
                        ? null
                        : () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 32),
                  const InfoCard(
                    message: "Data Anda aman dan tersimpan di cloud",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


