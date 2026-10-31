import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final Widget child;

  int get _index {
    if (currentLocation.startsWith('/discover')) return 1;
    if (currentLocation.startsWith('/bookings') ||
        currentLocation.startsWith('/booking')) {
      return 2;
    }
    if (currentLocation.startsWith('/messages')) return 3;
    if (currentLocation.startsWith('/notifications')) return 4;
    if (currentLocation.startsWith('/profile') ||
        currentLocation.startsWith('/settings')) {
      return 5;
    }
    return 0;
  }

  void _go(BuildContext context, int index) {
    const paths = [
      '/home',
      '/discover',
      '/bookings',
      '/messages',
      '/notifications',
      '/profile',
    ];
    context.go(paths[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'marketplace.',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => _go(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

