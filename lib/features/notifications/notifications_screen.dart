import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/models.dart';
import '../../shared/widgets/marketplace_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationItem>> request;

  @override
  void initState() {
    super.initState();
    request = widget.apiClient.notifications();
  }

  Future<void> markRead(String id) async {
    try {
      await widget.apiClient.markNotificationRead(id);
      if (mounted) setState(() => request = widget.apiClient.notifications());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The notification could not be updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PagePadding(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Booking, message, payment, and system updates.'),
        const SizedBox(height: 18),
        FutureBuilder<List<NotificationItem>>(
          future: request,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingState();
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: 'We could not load notifications.',
                onRetry: () =>
                    setState(() => request = widget.apiClient.notifications()),
              );
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return const SectionCard(child: Text('You are all caught up.'));
            }
            return Column(
              children: notifications
                  .map(
                    (notification) => SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                notification.read
                                    ? Icons.notifications_none_rounded
                                    : Icons.notifications_active_rounded,
                                color: notification.read
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(notification.body),
                                    const SizedBox(height: 5),
                                    Text(
                                      notification.createdAt,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (!notification.read)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => markRead(notification.id),
                                child: const Text('Mark as read'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

