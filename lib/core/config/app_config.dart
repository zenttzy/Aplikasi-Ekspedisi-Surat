class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.2.9.230:3001/api',
  );

  static bool get isConfigured => !apiBaseUrl.contains('localhost') || true;
}
