import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/news_service.dart';
import '../utils/responsive_helper.dart';
import '../widgets/responsive_page.dart';
import '../widgets/news_card.dart';
import '../widgets/news_detail_modal.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/welcome_header.dart';

class BeritaPage extends StatefulWidget {
  const BeritaPage({super.key});

  @override
  State<BeritaPage> createState() => _BeritaPageState();
}

class _BeritaPageState extends State<BeritaPage> {
  Timer? _timer;
  final Map<String, dynamic> _newsItem = NewsService.getDefaultNews();

  @override
  void initState() {
    super.initState();
    // Update every minute to refresh the time display
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final fontScale = ResponsiveHelper.getFontScale(context);
    final userDisplayName = AuthService.getUserDisplayName(AuthService.currentUser);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: GradientAppBar(
        title: "Berita",
        icon: Icons.newspaper_rounded,
      ),
      body: ResponsivePage(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeHeader(userName: userDisplayName),
              SizedBox(height: 24 * paddingScale),

              Text(
                "Berita & Update",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.w700,
                      fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * fontScale,
                    ),
              ),

              SizedBox(height: 16 * paddingScale),

              NewsCard(
                news: _newsItem,
                onTap: () => NewsDetailModal.show(context, _newsItem),
              ),

              SizedBox(height: 20 * paddingScale),
            ],
          ),
        ),
      ),
    );
  }
}

