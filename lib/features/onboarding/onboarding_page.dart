import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/presentation/login_page.dart';

class OnboardingPage extends StatefulWidget {
  final bool isConfigured;
  const OnboardingPage({super.key, required this.isConfigured});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _onboardingSeenKey = 'onboarding_seen_v1';
  final _pageController = PageController();
  var _currentPage = 0;
  var _isCompleting = false;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.assignment_turned_in_outlined,
      title: 'Tugas pengiriman yang terarah',
      description:
          'Lihat surat yang ditugaskan khusus untuk Anda dan ambil tugas saat siap dikirim.',
    ),
    _OnboardingSlide(
      icon: Icons.location_on_outlined,
      title: 'Bukti pengiriman terverifikasi',
      description:
          'Ambil foto bukti pengiriman dengan lokasi GPS dan nama penerima secara langsung.',
    ),
    _OnboardingSlide(
      icon: Icons.sync_outlined,
      title: 'Tetap bekerja saat offline',
      description:
          'Data tugas dan bukti pengiriman akan disinkronkan otomatis saat koneksi tersedia.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingSeenKey, true);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginPage(isConfigured: widget.isConfigured),
      ),
    );
  }

  void _next() {
    if (_currentPage == _slides.length - 1) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isCompleting ? null : _completeOnboarding,
                  child: const Text('Lewati'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (_, index) => _OnboardingSlideView(
                    slide: _slides[index],
                    isActive: index == _currentPage,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentPage ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? theme.colorScheme.primary
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isCompleting ? null : _next,
                  child: _isCompleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentPage == _slides.length - 1
                              ? 'Mulai Masuk'
                              : 'Selanjutnya',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _OnboardingSlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  final bool isActive;

  const _OnboardingSlideView({required this.slide, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isActive ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(
                slide.icon,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              slide.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
