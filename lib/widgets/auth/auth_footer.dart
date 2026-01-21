import 'package:flutter/material.dart';

class AuthFooter extends StatelessWidget {
  final String text;

  const AuthFooter({
    super.key,
    this.text = '© 2024 KiosDarma. All rights reserved.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
      ),
    );
  }
}


