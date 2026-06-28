/// Konfigurasi aplikasi yang dibaca saat compile-time via `--dart-define`.
///
/// Contoh menjalankan:
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
///
/// Nilai default di bawah memudahkan menjalankan aplikasi dalam mode
/// pengembangan tanpa harus selalu menyetel dart-define. Untuk produksi,
/// nilai WAJIB diisi lewat dart-define.
class AppConfig {
  AppConfig._();

  /// Base URL project Supabase, mis. `https://abcd.supabase.co`.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://CHANGE_ME.supabase.co',
  );

  /// Anon key Supabase (dipakai sebagai apikey header untuk Auth/REST).
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Base URL Edge Functions: `<supabaseUrl>/functions/v1`.
  static String get functionsBaseUrl => '$supabaseUrl/functions/v1';

  /// Base URL Supabase Auth (GoTrue): `<supabaseUrl>/auth/v1`.
  static String get authBaseUrl => '$supabaseUrl/auth/v1';

  /// Apakah konfigurasi sudah valid (URL & anon key terisi).
  static bool get isConfigured =>
      !supabaseUrl.contains('CHANGE_ME') && supabaseAnonKey.isNotEmpty;
}
