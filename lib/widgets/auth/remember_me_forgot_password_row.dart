import 'package:flutter/material.dart';

class RememberMeForgotPasswordRow extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onForgotPassword;

  const RememberMeForgotPasswordRow({
    super.key,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: (value) => onRememberMeChanged(value ?? false),
              activeColor: const Color(0xFF6366F1),
            ),
            Text(
              'Ingat saya',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        TextButton(
          onPressed: onForgotPassword,
          child: Text(
            'Lupa Password?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}


