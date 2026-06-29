import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/di/service_locator.dart';
import '../data/auth_repository.dart';
import 'login_page.dart';

class NonaktifPage extends StatelessWidget {
  const NonaktifPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block_rounded, size: 80, color: Colors.red)
                  .animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              const Text(
                'Akun Dinonaktifkan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
              const Text(
                'Akun kurir Anda telah dinonaktifkan oleh Admin. Anda tidak dapat mengakses sistem.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () async {
                  await sl<AuthRepository>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage(isConfigured: true)),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
