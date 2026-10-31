import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/notifications/local_notification_service.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.apiClient,
    required this.notificationService,
    required this.onSignedOut,
    super.key,
  });

  final ApiClient apiClient;
  final LocalNotificationService notificationService;
  final VoidCallback onSignedOut;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<Map<String, bool>> request;
  Map<String, bool>? preferences;
  final Set<String> saving = {};

  @override
  void initState() {
    super.initState();
    request = _loadPreferences();
  }

  Future<Map<String, bool>> _loadPreferences() async {
    final values = await widget.apiClient.notificationPreferences();
    preferences = {
      'bookingUpdates': values['bookingUpdates'] ?? true,
      'messages': values['messages'] ?? true,
      'marketing': values['marketing'] ?? false,
    };
    return preferences!;
  }

  Future<void> updatePreference(String key, bool value) async {
    final current = preferences;
    if (current == null || saving.contains(key)) return;
    final next = {...current, key: value};
    setState(() {
      preferences = next;
      saving.add(key);
    });
    try {
      await widget.apiClient.updateNotificationPreferences(next);
    } catch (_) {
      if (!mounted) return;
      setState(() => preferences = current);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your notification preference could not be saved.'),
        ),
      );
    } finally {
      if (mounted) setState(() => saving.remove(key));
    }
  }

  Future<void> enableNotifications() async {
    try {
      final granted = await widget.notificationService.requestPermission();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Notifications are enabled on this device.'
                : 'Notifications are blocked in your device settings.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission is unavailable.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PagePadding(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 18),
        FutureBuilder<Map<String, bool>>(
          future: request,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState();
            }
            if (snapshot.hasError || preferences == null) {
              return ErrorState(
                message: 'We could not load your notification preferences.',
                onRetry: () => setState(() {
                  preferences = null;
                  request = _loadPreferences();
                }),
              );
            }
            final values = preferences!;
            return SectionCard(
              child: Column(
                children: [
                  _toggle(
                    'Booking updates',
                    'bookingUpdates',
                    values['bookingUpdates']!,
                  ),
                  _toggle(
                    'Messages and calls',
                    'messages',
                    values['messages']!,
                  ),
                  _toggle(
                    'Product and marketing',
                    'marketing',
                    values['marketing']!,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: enableNotifications,
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Enable notifications on this device'),
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sign out'),
                leading: const Icon(Icons.logout_rounded),
                onTap: () async {
                  try {
                    await widget.apiClient.logout();
                  } catch (_) {
                    // The local session is cleared even when the service is offline.
                  }
                  if (!context.mounted) return;
                  widget.onSignedOut();
                  context.go('/auth');
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _toggle(String label, String key, bool value) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: value,
    onChanged: saving.contains(key)
        ? null
        : (changed) => updatePreference(key, changed),
  );
}

