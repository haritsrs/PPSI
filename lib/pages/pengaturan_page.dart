import 'package:flutter/material.dart';
import '../controllers/settings_controller.dart';
import '../widgets/responsive_page.dart';
import '../widgets/settings/settings_app_bar.dart';
import '../widgets/settings/settings_profile_section.dart';
import '../widgets/settings/general_settings_section.dart';
import '../widgets/settings/notifications_settings_section.dart';
import '../widgets/settings/business_settings_section.dart';
import '../widgets/settings/data_security_settings_section.dart';
import '../widgets/settings/support_settings_section.dart';
import '../widgets/settings/settings_dialogs.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController()
      ..addListener(_onControllerChanged)
      ..initialize();

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

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle error messages
    if (_controller.errorMessage != null && !_controller.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: SettingsAppBar(
        onReset: () => ResetSettingsDialog.show(context, _controller),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ResponsivePage(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsProfileSection(
                    onEditProfile: () => EditProfileDialog.show(context),
                  ),
                  const SizedBox(height: 24),
                  GeneralSettingsSection(controller: _controller),
                  const SizedBox(height: 16),
                  NotificationsSettingsSection(controller: _controller),
                  const SizedBox(height: 16),
                  BusinessSettingsSection(controller: _controller),
                  const SizedBox(height: 16),
                  DataSecuritySettingsSection(controller: _controller),
                  const SizedBox(height: 16),
                  SupportSettingsSection(controller: _controller),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
