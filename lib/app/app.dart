import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/realtime/realtime_client.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_screen.dart';
import '../features/bookings/booking_flow_screen.dart';
import '../features/bookings/bookings_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/disputes/dispute_screen.dart';
import '../features/communication/conversation_screen.dart';
import '../features/communication/messages_screen.dart';
import '../features/discovery/discovery_screen.dart';
import '../features/discovery/professional_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/reviews/review_screen.dart';
import '../features/tracking/tracking_screen.dart';
import '../shared/widgets/app_scaffold.dart';

class MarketplaceApp extends StatefulWidget {
  const MarketplaceApp({
    required this.apiClient,
    required this.realtimeClient,
    required this.notificationService,
    this.initialLocation = '/auth',
    super.key,
  });

  final ApiClient apiClient;
  final RealtimeClient realtimeClient;
  final LocalNotificationService notificationService;
  final String initialLocation;

  @override
  State<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends State<MarketplaceApp> {
  late final ValueNotifier<bool> _authenticated = ValueNotifier(
    widget.initialLocation != '/auth',
  );
  late final GoRouter _router = _buildRouter();
  StreamSubscription<Map<String, dynamic>>? _notificationEvents;

  @override
  void initState() {
    super.initState();
    widget.apiClient.onSessionExpired = () => _authenticated.value = false;
    widget.notificationService.onNotificationTap = () =>
        _router.go('/notifications');
    _notificationEvents = widget.realtimeClient.events.listen(
      widget.notificationService.showRealtimeNotification,
    );
    if (widget.initialLocation != '/auth') {
      unawaited(_connectRealtime());
    }
  }

  Future<void> _connectRealtime() async {
    try {
      await widget.realtimeClient.connect();
    } on Object {
      // Realtime is optional; API refresh remains available when it is offline.
    }
  }

  @override
  void dispose() {
    _notificationEvents?.cancel();
    widget.realtimeClient.dispose();
    widget.apiClient.onSessionExpired = null;
    _authenticated.dispose();
    _router.dispose();
    super.dispose();
  }

  GoRouter _buildRouter() {
    final shell = ShellRoute(
      builder: (context, state, child) =>
          AppScaffold(currentLocation: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              DiscoveryScreen(apiClient: widget.apiClient, showHome: true),
        ),
        GoRoute(
          path: '/discover',
          builder: (context, state) =>
              DiscoveryScreen(apiClient: widget.apiClient),
        ),
        GoRoute(
          path: '/professionals/:id',
          builder: (context, state) => ProfessionalScreen(
            apiClient: widget.apiClient,
            professionalId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/bookings',
          builder: (context, state) =>
              BookingsScreen(apiClient: widget.apiClient),
        ),
        GoRoute(
          path: '/bookings/:id/tracking',
          builder: (context, state) => TrackingScreen(
            apiClient: widget.apiClient,
            realtimeClient: widget.realtimeClient,
            bookingId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/booking/new',
          builder: (context, state) => BookingFlowScreen(
            apiClient: widget.apiClient,
            professionalId: state.uri.queryParameters['professionalId'],
          ),
        ),
        GoRoute(
          path: '/checkout/:id',
          builder: (context, state) => CheckoutScreen(
            apiClient: widget.apiClient,
            bookingId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/bookings/:id/review',
          builder: (context, state) => ReviewScreen(
            apiClient: widget.apiClient,
            bookingId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/bookings/:id/dispute',
          builder: (context, state) => DisputeScreen(
            apiClient: widget.apiClient,
            bookingId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/messages',
          builder: (context, state) =>
              MessagesScreen(apiClient: widget.apiClient),
        ),
        GoRoute(
          path: '/messages/:id',
          builder: (context, state) => ConversationScreen(
            apiClient: widget.apiClient,
            realtimeClient: widget.realtimeClient,
            conversationId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) =>
              NotificationsScreen(apiClient: widget.apiClient),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              ProfileScreen(apiClient: widget.apiClient),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsScreen(
            apiClient: widget.apiClient,
            notificationService: widget.notificationService,
            onSignedOut: () => _authenticated.value = false,
          ),
        ),
      ],
    );

    return GoRouter(
      initialLocation: widget.initialLocation,
      refreshListenable: _authenticated,
      redirect: (context, state) {
        final atAuth = state.uri.path == '/auth';
        if (!_authenticated.value && !atAuth) return '/auth';
        if (_authenticated.value && atAuth) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (_, _) => '/home'),
        GoRoute(
          path: '/auth',
          builder: (context, state) => AuthScreen(
            apiClient: widget.apiClient,
            realtimeClient: widget.realtimeClient,
            onAuthenticated: () => _authenticated.value = true,
          ),
        ),
        shell,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Marketplace',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

