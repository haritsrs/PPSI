import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/account_controller.dart';
import '../utils/haptic_helper.dart';
import '../widgets/responsive_page.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/account/profile_header_section.dart';
import '../widgets/account/account_info_form.dart';
import '../widgets/account/account_actions_section.dart';
import '../widgets/account/change_password_dialog.dart';
import '../widgets/account/verification_dialog.dart';
import '../widgets/account/image_picker_dialog.dart';
import 'logout_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AccountController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AccountController()
      ..addListener(_onControllerChanged)
      ..initialize();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
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


  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (_) => ImagePickerDialog(
        currentUser: _controller.currentUser,
        selectedImage: _controller.selectedImage,
        onPickImage: _controller.pickImage,
        onDeleteImage: () {
          _controller.clearSelectedImage();
          _controller.deleteProfilePicture();
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => ChangePasswordDialog(
        onChangePassword: (currentPassword, newPassword) =>
            _controller.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (_) => VerificationDialog(
        currentUser: _controller.currentUser,
        onSendEmail: _controller.sendVerificationEmail,
        onCheckStatus: _controller.checkEmailVerification,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: GradientAppBar(
        title: "Akun Saya",
        icon: Icons.person_rounded,
        automaticallyImplyLeading: true,
        actions: [
          if (!_controller.isEditing)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {
                  HapticHelper.lightImpact();
                  _controller.setEditing(true);
                },
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
              ),
            ),
        ],
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
                  ProfileHeaderSection(
                    currentUser: _controller.currentUser,
                    selectedImage: _controller.selectedImage,
                    isUploadingPhoto: _controller.isUploadingPhoto,
                    onImageTap: _showImagePickerDialog,
                  ),
                  const SizedBox(height: 24),
                  AccountInfoForm(
                    formKey: _controller.formKey,
                    nameController: _controller.nameController,
                    emailController: _controller.emailController,
                    currentUser: _controller.currentUser,
                    isEditing: _controller.isEditing,
                    isLoading: _controller.isLoading,
                    onCancel: _controller.cancelEdit,
                    onSave: _controller.saveProfile,
                  ),
                  const SizedBox(height: 24),
                  AccountActionsSection(
                    currentUser: _controller.currentUser,
                    onChangePassword: _showChangePasswordDialog,
                    onVerifyEmail: _showVerificationDialog,
                    onCheckVerification: _controller.checkEmailVerification,
                    onLogout: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LogoutPage()),
                    ),
                  ),
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
