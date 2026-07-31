import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di/service_locator.dart';
import '../auth/data/auth_repository.dart';
import '../auth/presentation/login_page.dart';
import '../home/home_page.dart';
import '../onboarding/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  final bool isConfigured;
  const SplashPage({super.key, required this.isConfigured});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _onboardingSeenKey = 'onboarding_seen_v1';
  static const _animationUrl =
      'https://lottie.host/5c30b85c-1c04-427f-ae41-99434d56f536/XyK3GOmcR4.lottie';

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _navigateToNext();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;

    final isLoggedIn = await sl<AuthRepository>().isLoggedIn;
    if (!mounted) return;

    if (isLoggedIn) {
      _replaceWith(HomePage(isConfigured: widget.isConfigured));
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final hasSeenOnboarding =
        preferences.getBool(_onboardingSeenKey) ?? false;

    _replaceWith(
      hasSeenOnboarding
          ? LoginPage(isConfigured: widget.isConfigured)
          : OnboardingPage(isConfigured: widget.isConfigured),
    );
  }

  void _replaceWith(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 420),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Expanded(
                flex: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: Lottie.network(
                      _animationUrl,
                      controller: _animationController,
                      repeat: false,
                      fit: BoxFit.contain,
                      decoder: (bytes) => LottieComposition.decodeZip(
                        bytes,
                        filePicker: (files) => files.firstWhere(
                          (file) =>
                              file.name.startsWith('animations/') &&
                              file.name.endsWith('.json'),
                          orElse: () => files.first,
                        ),
                      ),
                      onLoaded: (composition) {
                        _animationController
                          ..duration = composition.duration ~/ 3
                          ..forward(from: 0);
                      },
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 96,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ekspedisi Surat',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Powered by PT Timah Tbk',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 2),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
