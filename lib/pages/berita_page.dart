import 'package:flutter/material.dart';
import '../services/berita_controller.dart';
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
  late BeritaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BeritaController()
      ..addListener(_onControllerChanged)
      ..initialize();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final fontScale = ResponsiveHelper.getFontScale(context);
    final newsItem = _controller.newsItem;
    final userDisplayName = _controller.userDisplayName ?? 'Pengguna';

    if (newsItem == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: GradientAppBar(
          title: "Berita",
          icon: Icons.newspaper_rounded,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
        ),
      );
    }

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
                news: newsItem,
                onTap: () => NewsDetailModal.show(context, newsItem),
              ),

              SizedBox(height: 20 * paddingScale),
            ],
          ),
        ),
      ),
    );
  }
}

