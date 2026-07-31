import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/di/service_locator.dart';
import '../data/auth_repository.dart';
import '../../home/home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final bool isConfigured;
  const LoginPage({super.key, required this.isConfigured});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await sl<AuthRepository>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (result.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(isConfigured: widget.isConfigured)),
        );
      } else {
        setState(() => _errorMessage = result.error ?? 'Gagal login');
      }
    } catch (_) {
      setState(() {
        _errorMessage =
            'Login belum berhasil. Periksa koneksi Anda dan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      size: 42,
                      color: theme.colorScheme.primary,
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(),
                  const SizedBox(height: 16),
                  Text('Ekspedisi Surat',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold))
                      .animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text('Masuk sebagai kurir untuk mengelola tugas pengiriman.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                      .animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 32),
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tidak dapat masuk',
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tutup pesan',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _errorMessage = null),
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        (val == null || val.isEmpty) ? 'Email wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) =>
                        (val == null || val.isEmpty) ? 'Kata sandi wajib diisi' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Masuk'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterPage())),
                    child: const Text('Belum punya akun? Daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
