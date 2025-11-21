import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/account_controller.dart';
import '../widgets/responsive_page.dart';
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

  void _showSnackBar(String message, {bool isError = false, Duration? duration}) {
    if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 3),
          ),
        );
      }

  Future<void> _handleSaveProfile() async {
    try {
      await _controller.saveProfile();
      _showSnackBar('Profil berhasil diperbarui');
    } catch (e) {
      _showSnackBar('Gagal memperbarui profil: $e', isError: true);
    }
  }

  Future<void> _handlePickImage(ImageSource source) async {
    try {
      await _controller.pickImage(source);
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: $e', isError: true);
    }
  }
  
  Future<void> _handleDeleteProfilePicture() async {
    try {
      await _controller.deleteProfilePicture();
      _showSnackBar('Foto profil berhasil dihapus');
    } catch (e) {
      _showSnackBar('Gagal menghapus foto: $e', isError: true);
    }
  }
  
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (_) => ImagePickerDialog(
        currentUser: _controller.currentUser,
        selectedImage: _controller.selectedImage,
        onPickImage: _handlePickImage,
        onDeleteImage: () {
          _controller.clearSelectedImage();
          _handleDeleteProfilePicture();
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

  Future<void> _handleSendVerificationEmail() async {
    try {
      await _controller.sendVerificationEmail();
      _showSnackBar(
        'Email verifikasi telah dikirim. Silakan cek inbox Anda dan klik tautan verifikasi.',
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      _showSnackBar('Gagal mengirim email verifikasi: $e', isError: true);
    }
  }

  Future<void> _handleCheckEmailVerification() async {
    try {
      await _controller.checkEmailVerification();
      final isVerified = _controller.currentUser?.emailVerified ?? false;
      _showSnackBar(
        isVerified
            ? 'Email berhasil diverifikasi!'
            : 'Email belum diverifikasi. Silakan cek email Anda dan klik tautan verifikasi.',
        isError: !isVerified,
      );
    } catch (e) {
      _showSnackBar('Gagal memeriksa status verifikasi: $e', isError: true);
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (_) => VerificationDialog(
        currentUser: _controller.currentUser,
        onSendEmail: _handleSendVerificationEmail,
        onCheckStatus: _handleCheckEmailVerification,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Akun Saya",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
                  HapticFeedback.lightImpact();
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
                    onSave: _handleSaveProfile,
                        ),
                        const SizedBox(height: 24),
                  AccountActionsSection(
                    currentUser: _controller.currentUser,
                    onChangePassword: _showChangePasswordDialog,
                    onVerifyEmail: _showVerificationDialog,
                    onCheckVerification: _handleCheckEmailVerification,
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
