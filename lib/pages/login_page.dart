import 'package:flutter/material.dart';
import '../services/login_controller.dart';
import '../utils/validation_utils.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/responsive_page.dart';
import '../widgets/auth/login_header.dart';
import '../widgets/auth/auth_form_container.dart';
import '../widgets/auth/auth_form_field.dart';
import '../widgets/auth/remember_me_forgot_password_row.dart';
import '../widgets/auth/auth_button.dart';
import '../widgets/auth/auth_divider.dart';
import '../widgets/auth/auth_footer.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
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

  Future<void> _handleSignIn() async {
    try {
      await _controller.signIn();
    } catch (e) {
      if (mounted) {
        // Use friendly error message instead of exposing exception details
        final message = e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Terjadi kesalahan saat masuk. Silakan coba lagi.';
        SnackbarHelper.showError(context, message);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    try {
      await _controller.forgotPassword();
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'Email reset password telah dikirim');
      }
    } catch (e) {
      if (mounted) {
        // Use friendly error message instead of exposing exception details
        final message = e is Exception ? e.toString().replaceAll('Exception: ', '') : 'Terjadi kesalahan. Silakan coba lagi.';
        if (message.contains('Masukkan email') || message.contains('Format email')) {
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
                    const SizedBox(height: 40),
                    const LoginHeader(
                      title: "Selamat Datang",
                      subtitle: "Masuk ke KiosDarma untuk melanjutkan",
                    ),
                    const SizedBox(height: 48),
                    AuthFormContainer(
                      title: "Masuk",
                      child: Form(
                        key: _controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              textInputAction: TextInputAction.done,
                              onToggleVisibility: _controller.togglePasswordVisibility,
                              onSubmitted: _handleSignIn,
                              validator: ValidationUtils.validatePassword,
                            ),
                            const SizedBox(height: 16),
                            RememberMeForgotPasswordRow(
                              rememberMe: _controller.rememberMe,
                              onRememberMeChanged: _controller.setRememberMe,
                              onForgotPassword: _handleForgotPassword,
                            ),
                            const SizedBox(height: 24),
                            AuthButton(
                              text: 'Masuk',
                              icon: Icons.login_rounded,
                              onPressed: _handleSignIn,
                              isLoading: _controller.isLoading,
                            ),
                            const SizedBox(height: 24),
                            const AuthDivider(),
                            const SizedBox(height: 24),
                            AuthButton(
                              text: 'Daftar Akun Baru',
                              icon: Icons.person_add_rounded,
                              isOutlined: true,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
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
