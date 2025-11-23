import 'package:flutter/material.dart';
import '../services/register_controller.dart';
import '../utils/validation_utils.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/responsive_page.dart';
import '../widgets/auth/login_header.dart';
import '../widgets/auth/auth_form_container.dart';
import '../widgets/auth/auth_form_field.dart';
import '../widgets/auth/terms_and_conditions_checkbox.dart';
import '../widgets/auth/auth_button.dart';
import '../widgets/auth/auth_divider.dart';
import '../widgets/auth/auth_footer.dart';
import '../widgets/auth/back_button_app_bar.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late RegisterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RegisterController();
    _controller.addListener(_handleControllerChange);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
      begin: const Offset(0, 0.5),
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

  Future<void> _handleRegister() async {
    try {
      await _controller.register();
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Akun berhasil dibuat!');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        // Use friendly error message instead of exposing exception details
        final message = e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Terjadi kesalahan saat mendaftar. Silakan coba lagi.';
        if (message.contains('syarat dan ketentuan') || message.contains('Format email')) {
          SnackbarHelper.showInfo(context, message);
        } else {
          SnackbarHelper.showError(context, message);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const BackButtonAppBar(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ResponsivePage(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const LoginHeader(
                      title: "Buat Akun Baru",
                      subtitle: "Daftar untuk mulai menggunakan KiosDarma",
                      icon: Icons.person_add_rounded,
                    ),
                    const SizedBox(height: 40),
                    AuthFormContainer(
                      title: "Informasi Akun",
                      child: Form(
                        key: _controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AuthFormField(
                              controller: _controller.nameController,
                              labelText: 'Nama Lengkap',
                              hintText: 'Masukkan nama lengkap Anda',
                              prefixIcon: Icons.person_rounded,
                              textInputAction: TextInputAction.next,
                              validator: (value) =>
                                  ValidationUtils.validateMinLength(value, 2, fieldName: 'Nama'),
                            ),
                            const SizedBox(height: 20),
                            AuthFormField(
                              controller: _controller.emailController,
                              labelText: 'Email',
                              hintText: 'Masukkan email Anda',
                              prefixIcon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: ValidationUtils.validateEmail,
                            ),
                            const SizedBox(height: 20),
                            AuthFormField(
                              controller: _controller.passwordController,
                              labelText: 'Password',
                              hintText: 'Masukkan password Anda',
                              prefixIcon: Icons.lock_rounded,
                              obscureText: _controller.obscurePassword,
                              textInputAction: TextInputAction.next,
                              onToggleVisibility: _controller.togglePasswordVisibility,
                              validator: ValidationUtils.validatePassword,
                            ),
                            const SizedBox(height: 20),
                            AuthFormField(
                              controller: _controller.confirmPasswordController,
                              labelText: 'Konfirmasi Password',
                              hintText: 'Masukkan ulang password Anda',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _controller.obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onToggleVisibility: _controller.toggleConfirmPasswordVisibility,
                              onSubmitted: _handleRegister,
                              validator: (value) => ValidationUtils.validatePasswordConfirmation(
                                    value,
                                    _controller.passwordController.text,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            TermsAndConditionsCheckbox(
                              value: _controller.agreeToTerms,
                              onChanged: _controller.setAgreeToTerms,
                            ),
                            const SizedBox(height: 24),
                            AuthButton(
                              text: 'Daftar',
                              icon: Icons.person_add_rounded,
                              onPressed: _handleRegister,
                              isLoading: _controller.isLoading,
                            ),
                            const SizedBox(height: 24),
                            const AuthDivider(),
                            const SizedBox(height: 24),
                            AuthButton(
                              text: 'Sudah punya akun? Masuk',
                              icon: Icons.login_rounded,
                              isOutlined: true,
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const AuthFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
