class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const realtimeUrl = String.fromEnvironment('REALTIME_URL');
  static const mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
  );
  static const appName = 'Marketplace';

  static bool get isApiConfigured => isValidApiBaseUrl(apiBaseUrl);

  static bool isValidApiBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        const {
          'example.com',
          'example.invalid',
          'api.marketplace.example',
        }.contains(uri.host)) {
      return false;
    }
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(uri.host);
  }
}

