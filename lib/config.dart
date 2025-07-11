/// Configuration constants for the SmarterNEET app
class AppConfig {
  /// API Configuration
  static const String apiBaseUrl = 'https://dev.smarterneet.com/api';
  static const String subjectsEndpoint = '/subjects';

  /// Vercel Protection Bypass
  /// To configure:
  /// 1. Go to your Vercel project settings
  /// 2. Navigate to "Functions" > "Protection Bypass for Automation"
  /// 3. Generate a bypass secret
  /// 4. Replace the null value below with your secret string
  ///
  /// Example: static const String? vercelBypassSecret = 'your-secret-here';
  static const String vercelBypassSecret = "Bn6ymsvH9Of7fNjsgP5cn7BEmeH2CI03";

  /// API Request Configuration
  static const Duration requestTimeout = Duration(seconds: 30);
  static const int maxRetries = 5;
  static const String userAgent =
      'SmarterNEET-Mobile/1.0.0 (Flutter Mobile App)';

  /// Fallback Data Configuration
  static const bool enableFallbackData = true;

  /// Debug Configuration
  static const bool enableApiLogging = true;
}
