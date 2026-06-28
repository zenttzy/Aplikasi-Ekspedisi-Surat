import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../home/home_page.dart';

class SplashPage extends StatefulWidget {
  final bool isConfigured;
  const SplashPage({super.key, required this.isConfigured});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    // Navigate to Home/Login
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomePage(isConfigured: widget.isConfigured),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Surat Digital',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
                letterSpacing: 1.2,
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutQuad),
            const SizedBox(height: 8),
            const Text(
              'by',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            const SizedBox(height: 12),
            // Placeholder for PT Timah logo (can be replaced with asset later)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PT TIMAH',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 2.0,
                ),
              ),
            ).animate().fadeIn(delay: 800.ms, duration: 600.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.elasticOut),
          ],
        ),
      ),
    );
  }
}
