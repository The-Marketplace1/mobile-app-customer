import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/configuration_screen.dart';
import 'core/network/api_client.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/realtime/realtime_client.dart';
import 'core/storage/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isApiConfigured) {
    runApp(const ConfigurationScreen());
    return;
  }

  if (AppConfig.mapboxAccessToken.isNotEmpty) {
    MapboxOptions.setAccessToken(AppConfig.mapboxAccessToken);
  }

  final sessionStore = SessionStore();
  final accessToken = await sessionStore.accessToken;
  final apiClient = ApiClient(sessionStore);
  final realtimeClient = RealtimeClient(sessionStore);
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  runApp(
    MarketplaceApp(
      apiClient: apiClient,
      realtimeClient: realtimeClient,
      notificationService: notificationService,
      initialLocation: accessToken == null || accessToken.isEmpty
          ? '/auth'
          : '/home',
    ),
  );
}

